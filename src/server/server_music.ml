open Remo_common
open Astring
open Sexplib
open Sexplib.Conv
open Music
module List = List_ext
open Util
open React_ext
module Lwt = Lwt_ext
module R = Rresult_ext
module Log = (val (Logs.src_log (Logs.Src.create "server_music")))

module DbusMap = struct
	type t = (string * OBus_value.V.single) list
	let keys : t -> string list = fun map ->
		map |> List.map (fun (key,_) -> key)
end

type volume = {
	pa_core: OBus_proxy.t;
	pa_device: OBus_proxy.t;
}

type peers = {
	volume: volume option;
	player: OBus_proxy.t option;
}

type state = {
	peers: peers sexp_opaque;
	music_state: Music.state;
} [@@deriving sexp_of]


let mpris_path = "org.mpris.MediaPlayer2"
let mpris_prefix = mpris_path ^ "."

type 'a delayed_stream_mode =
	| Head of 'a Lwt_stream.t Lwt.t
	| Tail of 'a Lwt_stream.t

let delayed_stream (stream: 'a Lwt_stream.t Lwt.t) : 'a Lwt_stream.t =
	let state = ref (Head stream) in
	let rec next = fun () ->
		match !state with
			| Tail stream -> Lwt_stream.get stream
			| Head stream ->
				Lwt.bind stream (fun stream ->
					state := Tail stream;
					next ()
				)
	in
	Lwt_stream.from next

let player_events player =
	let open Event in
	let rec get_string key : OBus_value.V.single -> (string, Sexp.t) result = let open OBus_value.V in function
		| Basic (String v) -> Ok v
		| Array (_typ, values) -> get_string_of_list key values
		| Structure (values) -> get_string_of_list key values
		| other -> Error (Sexp.Atom ("Unexpected dbus value for key " ^ key ^ ": " ^ (string_of_single other)))
	and get_string_of_list key values =
		values |> List.map (get_string key)
			|> R.collect |> R.map (String.concat ~sep:", ")
	in
	let current_artist x = Current_artist (Some x) in
	let current_title x = Current_title (Some x) in
	let play_status_change_event = function
		| "Playing" -> Ok (Music_event (Current_playing true))
		| "Paused" | "Stopped" -> Ok (Music_event (Current_playing false))
		| other -> Error (Sexp.Atom ("Unknown play status: " ^ other))
	in
	let metadata_change_events map = (
		Log.debug(fun m->m "Saw changes to metadata: %s"
			(map |> List.map (fun (k,v) ->
				k ^ ": " ^ (OBus_value.V.string_of_single v)) |> String.concat ~sep:","));
		let music_events = map |> List.filter_map (fun (key, value) ->
			match key with
				| "xesam:artist" -> Some (get_string key value |> R.map current_artist)
				| "xesam:title" -> Some (get_string key value |> R.map current_title)
				| _ -> None
		) in
		music_events |> List.map (fun evt -> evt |> R.map (fun evt -> Music_event evt))
	) in

	let open Rhythmbox_client in
	let open Org_mpris_MediaPlayer2_Player in
	let metadata_events = OBus_property.monitor (metadata player)
		|> Lwt.map (fun signal ->
			signal |> S.changes_with_initial
				|> E.map metadata_change_events
				|> E.flatten
		)
	in
	let play_status_events = OBus_property.monitor (playback_status player)
		|> Lwt.map (fun signal ->
			signal |> S.changes_with_initial
				|> E.map play_status_change_event
		)
	in

	let stream_of_events_lwt events =
		events |> Lwt.map Lwt_react.E.to_stream |> delayed_stream in

	Lwt_stream.choose (
		[ metadata_events; play_status_events ] |> List.map stream_of_events_lwt)

let volume_events { pa_core; pa_device } =
	let open Event in
	let volume_change_event steps v = (
		let to_ratio v = (float_of_int v) /. (float_of_int steps) in
		let average ints =
			let sum = List.fold_left (+) 0 ints in
			let count = List.length ints in
			sum / count
		in
		Log.debug(fun m->m "Saw changes to volume: %s"
			(List.map string_of_int v |> String.concat ~sep:","));
		v
			|> R.wrap (to_ratio % average)
			|> R.map (fun v -> Music_event (Current_volume (Some v)))
	) in

	let open Pulseaudio_client.Org_PulseAudio_Core1_Device in
	let volume_steps : int Lwt.t = volume_steps pa_device |> OBus_property.get in
	let initial_volume : int list Lwt.t = volume pa_device |> OBus_property.get in
	let volume_changes : int list React.event Lwt.t = volume_updated pa_device in
	let enable_subscription = Pulseaudio_client.Org_PulseAudio_Core1.listen_for_signal
		pa_core ~signal:"org.PulseAudio.Core1.Device.VolumeUpdated" ~objects:[pa_device] in

	Lwt.zip (Lwt.zip volume_steps initial_volume) (Lwt.zip enable_subscription volume_changes) |> Lwt.map (fun ((steps, initial), ((), signal)) ->
		signal |> E.prefix initial
			|> E.map (volume_change_event steps)
			|> Lwt_react.E.to_stream
	) |> delayed_stream

let first_mpris_service bus : OBus_proxy.t option Lwt.t =
	let%lwt all = OBus_bus.list_names bus in
	let dump_names all =
		let formatted = List.map (fun x -> " - " ^ x) (List.sort compare all) in
		String.concat ~sep:"\n" formatted
	in
	(* Log.debug (fun m -> m"All dbus names:\n%s" (dump_names all)); *)
	let mpris_names = all |> List.filter (fun name ->
		String.is_prefix ~affix:mpris_prefix name
	) in
	Log.debug (fun m -> m"All MPRIS names:\n%s" (dump_names mpris_names));
	List.nth_opt mpris_names 0 |> Option.map (fun name ->
		Log.info(fun m->m"Connecting to MPRIS bus %s" name);
		OBus_bus.get_peer bus name |> Lwt.map (fun peer ->
			Some (OBus_proxy.make ~peer ~path:(OBus_path.of_string "/org/mpris/MediaPlayer2"))
		)
	) |> Option.default Lwt.return_none

let make_player peer =
	OBus_proxy.make ~peer ~path:(OBus_path.of_string "/org/mpris/MediaPlayer2")

let disconnected = {
	volume = None;
	player = None;
}

let init () = {
	peers = disconnected;
	music_state = Music.init ();
}

let invoke state =
	let open Rhythmbox_client.Org_mpris_MediaPlayer2_Player in
	let music fn =
		state.peers.player
			|> Option.map (fun player -> R.wrap_lwt fn player)
			|> Option.default_fn (fun () -> Lwt.return (Ok ()))
	in
	let volume direction =
		state.peers.volume
			|> Option.map (fun volume : (unit, Sexplib.Sexp.t) result Lwt.t ->
				R.wrap_lwt (fun { pa_device; _ } : unit Lwt.t ->
					let open Pulseaudio_client.Org_PulseAudio_Core1_Device in
					let%lwt (max, vol) = Lwt.zip
						(volume_steps pa_device |> OBus_property.get)
						(volume pa_device |> OBus_property.get)
					in
					let increment = max / 20 in
					let updated = vol |> List.map (fun vol ->
						if (direction > 0) && (vol >= max - increment) then
							max
						else if (direction < 0) && (vol <= increment) then
							0
						else
							vol + (direction * increment)
					) in
					Log.info (fun m->
						let max = float_of_int max in
						let volume_float d =
							let first = List.nth_opt d 0 |> Option.default 0 in
							(float_of_int first) /. max in
						m"volume %0.2f -> %0.2f"
							(volume_float vol)
							(volume_float updated)
					);
					OBus_property.set (volume pa_device) updated
				) volume
			)
			|> Option.default_fn (fun () -> Lwt.return (Ok ()))
	in
	function
	| Previous -> music previous
	| PlayPause -> music play_pause
	| Next -> music next
	| Louder -> volume 1
	| Quieter -> volume (-1)

let discover_volume_device session_bus : volume Lwt.t =
	let%lwt (address:string) = (
		let%lwt peer = OBus_bus.get_peer session_bus "org.PulseAudio1" in
		let proxy = OBus_proxy.make ~peer ~path:(OBus_path.of_string "/org/pulseaudio/server_lookup1") in
		Pulseaudio_client.Org_PulseAudio_ServerLookup1.address proxy |> OBus_property.get
	)
	in

	(* now connect to the server directly *)
	let%lwt conn = OBus_connection.of_addresses ~shared:true (OBus_address.of_string address) in
	let pa_peer = OBus_peer.make ~connection:conn ~name:("org.PulseAudio.Core1") in
	let pa_core = OBus_proxy.make ~peer:pa_peer ~path:(OBus_path.of_string "/org/pulseaudio/core1") in
	let%lwt pa_device = Pulseaudio_client.Org_PulseAudio_Core1.fallback_sink pa_core |> OBus_property.get in
	Lwt.return { pa_core; pa_device }

let connect () =
	let%lwt bus = OBus_bus.session () in
	let%lwt (player, volume) = Lwt.zip
		(first_mpris_service bus)
		(discover_volume_device bus)
	in
	Lwt.return {
		volume = Some volume;
		player;
	}

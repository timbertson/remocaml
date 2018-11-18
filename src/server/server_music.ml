open Remo_common
open Astring
open Sexplib.Conv
module Lwt = Lwt_ext
module R = Rresult_ext
module Log = (val (Logs.src_log (Logs.Src.create "server_music")))

type dbus_map = (string * OBus_value.V.single) list

type player = {
	player_proxy: OBus_proxy.t;
	metadata_signal: dbus_map React.signal Lwt.t;
}

type peers = {
	volume: OBus_proxy.t option;
	player: player option;
}

type state = {
	peers: peers sexp_opaque;
	music_state: Music.state;
} [@@deriving sexp_of]


let mpris_path = "org.mpris.MediaPlayer2"
let mpris_prefix = mpris_path ^ "."

let first_mpris_service bus : OBus_peer.t option Lwt.t =
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
		OBus_bus.get_peer bus name |> Lwt.map (fun x -> Some x)
	) |> Option.default Lwt.return_none

let make_player peer =
	let open Rhythmbox_client in
	let proxy = OBus_proxy.make ~peer ~path:(OBus_path.of_string "/org/mpris/MediaPlayer2") in
	{
		player_proxy = proxy;
		metadata_signal = OBus_property.monitor (Org_mpris_MediaPlayer2_Player.metadata proxy);
	}

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
	let open Music in
	let music fn =
		state.peers.player
			|> Option.map (fun player -> R.wrap_lwt fn player.player_proxy)
			|> Option.default_fn (fun () -> Lwt.return (Ok ()))
	in
	let volume direction =
		state.peers.volume
			|> Option.map (fun player : (unit, Sexplib.Sexp.t) result Lwt.t ->
				R.wrap_lwt (fun player : unit Lwt.t ->
					let open Pulseaudio_client.Org_PulseAudio_Core1_Device in
					let%lwt (max, vol) = Lwt.zip
						(volume_steps player |> OBus_property.get)
						(volume player |> OBus_property.get)
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
					OBus_property.set (volume player) updated
				) player
			)
			|> Option.default_fn (fun () -> Lwt.return (Ok ()))
	in
	function
	| Previous -> music previous
	| Play -> music play
	| Pause -> music pause
	| Next -> music next
	| Louder -> volume 1
	| Quieter -> volume (-1)

let discover_volume_device session_bus : OBus_proxy.t Lwt.t =
	let%lwt (address:string) = (
		let%lwt peer = OBus_bus.get_peer session_bus "org.PulseAudio1" in
		let proxy = OBus_proxy.make ~peer ~path:(OBus_path.of_string "/org/pulseaudio/server_lookup1") in
		Pulseaudio_client.Org_PulseAudio_ServerLookup1.address proxy |> OBus_property.get
	)
	in

	(* now connect to the server directly *)
	let%lwt conn = OBus_connection.of_addresses ~shared:true (OBus_address.of_string address) in
	let pa_peer = OBus_peer.make ~connection:conn ~name:("org.PulseAudio.Core1") in
	let pa_proxy = OBus_proxy.make ~peer:pa_peer ~path:(OBus_path.of_string "/org/pulseaudio/core1") in
	Pulseaudio_client.Org_PulseAudio_Core1.fallback_sink pa_proxy |> OBus_property.get

let connect () =
	let%lwt bus = OBus_bus.session () in
	let%lwt (player_peer, volume) = Lwt.zip
		(first_mpris_service bus)
		(discover_volume_device bus)
	in
	let player = player_peer |> Option.map make_player in
	Lwt.return {
		volume = Some volume;
		player;
	}

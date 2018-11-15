open Remo_common
open Astring
open Sexplib.Conv
module R = Rresult_ext
module Log = (val (Logs.src_log (Logs.Src.create "server_music")))

type player = {
	props: OBus_proxy.t;
	music: OBus_proxy.t;
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
	Log.debug (fun m -> m"All dbus names:\n%s" (dump_names all));
	let mpris_names = all |> List.filter (fun name ->
		String.is_prefix ~affix:mpris_prefix name
	) in
	Log.debug (fun m -> m"All MPRIS names:\n%s" (dump_names mpris_names));
	List.nth_opt mpris_names 0 |> Option.map (fun name ->
		Log.info(fun m->m"Connecting to MPRIS bus %s" name);
		OBus_bus.get_peer bus name |> Lwt.map (fun x -> Some x)
	) |> Option.default Lwt.return_none

let music_iface peer =
	OBus_proxy.make ~peer ~path:(OBus_path.of_string "/org/mpris/MediaPlayer2")

let props_iface peer =
	(* TODO: unnecessary *)
	OBus_proxy.make ~peer ~path:(OBus_path.of_string "/org/mpris/MediaPlayer2")
	(* OBus_proxy.make ~peer ~path:(OBus_path.of_string "org.freedesktop.DBus.Properties") *)

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
			|> Option.map (fun player ->
					R.wrap_lwt fn player.music)
			|> Option.default_fn (fun () -> Lwt.return (Ok ()))
	in
	function
	| Previous -> music previous
	| Play -> music play
	| Pause -> music pause
	| Next -> music next

let connect () =
	let%lwt bus = OBus_bus.session () in
	let%lwt player_peer = first_mpris_service bus in
	let player = player_peer |> Option.map (fun player_peer ->
		let music_proxy = music_iface player_peer in
		let props_proxy = props_iface player_peer in
		{
			music = music_proxy;
			props = props_proxy;
		}
	) in
	Lwt.return {
		volume = None;
		player;
	}

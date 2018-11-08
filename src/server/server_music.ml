open Remo_common
open Astring
open Sexplib.Std
open Sexplib.Std

type player = {
	props: OBus_proxy.t;
	music: OBus_proxy.t;
}

type volume = OBus_proxy.t

type peers = {
	volume: volume option;
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
	let mpris_names = all |> List.filter (fun name ->
		String.is_prefix ~affix:"" name
	) in
	List.nth_opt mpris_names 0 |> Option.map (fun name ->
		OBus_bus.get_peer bus name |> Lwt.map (fun x -> Some x)
	) |> Option.default Lwt.return_none

let music_iface peer =
	OBus_bus.get_proxy peer "org.mpris.MediaPlayer2.Player"

let props_iface peer =
	OBus_bus.get_proxy peer "org.freedesktop.DBus.Properties"

let init () = {
	peers = {
		volume = None;
		player = None;
	};
	music_state = Music.init ();
}

let state = ref (init ())

(* let play = Rhythmbox_client.Org_mpris_MediaPlayer2_Player.play *)
(* let previous = Rhythmbox_client.Org_mpris_MediaPlayer2_Player.previous *)
(* let next = Rhythmbox_client.Org_mpris_MediaPlayer2_Player.next *)

let perform state =
	let open Rhythmbox_client.Org_mpris_MediaPlayer2_Player in
	let open Music in
	let music fn =
		!state.player
			|> Option.map (fun player -> fn player.music)
			|> Option.default Lwt.return_unit
	in
	function
	| Previous -> music previous
	| Play -> music play
	| Pause -> music pause
	| Next -> music next

let connect () =
	let%lwt bus = OBus_bus.session () in
	let%lwt player_peer = first_mpris_service bus in
	let%lwt music_proxy = OBus_bus.get_proxy bus "org.mpris.MediaPlayer2.rhythmbox" (OBus_path.of_string "org.mpris.MediaPlayer2") in
	let%lwt props_proxy = OBus_bus.get_proxy bus "org.mpris.MediaPlayer2.rhythmbox" (OBus_path.of_string "org.freedesktop.DBus.Properties") in
	Lwt.return {
		volume = None;
		player = Some {
			music = music_proxy;
			props = props_proxy;
		};
	}


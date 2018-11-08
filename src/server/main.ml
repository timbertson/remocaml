(* open Lwt *)
open Cohttp
open Cohttp_lwt
open Cohttp_lwt_unix
open Sexplib
open Remo_common
open Util
module R = Rresult_ext
module Log = (val (Logs.src_log (Logs.Src.create "main")))

module StringSet = Set.Make(String)
module StringMap = Map.Make(String)

let static_files = StringSet.of_list [
	"index.html";
	"main.bc.js";
	"style.css";
	"bootstrap.min.css";
]
let static_root = "_build/default/src/www"

type 'a http_result = ('a, (Code.status_code * Sexp.t)) result

let wrap_exn ?(code:Code.status_code option) f a = (R.wrap f) a |> R.reword_error (fun err ->
	(code |> Option.default `Internal_server_error, err)
)

let handler ~state ~static_cache = fun conn req body ->
	let uri = req |> Request.uri in
	let path = Uri.path uri in
	let meth = req |> Request.meth in
	let unknown () =
		let meth = meth |> Code.string_of_method in
		let headers = req |> Request.headers |> Header.to_string in
		let uri = Uri.to_string uri in
		let%lwt body = body |> Body.to_string |> Lwt.map (fun body ->
			(Printf.sprintf "Uri: %s\nPath: %s\nMethod: %s\nHeaders\nHeaders: %s\nBody: %s"
				uri path meth headers body
			)) in
		Server.respond_string ~status:`Not_found ~body ()
	in

	let serve_static path =
		(* TODO: etag? *)
		match StringMap.find_opt path static_cache with
			| Some cached -> Server.respond_string
					~status:`OK
					~body:cached ()
			| None ->
				Log.debug (fun m->m"responding with file %s" path);
				Server.respond_file ~fname:(Filename.concat static_root path) ()
	in

	let path_without_slash =  String.sub path 1 ((String.length path) - 1) in
	let response = match (meth, path_without_slash) with
		| (`GET, "") -> serve_static "index.html"
		| (`GET, path) when StringSet.mem path static_files -> serve_static path

		| (`GET, "events") ->
			(* let (event_stream, push) = Lwt_stream.create () in *)
			(* let rec loop = fun () -> *)
			(* 	Log.app (fun m->m"sleepgin"); *)
			(* 	let open Event in *)
			(* 	let%lwt () = Lwt_unix.sleep 1.0 in *)
			(* 	Log.app (fun m->m"Pushing event..."); *)
			(* 	push (Some (Ok (Music_event (Current_track (Some "mountain goats woo!"))))); *)
			(* 	let%lwt () = Lwt_unix.sleep 1.0 in *)
			(* 	Log.app (fun m->m"Pushing event..."); *)
			(* 	push (Some (Ok (Music_event (Current_track None)))); *)
			(* 	if (List.mem conn !stream_conns) then *)
			(* 		loop () *)
			(* 	else *)
			(* 		Lwt.return_unit *)
			(* in *)
			let initial_state = Event.(Reset_state (!state |> Server_state.client_state)) in
			let events = Connections.add_event_stream conn initial_state in
			let response = events |> Lwt_stream.map (fun event ->
				event |> R.map Event.sexp_of_event
				|> R.sexp_of_result
				|> fun s ->
						"data: " ^ (Sexp.to_string s) ^ "\n\n"
			) in
			let headers = Header.add_list (Header.init ()) [
				"Cache-Control", "no-cache";
				"Content-Type", "text/event-stream";
			] in
			Server.respond ~headers ~flush:true ~status:`OK ~body:(Body.of_stream response) ()
		| (`POST, "/send") -> (
			let%lwt body = body |> Cohttp_lwt.Body.to_string in
			let event = body |> wrap_exn ~code:`Bad_request (Event.event_of_sexp % Sexp.of_string) in
			let response = event |> R.map (fun event -> (Event.sexp_of_event event)) in
			let (status, body) = match response with
				| Ok body -> (`OK, Ok body)
				| Error (status, body) -> (status, Error body)
			in
			Server.respond_string ~status ~body:(Sexp.to_string (R.sexp_of_result body)) ()
		)

		| _ -> unknown ()
	in
	response |> Lwt.map (fun response ->
		let (http_response, _body) = response in
		Log.debug (fun m->m"%s %s -> %s"
			(Code.string_of_method meth) path
			(Code.string_of_status (Response.status http_response))
		);
		response
	)

let play () =
	let%lwt conn = Server_music.connect () in
	let%lwt music_state = Server_music.state conn in

	(* let%lwt bus = OBus_bus.session () in *)
	(* let%lwt proxy = OBus_bus.get_proxy bus "org.mpris.MediaPlayer2.rhythmbox" (OBus_path.of_string "org.mpris.MediaPlayer2") in *)
	(* let%lwt () = Rhythmbox_client.Org_mpris_MediaPlayer2_Player.play_pause proxy in *)
	Lwt.return_unit

let read_entire_file path =
	(* TODO: surely there's a builtin? *)
	let open Unix in
	let f = openfile path [O_RDONLY; O_CLOEXEC] 0o600 in
	let buf = Bytes.empty in
	let rec read_chunk = fun offset ->
		Log.debug(fun m->m"reading upto 1024 bytes into offset %d in %s (fd %d)"
			offset path (Obj.magic f));
		let bytes_read = read f buf offset 1024 in
		Log.debug(fun m->m"read %d bytes into offset %d in %s"
			bytes_read offset path);
		if bytes_read > 0 then read_chunk (offset + bytes_read)
	in
	let () = try
		read_chunk 0;
	with e -> (
		Log.err(fun m->m"Failed to read file %s" path);
		raise e
	) in
	Bytes.to_string buf

let () =
	Logs.set_level (
		try (Unix.getenv "LOG_LEVEL" |> Logs.level_of_string |> R.get_ok) with _ -> Some (Logs.Info)
	);
	Logs.set_reporter (Logs_fmt.reporter ());
	let config = Server_config.load ~state_dir:("/tmp/remocaml") "config/remocaml.sexp" |> R.force in
	let server_state = Server_state.load config |> R.force in
	Log.debug(fun m->m"server state: %s" (Server_state.sexp_of_state server_state |> Sexp.to_string));
	let static_cache = StringMap.empty in
	(* Invalid_argument !?!?!? *)
	(* let static_cache = StringSet.fold (fun path map -> *)
	(* 	StringMap.add path (read_entire_file (Filename.concat static_root path)) map *)
	(* ) static_files static_cache in *)

	let callback = handler ~static_cache ~state:(ref server_state) in
	let server = Server.create
		~mode:(`TCP (`Port 8000))
		~on_exn:(fun _ -> Log.warn (fun m->m"Error in server; ignoring"))
		(Server.make ~callback ()) in
	ignore (play ());
	ignore (Lwt_main.run server)

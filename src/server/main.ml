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

let reconnect state =
	let current_state: Server_state.state = !state in
	let%lwt music_peers = R.wrap_lwt Server_music.connect () in
	let (peers, error_events) = (match music_peers with
		| Ok peers -> (peers, [])
		| Error err -> (Server_music.disconnected, [Error err])
	) in
	state := { current_state with
		server_music_state = { current_state.Server_state.server_music_state with
			peers;
		}
	};
	(* TODO: trigger a refresh of music state *)
	Lwt.return error_events

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
			(* reconnect music peers on every connection. It's not that expensive,
			 * and the mpris peer may have changed *)
			let%lwt reconnect_events = reconnect state in
			let client_state = !state |> Server_state.client_state in
			let initialize_state = [
				Ok (Event.(Reset_state client_state))
			] in
			let events = Connections.add_event_stream conn (reconnect_events @ initialize_state) in
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

		| (`POST, "invoke") -> (
			let%lwt command = body |> Cohttp_lwt.Body.to_string in
			let command = command |> R.wrap (Event.command_of_sexp % Sexp.of_string) in
			let%lwt response = command |> R.bind_lwt (fun command ->
				Server_state.invoke !state command
			) in
			let (status, body) = match response with
				| Ok () -> (`OK, "")
				| Error err -> (`Internal_server_error, Sexp.to_string (R.sexp_of_error err))
			in
			let headers = Header.add_list (Header.init ()) [
				"Content-Type", "text/plain";
			] in
			Server.respond_string ~headers ~status ~body ()
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

let read_entire_file path =
	(* TODO: surely there's a builtin? *)
	let open Unix in
	let f = openfile path [O_RDONLY; O_CLOEXEC] 0o600 in
	let stats = fstat f in
	let buf = Bytes.make stats.st_size '\x00' in
	let rec read_chunk = fun offset ->
		let bytes_left = stats.st_size - offset in
		if (bytes_left > 0) then (
			let bytes_read = read f buf offset bytes_left in
			assert (bytes_read > 0);
			read_chunk (offset + bytes_read)
		)
	in
	try
		read_chunk 0;
		Bytes.to_string buf
	with e -> (
		Log.err(fun m->m"Failed to read file %s" path);
		raise e
	)

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
	let static_cache = StringSet.fold (fun path map ->
		StringMap.add path (read_entire_file (Filename.concat static_root path)) map
	) static_files static_cache in

	let state = ref server_state in
	let callback = handler ~static_cache ~state in
	let server = Server.create
		~mode:(`TCP (`Port 8000))
		~on_exn:(fun _ -> Log.warn (fun m->m"Error in server; ignoring"))
		(Server.make ~callback ()) in
	Lwt.async (fun () ->
		let%lwt (_:_ list) = reconnect state in
		Lwt.return_unit);
	let () = (Lwt_main.run server) in
	()

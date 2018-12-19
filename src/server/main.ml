open Cohttp
open Cohttp_lwt
open Cohttp_lwt_unix
open Sexplib
open Remo_common
open Astring
module List = List_ext
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

type 'a http_result = ('a, (Code.status_code * Sexp.t)) result

let reconnect config state =
	let current_state: Server_state.state = !state in
	let%lwt music_peers = R.wrap_lwt Server_music.connect config.Server_config.music in
	let (peers, error_events) = (match music_peers with
		| Ok peers -> (peers, [])
		| Error err -> (Server_music.disconnected, [Error err])
	) in
	state := { current_state with
		server_music_state = { current_state.Server_state.server_music_state with
			peers;
		}
	};
	Lwt.return error_events

let handler ~config ~state ~static_cache ~static_root = fun conn req body ->
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

	let path_without_slash =  String.trim ~drop:(fun x -> x = '/') path in
	let response = match (meth, path_without_slash) with
		| (`GET, "") -> serve_static "index.html"
		| (`GET, path) when StringSet.mem path static_files -> serve_static path

		| (`GET, path) when String.is_prefix ~affix:"webfonts/" path -> serve_static path

		| (`GET, "events") ->
			(* reconnect music peers on every connection. It's not that expensive,
			 * and the mpris peer may have changed *)
			let%lwt reconnect_events = reconnect config state in
			let client_state = !state |> Server_state.client_state in
			let initialize_state = [
				Ok (Event.(Reset_state client_state))
			] in
			let events = Connections.add_event_stream conn (reconnect_events @ initialize_state) in

			let dbus_events: Event.event R.std_result Lwt_stream.t =
				let open Server_music in
				let peers = (!state).Server_state.server_music_state.peers in
				Lwt_stream.choose (List.filter_map identity [
					peers.player |> Option.map (Server_music.player_events);
					peers.volume |> Option.map (Server_music.volume_events);
				])
			in

			let job_events: Event.event R.std_result Lwt_stream.t =
				let open Server_job in
				Lwt_react.E.to_stream ((!state).Server_state.server_jobs.events)
			in

			let response = Lwt_stream.choose [events; dbus_events; job_events] |> Lwt_stream.map (fun event ->
				event |> R.sexp_of_result Event.sexp_of_event |> fun s ->
					Log.debug (fun m->m "emitting: %s" (Sexp.to_string s));
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
				Server_state.invoke state command
			) in
			Log.debug (fun m->
				let result_s = R.sexp_of_result (Conv.sexp_of_option Event.sexp_of_event) response in
				m"/invoke response: %s" (Sexp.to_string result_s));
			let (status, body) = match response with
				| Ok event ->
						event |> Option.may (Connections.broadcast);
						(`OK, "")
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

let init_logs () =
	Logs.set_level (
		try (Unix.getenv "LOG_LEVEL" |> Logs.level_of_string |> R.get_ok) with _ -> Some (Logs.Info)
	);
	(* Quiet, cohttp *)
	Logs.Src.list () |> List.iter (fun src ->
		if String.is_prefix ~affix:"cohttp." (Logs.Src.name src) then
			Logs.Src.set_level src (Some Info)
	);
	let tagging_reporter parent =
		{ Logs.report = (fun src level ~over k user_msgf ->
			if (Logs.Src.equal src Logs.default || level = Logs.App) then
				parent.Logs.report src level ~over k user_msgf
			else
				parent.Logs.report src level ~over k (fun outer_msgf ->
					user_msgf (fun ?header ?tags fmt ->
						outer_msgf ?header ?tags ("[%a %s] @[" ^^ fmt ^^ "@]")
							Logs.pp_level level
							(Logs.Src.name src)
					)
			)
		)}
	in
	let default_reporter =
		let pp_header _ _ = () in
		Logs.format_reporter ~pp_header ()
	in
	Logs.set_reporter (tagging_reporter default_reporter)

let getenv key =
	try Some (Unix.getenv key) with Not_found -> None

let () =
	init_logs ();

	let ephemeral = (try Unix.getenv "REMOCAML_EPHEMERAL" with Not_found -> "false") = "true" in
	Connections.Timeout.set_ephemeral ephemeral;

	let home = getenv "HOME" |> Option.force in
	let config_path = getenv "REMOCAML_CONFIG" |> Option.default (Filename.concat home ".config/remocaml/config.sexp") in
	let runtime_dir = getenv "XDG_RUNTIME_DIR" |> Option.default "/tmp" in
	let state_dir = getenv "REMOCAML_STATE" |> Option.default (Filename.concat runtime_dir "remocaml") in

	let static_root = match getenv "REMOCAML_STATIC" with
		| Some dir -> dir
		| None ->
			let self = Sys.argv.(0) in
			let here = Filename.dirname self in
			(* let basedir = Filename.dirname here in *)
			let basedir_name = Filename.basename here in
			Log.debug (fun m->m"server basedir: %s" basedir_name);
			if (basedir_name = "bin") then (
				(* Running from an installed directory: *)
				Filename.concat (Filename.dirname here) "share/remocaml"
			) else (
				Log.info (fun m->m "Not running from a bin/ directory, assuming development setup");
				"_build/default/src/www"
			)
	in

	let config = Server_config.load ~state_dir config_path |> R.force in
	let server_state = Server_state.load config |> R.force in
	Log.debug(fun m->m"server state: %s" (Server_state.sexp_of_state server_state |> Sexp.to_string));

	let static_cache = StringMap.empty in
	let static_cache = StringSet.fold (fun path map ->
		StringMap.add path (read_entire_file (Filename.concat static_root path)) map
	) static_files static_cache in

	let state = ref server_state in
	let callback = handler ~config ~static_cache ~static_root ~state in
	let mode =
		if getenv "LISTEN_PID" |> Option.fold false (fun listen -> listen = string_of_int (Unix.getpid ()))
		then `Listening_socket (Lwt_unix.of_unix_file_descr ((Obj.magic 3) : Unix.file_descr))
		else `TCP  (`Port (getenv "REMOCAML_PORT" |> Option.map int_of_string |> Option.default 8000))
	in
	Log.info (fun m->m "Listening on %s" (match mode with
		| `TCP (`Port port) -> "port " ^ (string_of_int port)
		| `Listening_socket _ -> "<inherited systemd socket>"
	));

	let server = Server.create ~mode
		~on_exn:(fun _ -> Log.warn (fun m->m"Error in server; ignoring"))
		(Server.make ~callback ()) in
	Lwt.async (fun () ->
		let%lwt (_:_ list) = reconnect config state in
		Lwt.return_unit);
	let () = (Lwt_main.run server) in
	()

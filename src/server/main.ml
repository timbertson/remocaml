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

let static_files = StringSet.of_list [
	"index.html";
	"main.bc.js";
]

type 'a http_result = ('a, (Code.status_code * Sexp.t)) result

let wrap_exn ?(code:Code.status_code option) f a = (R.wrap f) a |> R.reword_error (fun err ->
	(code |> Option.default `Internal_server_error, err)
)

let stream_conns = ref []
let conn_closed closed =
	Log.info(fun m->m"Connection closed");
	let initial_cons = !stream_conns |> List.length in
	stream_conns := !stream_conns |> List.filter (fun conn ->
		conn != closed
	);
	let final_cons = !stream_conns |> List.length in
	Log.info(fun m->m"open conns is %d (was %d)" final_cons initial_cons)

let handler ~state = fun conn req body ->
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

	let serve_file path =
		Log.debug (fun m->m"responding with file %s" path);
		Server.respond_file ~fname:(Filename.concat "_build/default/src/www" path) ()
	in

	let path_without_slash =  String.sub path 1 ((String.length path) - 1) in
	let response = match (meth, path_without_slash) with
		| (`GET, "") -> serve_file "index.html"
		| (`GET, path) when StringSet.mem path static_files -> serve_file path

		| (`GET, "events") ->
			let (event_stream, push) = Lwt_stream.create () in
			let rec loop = fun () ->
				Log.app (fun m->m"sleepgin");
				let open Event in
				let%lwt () = Lwt_unix.sleep 1.0 in
				Log.app (fun m->m"Pushing event...");
				push (Some (Ok (Music_event (Current_track (Some "mountain goats woo!")))));
				let%lwt () = Lwt_unix.sleep 1.0 in
				Log.app (fun m->m"Pushing event...");
				push (Some (Ok (Music_event (Current_track None))));
				if (List.mem conn !stream_conns) then
					loop ()
				else
					Lwt.return_unit
			in
			stream_conns := conn :: !stream_conns;
			Lwt.async (loop);
			push (Some (Ok (Reset_state (!state |> Server_state.client_state))));
			let response = event_stream |> Lwt_stream.map (fun event ->
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


let () =
	Logs.set_level (
		try (Unix.getenv "LOG_LEVEL" |> Logs.level_of_string |> R.get_ok) with _ -> Some (Logs.Info)
	);
	Logs.set_reporter (Logs_fmt.reporter ());
	let config = Server_config.load ~state_dir:("/tmp/remocaml") "config/remocaml.sexp" |> R.force in
	let server_state = Server_state.load config |> R.force in
	Log.debug(fun m->m"server state: %s" (Server_state.sexp_of_state server_state |> Sexp.to_string));
	let server = Server.create
		~mode:(`TCP (`Port 8000))
		~on_exn:(fun _ -> Log.warn (fun m->m"Error in server; ignoring"))
		(Server.make ~callback:(handler ~state:(ref server_state)) ()) in
	ignore (Lwt_main.run server)

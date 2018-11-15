open Remo_common
open Util
module R = Rresult_ext
open Sexplib
open Sexplib.Std
open Fieldslib

module Log = (val (Logs.src_log (Logs.Src.create "ui_state")))

type t = {
	server_state: State.state;
	error: Sexp.t option;
	log: string option;
} [@@deriving sexp, fields]

let init () = {
	server_state = State.init ();
	error = None;
	log = None;
}

let eq : t -> t -> bool = fun a b ->
	let use op = fun field ->
		op (Field.get field a) (Field.get field b)
	in
	Fields.for_all
		~server_state:(use (=))
		~error:(use (=))
		~log:(use (=))

type event_result = (Event.event, Sexp.t) R.result
let sexp_of_event_result = R.sexp_of_result % (R.map Event.sexp_of_event)

type event =
	| Server_event of event_result
	| Invoke of Event.command
	[@@deriving sexp_of]

let update state : event -> t = function
	| Server_event (Error err) -> { state with error = Some err }
	| Server_event (Ok evt) -> { state with server_state = Event.update state.server_state evt }
	| Invoke _ -> state

let update state event = { (update state event) with log = Some (Sexp.to_string (sexp_of_event event)) }

let command instance = fun _state -> function
	| Server_event _ -> None
	| Invoke command -> Some (
			let payload = (Sexp.to_string (Event.sexp_of_command command)) in
			Log.info (fun m->m"invoking command: %s" payload);
			let open Url in
			let path = "invoke" in
			let relative_url url = {
				hu_host = url.hu_host;
				hu_port = url.hu_port;
				hu_path = path_of_path_string path;
				hu_path_string = path;
				hu_arguments = [];
				hu_fragment = "";
			} in
			let dest = match Url.Current.get () with
				| Some (Http u) -> Http (relative_url u)
				| Some (Https u) -> Https (relative_url u)
				| _ -> failwith "invalid URL"
			in
			let%lwt response = Lwt_xmlHttpRequest.perform
				~contents:(`String payload)
				dest
			in
			Lwt.return (match response.code with
				| 200 -> ()
				| _ ->
						let error = try
							Sexp.of_string response.content
						with _ -> Sexp.Atom response.content
						in
						Vdoml.Ui.emit instance (Server_event (Error error))
			)
	)

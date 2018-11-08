open Remo_common
open Util
module R = Rresult_ext
open Sexplib
open Sexplib.Std
open Fieldslib

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


open Vdoml
open Lwt
open Js
open Dom_html
open React
open Remo_common
module R = Rresult_ext
(* module Log = (val Logs.log_module "main") *)
module Log = (val (Logs.src_log (Logs.Src.create "main")))
open Pervasives

open Sexplib
open Sexplib.Std
open Fieldslib

let s = Js.string

module Ui_state = struct
	type t = {
		server_state: State.state;
		error: Sexp.t option;
	} [@@deriving sexp, fields]

	let init () = {
		server_state = State.init ();
		error = None;
	}

	let eq : t -> t -> bool = fun a b ->
		let use op = fun field ->
			op (Field.get field a) (Field.get field b)
		in
		Fields.for_all
			~server_state:(use (=))
			~error:(use (=))
end

let update state : (Event.event, Sexp.t) result -> Ui_state.t = function
	| Error err -> { state with error = Some err }
	| Ok evt -> { state with server_state = Event.update state.server_state evt }

let view instance = function _state ->
	let open Html in
	div [text "Hello!"]

let component tasks =
	Ui.Tasks.sync tasks (fun instance ->
		let event_source = new%js EventSource.eventSource (Js.string "/events") in
		event_source##.onmessage := Dom.handler (fun event ->
			let data = event##.data |> Js.to_string in
			Log.debug(fun m->m"Got event: %s" data);
			let event: (Event.event, Sexp.t) result =
				data
					|> R.wrap Sexp.of_string
					|> R.bindr R.result_of_sexp
					|> R.bindr (R.wrap Event.event_of_sexp)
			in
			Ui.emit instance event;
			Js._true
		)
	);
	let initial_state = Ui_state.init () in
	Ui.root_component ~eq:Ui_state.eq ~update ~view initial_state

let () = (
	Logs.set_reporter (Logs_browser.console_reporter ());
	let app_level, vdoml_level, show_debug = (
		let root_url =
			let open Url in
			match Url.Current.get () with
				| Some (Http _ as u)
				| Some (Https _ as u) -> Url.string_of_url u |> Uri.of_string
				| None | Some (File _) -> failwith "unsupported protocol"
		in

		let open Logs in
		match Uri.fragment root_url with
		| Some "trace" -> (Debug, Some Debug, true)
		| Some "debug" -> (Debug, Some Info, true)
		| Some "info" -> (Info, None, false)
		| _ -> (match Uri.host root_url with
			| Some "localhost" -> (Info, None, false)
			| _ -> (Warning, None, false)
		)
	) in
	Logs.set_level ~all:true (Some app_level);
	vdoml_level |> Option.default app_level |> Ui.set_log_level;
	let tasks = Ui.Tasks.init () in
	Lwt.async (fun () ->
		Ui.main ~tasks ~root:"main" (component tasks) ()
	)
)


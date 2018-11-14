open Vdoml
open Remo_common
module R = Rresult_ext
(* module Log = (val Logs.log_module "main") *)
module Log = (val (Logs.src_log (Logs.Src.create "main")))
open Pervasives

open Sexplib

let component ~show_debug tasks =
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
			Ui.emit instance (Ui_state.Server_event event);
			Js._true
		)
	);
	let initial_state = Ui_state.init () in
	Ui.root_component
		~eq:Ui_state.eq
		~update:Ui_state.update
		~command:Ui_state.command
		~view:(View.view ~show_debug)
		initial_state

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
		Ui.main ~tasks ~root:"main" (component ~show_debug tasks) ()
	)
)


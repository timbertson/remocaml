open Vdoml
open Remo_common
module R = Rresult_ext
module Log = (val (Logs.src_log (Logs.Src.create "main")))
open Pervasives

open Sexplib

let component ~show_debug ~fake tasks =
	let active_event_source = ref None in
	let reconnect instance =
		!active_event_source |> Option.may (fun event_source -> event_source##close);
		let event_source = new%js EventSource.eventSource (Js.string "/events") in
		event_source##.onmessage := Dom.handler (fun event ->
			let data = event##.data |> Js.to_string in
			Log.debug(fun m->m"Got event: %s" data);
			let event: Event.event R.std_result =
				data
					|> R.wrap Sexp.of_string
					|> R.bindr R.result_of_sexp
					|> R.bindr (R.wrap Event.event_of_sexp)
			in
			Ui.emit instance (Ui_state.Server_event event);
			Js._true
		);
		active_event_source := Some (event_source)
	in
	Ui.Tasks.sync tasks reconnect;
	let initial_state = Ui_state.init ~fake () in
	let command instance =
		let command = Ui_state.command instance in
		fun state -> function
			| Ui_state.Reconnect -> reconnect instance; None
			| other -> command state other
	in
	Ui.root_component
		~eq:Ui_state.eq
		~update:Ui_state.update
		~command
		~view:(View.view ~show_debug)
		initial_state

let () = (
	Logs.set_reporter (Logs_browser.console_reporter ());
	let root_url =
		let open Url in
		match Url.Current.get () with
			| Some (Http _ as u)
			| Some (Https _ as u) -> Url.string_of_url u |> Uri.of_string
			| None | Some (File _) -> failwith "unsupported protocol"
	in
	let fragments = Uri.fragment root_url |> Option.default "" |> String.split_on_char ',' in

	let open Logs in
	let app_level = ref Warning in
	let vdoml_level = ref None in
	let show_debug = ref false in
	let fake_data = ref false in

	let () = match Uri.host root_url with
		| Some "localhost" -> app_level := Info
		| _ -> ()
	in

	let () = fragments |> List.iter (function
		| "trace" ->
			app_level := Debug;
			vdoml_level := Some Debug;
			show_debug := true
		| "debug" ->
			app_level := Debug;
			vdoml_level := Some Info;
			show_debug := true
		| "info" ->
			app_level := Debug;
			vdoml_level := Some Info;
			show_debug := true
		| "fake" ->
			fake_data := true
		| _ -> ()
	)
	in

	Logs.set_level ~all:true (Some !app_level);
	!vdoml_level |> Option.default !app_level |> Ui.set_log_level;
	let tasks = Ui.Tasks.init () in
	Lwt.async (fun () ->
		Ui.main ~tasks ~root:"main" (component ~show_debug:!show_debug ~fake:!fake_data tasks) ()
	)
)


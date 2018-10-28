open Vdoml
open Lwt
open Js
open Dom_html
open React
open Remo_common
(* module Log = (val Logs.log_module "main") *)
module Log = (val (Logs.src_log (Logs.Src.create "main")))

open Sexplib

let s = Js.string

let () = (
	Logs.set_reporter (Logs_browser.console_reporter ());
	Log.app (fun m->m "init");
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
	let event_source = new%js EventSource.eventSource (Js.string "/events") in
	event_source##.onmessage := Dom.handler (fun event ->
		let data = event##.data |> Js.to_string in
		Log.info(fun m->m"Got event: %s" data);
		Js._true
	)
)


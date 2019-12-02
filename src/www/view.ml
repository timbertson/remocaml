open Remo_common
open Vdoml
open Html
open Ui_state
open Sexplib
open Util

let card ?header ?(cls=[]) body = div ~a:[a_class_list (cls @ ["card"])] [
	(header |> Option.map (fun header -> div ~a:[a_class "card-header"] header) |> Option.default empty);
	div ~a:[a_class "card-body"] body;
]

let view_music _instance =
	let open Music in
	let open Remo_common.Event in
	fun state ->
		let controls = [
			Previous, "backward";
			PlayPause, if state.playing then "pause" else "play";
			Next, "forward";
		] in

		let track_display {artist; title } = match (artist, title) with
			| None, None -> empty
			| artist, title ->
				div [
					div ~a:[a_class "title"] [ text (title |> Option.default "(unknown)") ];
					div ~a:[a_class "artist"] [ text (artist |> Option.default "(unknown)") ];
				]
		in
		let music_controls = div (controls |> List.map (fun (cmd, icon) ->
			span ~a:[
				a_class ("music-button rounded-circle music-" ^ icon);
				a_onclick (emitter (Invoke (Music_command cmd)))
			] []
		)) in
		let volume_controls = (
			let volume_bar_style =
				let open Printf in
				let volume_width = (state.volume |> Option.default 0.0) *. 100.0 in
				sprintf "width: %0.1f%%;" volume_width
			in
			let btn cmd icon = span ~a:[
				a_class ("volume-button rounded-circle volume-" ^ icon);
				a_onclick (emitter (Invoke (Music_command cmd)));
			] []
			in
			div ~a:[a_class "volume-slider"] [
				btn Quieter "minus";
				div ~a:[a_style volume_bar_style; a_class "volume-color"] [];
				btn Louder "plus";
			]
		) in
		card ~cls:["music-card"] [
			div ~a:[
				a_class "global-button rounded-circle button-reload";
				a_onclick (emitter (Reconnect));
			] [];
			div ~a:[a_class "music-details"] [
				track_display state.track;
			];
			music_controls;
			volume_controls;
		]

let view_job _instance =
	let open Remo_common.Event in
	let open Job in

	let append_newline s = s ^ "\n" in
	let button id icon action = span ~a:[
		a_class ("button rounded-circle job-"^icon);
		a_onclick (emitter (Invoke (Job_command (id, action))));
	] [] in
	fun { job; state; output } -> (
		let button = button job.id in
		let start_or_stop = match state with
			| None | Some (Exited _) -> button "run" Start
			| Some Running -> button "stop" Stop
		in
		let output_shown, output_display = output |> Option.fold
			(false, [ empty ])
			(fun output -> (true, match output with
				| [] -> [ text "(no output)" ]
				| output -> output |> List.map (text % append_newline))
			)
		in
		let header = [
			div ~a:[a_class "controls"] [
				button "list" (Show_output (not output_shown));
				start_or_stop;
			];
			span ~a:[a_class "text"] [text job.name];
		] in
		let empty_cls = if output_shown then [] else ["empty"] in
		card ~header ~cls:(["text-white"; "bg-secondary"; "job-card"] @ empty_cls) [
			pre ~a:[a_class "output"] output_display;
		]
	)

let job_component = Ui.component ~view:view_job ()

let view_jobs =
	let open Job in
	fun instance ->
		let children = Ui.collection ~id:(fun {job; _ } -> `String job.id) job_component instance in
		fun { jobs } -> div (children jobs)

let view ~show_debug instance =
	let view_music = view_music instance in
	let view_jobs = view_jobs instance in
	function state ->
		let open State in
		let { server_state; state_override; error; log } = state in
		let server_state = state_override |> Option.default server_state in
		let { music_state; job_state } = server_state in
		div ~a:[a_class "container"] [
			div [
				(error |> Option.map (fun err ->
					div ~a:[a_class "alert alert-danger"] [
						h1 [ text "Error:"];
						text (Sexp.to_string err)
					]
				) |> Option.default empty);
				(view_music music_state);
				(view_jobs job_state);
				(if show_debug then (
					(log |> Option.map (fun log ->
						div [
							div ~a:[a_class "log"] [
								h3 [text "Log:"];
								div [text log];
								h3 [text "State:"];
								div [text (Sexp.to_string (sexp_of_state server_state))];
							];
						]
					)) |> Option.default empty
				) else empty);
			]
		]


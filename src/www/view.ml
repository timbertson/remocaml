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
	fun state pending_ratings ->
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
				a_class ("button music-button music-" ^ icon);
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
				a_class ("button volume-button volume-" ^ icon);
				a_onclick (emitter (Invoke (Music_command cmd)));
			] []
			in
			div ~a:[a_class "volume-slider"] [
				btn Quieter "minus";
				div ~a:[a_style volume_bar_style; a_class "volume-color"] [];
				btn Louder "plus";
			]
		) in

		let rec rating_stars url rating n = if n > Irank.stars then [] else
				let open Irank in
				let enabled = rating.rating_value >= n in
				let new_rating = { rating with rating_value = n } in
				let action = emitter (Pending_rating (Some (url, new_rating))) in
				let star = span ~a:[
					a_class_list ["star-button"; (if enabled then "full" else "empty")];
					a_onclick action;
				] [] in
				star :: rating_stars url rating (n+1)
		in
		let irank_controls = let open Irank in match (state.track.url, state.track.ratings) with
			| (Some url, Some ratings) -> (
				let pending_ratings = (match pending_ratings with
					| Some (pending_url, pending_ratings) when url = pending_url -> pending_ratings
					| _ -> []
				) |> List.filter (fun pending ->
					let existing_value = Irank.find pending.rating_name ratings |> Option.map (fun r -> r.rating_value) in
					existing_value <> Some pending.rating_value
				) in
				let rating_grid = div ~a:[a_class "grid"] (ratings |> List.map (fun rating ->
					let overridden = List.find_opt (fun override -> override.rating_name = rating.rating_name) pending_ratings in
					let (extra_cls, rating) = match overridden with
						| Some override -> (["pending"], override)
						| None -> ([], rating)
					in
					[
						span ~a:[a_class_list ("rating-name" :: extra_cls)] [text rating.Irank.rating_name];
						span ~a:[a_class_list ("rating-value" :: extra_cls)] (rating_stars url rating 0);
					]
				) |> List.concat) in
				let children = match pending_ratings with
					| [] -> [ rating_grid ]
					| overrides ->
						let save = emitter (Invoke (Music_command (Rate (url, overrides)))) in
						let cancel = emitter (Pending_rating None) in
						let rating_panel = div ~a:[a_class "actions"] [
							span ~a:[a_onclick cancel; a_class "button action-button button-cancel"] [];
							span ~a:[a_onclick save; a_class "button action-button button-save"] [];
						] in
						[rating_grid; rating_panel]
				in div ~a:[a_class "irank-ratings"] children
			)
			| _ -> empty in

		card ~cls:["music-card"] [
			div ~a:[
				a_class "button global-button button-reload";
				a_onclick (emitter (Reconnect));
			] [];
			div ~a:[a_class "music-details"] [
				track_display state.track;
			];
			music_controls;
			volume_controls;
			irank_controls;
		]

let view_job _instance =
	let open Remo_common.Event in
	let open Job in

	let append_newline s = s ^ "\n" in
	let button id icon action = span ~a:[
		a_class ("button job-"^icon);
		a_onclick (emitter (Invoke (Job_command (id, action))));
	] [] in
	fun { job; state; output } -> (
		let button = button job.id in
		let start_or_stop = match state with
			| None | Some (Exited _) -> button "run" Start
			| Some Running -> button "stop" Stop
		in
		let output_shown, output_display = output |> Job.Output.fold
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
		let { server_state; state_override; pending_ratings; error; log } = state in
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
				(view_music music_state pending_ratings);
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


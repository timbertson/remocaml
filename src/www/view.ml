open Remo_common
open Vdoml
open Html
open Ui_state
open Sexplib
open Util

let card ?header ?(cls=[]) body = div ~a:[a_class_list (cls @ ["card"])] [
	(header |> Option.map (fun header -> div ~a:[a_class "card-header"] [ text header ]) |> Option.default empty);
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
		card ~header:job.name ~cls:["text-white"; "bg-secondary"; "job-card"] (
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
			[
				start_or_stop;
				button "list" (Show_output (not output_shown));
				pre ~a:[a_class "output"] output_display;
			]
		)
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


(* template from remote.mho:
				var musicControls = [
					['previous', 'step-backward'],
					['play', 'play'],
					['pause', 'pause'],
					['next', 'step-forward'],
				] .. @map([method, icon] ->
					Button(icon) .. @OnClick(-> api[method]())
				);

				var volumeIncrement = 1 / 20;
				var volumeControls = v -> [
					['minus', - volumeIncrement],
					['plus',  + volumeIncrement],
				] .. @map(function([icon, diff]) {
					console.log("Vol is ", v);
					return Button(icon)
						.. @OnClick(-> v.inc(diff))
						.. volumeButtonStyle
				});

				var musicWidget = h.Div([
						h.H2("Music"),
						h.Div("(loading track details...)")
							.. musicDetailsStyle()
							.. @Mechanism(function(elem) {

								var info = @ObservableVar(null);
								var volume = @ObservableVar(null);

								var ready = {volume: @Condition(), info: @Condition()};

									var [v, i] = [volume, info] .. @map(@mirror);
									//var get = function(o, p,d) {
									//	console.log("Getting #{p} of", o, "which is", o[p]);
									//	return o .. @get(p,d);
									//};
									var metadata = i .. @transform(i -> i .. @get('Metadata', {}));
									var prop = (obs, key) -> obs .. @transform(val -> val[key]);
									var display = [
										h.Div(metadata .. prop('artist')) .. artistStyle,
										h.Div(metadata .. prop('title')) .. trackStyle,
										h.Div([
											volume .. volumeControls,
											h.Div(
												v .. @transform(vol ->
													vol ? h.Div() .. @CSS("{ width: #{vol.scaled * maxVolume}px; }")
												)
											) .. volumeStyle,
										]) .. @CSS('{ width: auto; margin: 0 auto; }'),
										h.Div(`(${i .. prop('PlaybackStatus')})`) .. playStateStyle,
									];
									elem.innerHTML = "";
									elem .. @appendContent(display, -> hold())
								}

							})
						,h.Div(musicControls)
						,clear
					]) .. sectionStyle();

				var taskWidget = h.Div([
						h.Div("(loading...)") .. @Mechanism(function(elem) {
							var tasks = api.tasks();
							var taskWidgets = tasks .. @map(function(task) {

								var hideOutput = @Emitter();
								var toggleOutput = @Emitter();

								// create a local copy of currentPid:
								var currentPid = @ObservableVar(null);
								var isRunning = currentPid .. @transform(p -> p !== null);

								var controls = [
									Button('chevron-right')
										.. @OnClick( function() { console.log("RUNNING"); spawn(task.run()); })
										.. @Class('invisible', isRunning),
									Button('list') .. @OnClick( -> toggleOutput.emit()),
									Button('refresh')
										.. @OnClick( -> task.refresh),
									Button('remove')
										.. @OnClick( -> task.stop(currentPid.get()))
										.. @Class('kill')
										.. @Class('invisible', isRunning .. @transform(x -> !x)),
								];

								var taskStatus = task.wasSuccessful .. @transform(function(success) {
									switch(success) {
										case null: return undefined;
										case true: return h.Span(' ', {'class':'glyphicon glyphicon-ok-sign pull-right'});
										case false: return h.Span(' ', {'class':'glyphicon glyphicon-minus-sign pull-right'});
									}
								});

								return h.Div([
									h.H3([task.name, taskStatus]),
									h.Div([
										h.Div(controls),
										h.Div([
											h.Pre(null, {'class':'output'}),
											clear,
										], {'class':'outputContainer'}) .. @Mechanism(function(elem) {
											if(task.ignoreOutput) return;

											var output = elem.querySelector('.output');
											while(true) {
												elem.classList.remove('viewing');

												elem.classList.add('viewing');
											}
										}),
									]) .. @Class('ctl'),
								], {'class':'col col-md-6'})
									.. @Class('running', isRunning)
									.. taskStyle
									.. @Mechanism(function(elem) {
									})
							});

							elem.innerHTML = "";
							elem .. @appendContent(h.Div(taskWidgets, {'class':'row'}), -> hold());
						}),
						clear
					]);

				var w = h.Div([
						Button('remove')
							.. @OnClick(-> quit.set())
							.. globalButton()
						,
						Button('repeat')
							.. @OnClick(-> api.ping())
							.. globalButton()
						,
						musicWidget,
						taskWidget,
					]);
				document.getElementsByTagName('div')[0] .. @appendContent(w, function() {
					ready();
					quit.wait()
					api.quit();
				});
			}
		}
	} catch(e) {
		console.log('App caught Error:' + e);
		document.body .. @appendContent(
			@Element("div", [
				@Element("button", "retry") .. reconnectButtonStyle,
				@Element("pre", String(e)),
			])
			, function(elem) {
				elem.querySelector('button') .. @wait("click");
				quit.clear();
			}
		);
	}
	if (quit.isSet) {
		document.body .. @appendContent(
			@Element("button", "connect") .. reconnectButtonStyle
			, function(elem) {
				elem .. @wait("click");
				quit.clear();
			}
		);
	}
}

*)

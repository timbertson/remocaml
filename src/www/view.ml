open Remo_common
open Vdoml
open Html
open Ui_state

let view_music instance =
	let open Music in
	let volumeIncrement = 1.0 /. 20.0 in
	let controls = [
		Previous, "step-backward";
		Play, "play";
		Pause, "pause";
		Next, "step-forward";
	] in

	fun state ->
		div (controls |> List.map (fun (command, icon) ->
			span ~a:[a_class ("btn " ^ icon)] [
				text icon(* tmp *)
			]
		))

let view_job instance = fun state ->
	empty

let view_jobs instance = fun state ->
	empty

let view instance =
	let view_music = view_music instance in
	function state ->
		let open State in
		let { server_state; _ } = state in
		let { music_state } = server_state in
		div [
			div [text "Hello!"];
			(view_music music_state);
			(state.log |> Option.map (fun log ->
				div [
					div [text "log:"];
					div [text log]
				]
			)) |> Option.default empty;
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

(* `include React` would be nicer, but leads to duplicate submodule definitions *)
open React
module Log = (val (Logs.src_log (Logs.Src.create "TMP")))

module E = struct
	include E

	let _retain_and_exec ev fn =
		let (_: [`R of unit -> unit]) = E.retain ev fn in
		fn ();
		ev

	let flatten events =
		let rv, send = E.create () in
		_retain_and_exec rv (fun () ->
			let (_:unit event) = events |> E.map (fun events ->
				events |> List.iter send
			) in
			()
		)

	let prefix init desc events =
		let rv, send = E.create () in
		Log.info(fun m->m"Sending initial %s" desc);
		Lwt.async (fun () -> Lwt_main.yield () |> Lwt.map (fun () -> send init));
		(* send init; *)
		_retain_and_exec rv (fun () ->
			let send e = Log.info(fun m->m"Sending subsequent %s" desc); send e in
			let (_:unit event) = events |> E.map send in
			()
		)
end

module S = struct
	include S
	let changes_with_initial desc signal =
		Log.info(fun m->m"Prepending initial event %s" desc);
		let rv, send = E.create () in
		(* XXX this only seems to work if I delay the send *)
		Lwt.async (fun () -> Lwt_main.yield () |> Lwt.map (fun () -> send (signal |> S.value)));
		(* send (signal |> S.value); *)
		E._retain_and_exec rv (fun () ->
			let send e = Log.info(fun m->m"Sending subsequent %s" desc); send e in
			let (_:unit event) = signal |> S.changes |> E.map send in
			()
		)
end

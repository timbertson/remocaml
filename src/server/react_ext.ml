(* `include React` would be nicer, but leads to duplicate submodule definitions *)
open React
module Log = (val (Logs.src_log (Logs.Src.create "TMP")))

module E = struct
	include E

	let _retain_any ~result obj =
		let (_: [`R of unit -> unit]) = E.retain result (fun () -> ignore obj) in
		result

	let flatten events =
		let rv, send = E.create () in
		_retain_any ~result:rv (events |> E.map (fun events ->
			events |> List.iter send
		) : unit event)

	let prefix init events =
		let rv, send = E.create () in
		Lwt.async (fun () -> Lwt_main.yield () |> Lwt.map (fun () -> send init));
		(* send init; *)
		_retain_any ~result:rv (events |> E.map send)
end

module S = struct
	include S
	let changes_with_initial signal =
		E.prefix (S.value signal) (S.changes signal)
end

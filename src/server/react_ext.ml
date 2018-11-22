(* `include React` would be nicer, but leads to duplicate submodule definitions *)
open React

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
end

module S = struct
	include S
	let changes_with_initial signal =
		let rv, send = E.create () in
		send (signal |> S.value);
		E._retain_and_exec rv (fun () ->
			let (_:unit event) = signal |> S.changes |> E.map send in
			()
		)
end

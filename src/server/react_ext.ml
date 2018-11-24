(* `include React` would be nicer, but leads to duplicate submodule definitions *)
open React
module Log = (val (Logs.src_log (Logs.Src.create "TMP")))

module S = struct
	include S
	let _retain_any ~result obj =
		let (_: [`R of unit -> unit]) = S.retain result (fun () -> ignore obj) in
		result

	let to_lwt_stream signal =
		let stream, push, set_ref = Lwt_stream.create_with_reference () in
		set_ref (map (fun x -> push (Some x)) signal);
		stream
end

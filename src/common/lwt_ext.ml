include Lwt
open Lwt.Infix

let zip a b =
	let (t, wake) = wait () in
	let ar = ref None in
	let br = ref None in
	bind (
		bind a (fun x -> ar := Some x)
		<&>
		bind b (fun x -> br := Some x)
	) (fun () ->
		match (ar, ab) with
			| Some a, Some b -> wake (a,b)
			| _ -> failwith "Impossible!"
	)



include Lwt
open Lwt.Infix

let zip a b =
	let ar = ref None in
	let br = ref None in
	((
		map (fun x -> ar := Some x) a
		<&>
		map (fun x -> br := Some x) b
	) |> map (fun () ->
		match (!ar, !br) with
			| Some a, Some b -> (a,b)
			| _ -> failwith "Impossible!"
	))

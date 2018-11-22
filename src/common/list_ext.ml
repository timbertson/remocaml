include List
let filter_map fn input = List.fold_left (fun acc item ->
	match fn item with
		| None -> acc
		| Some x -> x :: acc
) [] input |> rev

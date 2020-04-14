open Remo_common
open Irank
open Astring

module Log = (val (Logs.src_log (Logs.Src.create "server_irank")))

let rating_names = lazy (
	let home = Unix.getenv "HOME" in
	let config_path = Filename.concat home ".config/irank/ratings" in
	let lines file =
		let rec iter_rev acc =
			let line = try Some (input_line file) with End_of_file -> None in
			match line with
				| Some line -> iter_rev (line::acc)
				| None -> acc
		in List.rev (iter_rev [])
	in
	let file = open_in config_path in
	let ratings = lines file |> List.map String.trim |> List.filter ((!=) "") in
	let () = close_in file in
	ratings
)

let blank_ratings () =
	Lazy.force rating_names
	|> List.map (fun name -> { rating_name = name; rating_value = 0 })

let default config = if config.Server_config.irank
	then Some (blank_ratings ())
	else None

open Str
let rating_re = regexp "\\[[^]=]+=[0-5]\\]"
let rating_split = regexp "[][=]"

let parse_rating str =
	Log.debug (fun m->m"parsing comment substring: %s" str);
	let parsed =
		match Str.full_split rating_split str with
			| [Delim "["; Text name; Delim "="; Text value; Delim "]"] ->
					(try Some (int_of_string value) with Failure _ -> None)
						|> Option.map (fun value -> (name, value))
			| _ -> None
	in
	let () = if parsed = None then
		Log.warn (fun m->m"Couldn't extract irank rating from string: %s" str)
	in parsed

let parse comment : Irank.t =
	(* I don't care about the stuff between the "delimiters", it's just a
	 * cheeky way to ust get all the matched strings :shrug: *)
	let parsed = Str.full_split rating_re comment |> List.filter_map (function
		| Delim s -> Some s
		| Text _ -> None
	) |> List.filter_map parse_rating in
	blank_ratings () |> List.map (fun rating ->
		{ rating with rating_value = List.assoc_opt rating.rating_name parsed |> Option.default 0 }
	)

open Remo_common
module Unix = Unix_ext
module R = Rresult_ext
open Astring

let init () =
	Logs.set_level (Some (
		Unix.getenv_opt "LOG_LEVEL" |> Option.map Logs.level_of_string |> Option.bind R.get_ok |> Option.default Logs.Info
	));
	(* Quiet, cohttp *)
	Logs.Src.list () |> List.iter (fun src ->
		if String.is_prefix ~affix:"cohttp." (Logs.Src.name src) then
			Logs.Src.set_level src (Some Info)
	);
	let tagging_reporter parent =
		{ Logs.report = (fun src level ~over k user_msgf ->
			if (Logs.Src.equal src Logs.default || level = Logs.App) then
				parent.Logs.report src level ~over k user_msgf
			else
				parent.Logs.report src level ~over k (fun outer_msgf ->
					user_msgf (fun ?header ?tags fmt ->
						outer_msgf ?header ?tags ("[%a %s] @[" ^^ fmt ^^ "@]")
							Logs.pp_level level
							(Logs.Src.name src)
					)
			)
		)}
	in
	let default_reporter =
		let pp_header _ _ = () in
		Logs.format_reporter ~pp_header ()
	in
	Logs.set_reporter (tagging_reporter default_reporter)

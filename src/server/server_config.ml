open Remo_common
module R = Rresult_ext
open Sexplib
open Sexplib.Std

type job_configuration = {
	job: Job.job_identity;
	command: string list;
} [@@deriving sexp]

type config = {
	state_directory: string;
	config_path: string;
	jobs: job_configuration list;
} [@@deriving sexp]

open Sexp

let unparseable sexp = Error (List [Atom "Unparseable"; sexp])

let parse_cmd cmd : (string list, Sexp.t) result = cmd |> List.map (function
	| Atom arg -> Ok arg
	| other -> unparseable other
) |> R.collect

let parse_jobs jobs =
	jobs |> List.map (fun job -> match job with
		| List [Atom id; Atom name; List command] ->
				parse_cmd command |> R.map (fun command ->
					{
						job = Job.{ id; name };
						command;
					}
				)
		| other -> unparseable other
	) |> R.collect

let parse_config conf = function
	| List [Atom "jobs"; List jobs] ->
			parse_jobs jobs |> R.map (fun jobs -> { conf with jobs })
	| other -> unparseable other

let accum_config conf directive = R.bind conf (fun conf -> parse_config conf directive)

let load ~state_dir path =
	let load_file () =
		try
			Sexp.load_sexps path
		with
			| Unix.Unix_error (Unix.ENOENT, _, _)
			| Sys_error _ -> []
	in
	R.bind (R.catch_exn load_file) (fun config ->
		let initial_config = {
			state_directory = state_dir;
			config_path = path;
			jobs = [];
		} in
		config |> List.fold_left accum_config (Ok initial_config)
	)

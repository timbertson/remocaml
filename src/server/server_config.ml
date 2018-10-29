open Remo_common
module R = Rresult_ext
open Sexplib
open Sexplib.Std

type job_configuration = {
	job: Job.job_identity;
	command: string list;
} [@@deriving sexp]

type running_job = {
	pid: int;
	output: Unix.file_descr;
}

type config = {
	state_directory: string;
	config_path: string;
	jobs: job_configuration list;
} [@@deriving sexp]

open Sexp

let unparseable sexp = Error (List [Atom "Unparseable"; sexp])

let parse_jobs jobs =
	jobs |> List.fold_left (fun jobs job -> R.bind jobs (fun _jobs -> match job with
	| _x -> unparseable (Atom "TODO")
	)) (Ok [])

let parse_config conf = function
	| List [Atom "jobs"; List jobs] ->
			parse_jobs jobs |> R.map (fun jobs -> { conf with jobs })
	| other -> unparseable other

let accum_config conf directive = R.bind conf (fun conf -> parse_config conf directive)

let load ~state_dir path =
	let load_file () =
		try
			Sexp.load_sexps path
		with Unix.Unix_error (Unix.ENOENT, _, _) -> []
	in
	R.bind (R.catch_exn load_file) (fun config ->
		let initial_config = {
			state_directory = state_dir;
			config_path = path;
			jobs = [];
		} in
		config |> List.fold_left accum_config (Ok initial_config)
	)

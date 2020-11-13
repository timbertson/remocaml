open Remo_common
module R = Rresult_ext
open Sexplib
open Sexplib.Std
module Unix = Unix_ext
module Log = (val (Logs.src_log (Logs.Src.create "server_config")))

type job_configuration = {
	job: Job.job_identity;
	sort_order: int;
	command: string list;
} [@@deriving sexp]

let id_of_job_configuration job = job.job.Job.id

type music_configuration = {
	mpris_priority: string list;
	encourage_rating: string list;
} [@@deriving sexp]

type config = {
	state_directory: string;
	config_path: string;
	jobs: job_configuration list;
	music: music_configuration;
	irank: bool;
} [@@deriving sexp]

open Sexp

let unparseable sexp = Error (List [Atom "Unparseable"; sexp])

let parse_cmd cmd : string list R.std_result = cmd |> List.map (function
	| Atom arg -> Ok arg
	| other -> unparseable other
) |> R.collect

let parse_jobs jobs =
	jobs |> List.mapi (fun sort_order job -> match job with
		| List [Atom id; Atom name; List command] ->
				parse_cmd command |> R.map (fun command ->
					{
						job = Job.{ id; name };
						sort_order;
						command;
					}
				)
		| other -> unparseable other
	) |> R.collect

let parse_strings strings =
	strings |> List.map (fun job -> match job with
		| Atom s -> Ok s
		| other -> unparseable other
	) |> R.collect

let parse_config conf = function
	| List [Atom "jobs"; List jobs] ->
			parse_jobs jobs |> R.map (fun jobs -> { conf with jobs })
	| List [Atom "mpris"; List names] ->
			parse_strings names |> R.map (fun names -> { conf with music = { conf.music with mpris_priority = names }})
	| List [Atom "encourage-rating"; List names] ->
			parse_strings names |> R.map (fun names -> { conf with music = { conf.music with encourage_rating = names }})
	| List [Atom "irank"; Atom value] as irank -> (
			match value with
				| "true" -> Ok { conf with irank = true }
				| "false" -> Ok { conf with irank = false }
				| _ -> unparseable irank
	)
	| other -> unparseable other

let accum_config conf directive = R.bind conf (fun conf -> parse_config conf directive)


let home = Unix.getenv_opt "HOME" |> Option.force

let state_dir =
	let runtime_dir = Unix.getenv_opt "XDG_RUNTIME_DIR" |> Option.default "/tmp" in
	Unix.getenv_opt "REMOCAML_STATE" |> Option.default (Filename.concat runtime_dir "remocaml")
	
let config_path = Unix.getenv_opt "REMOCAML_CONFIG" |> Option.default (Filename.concat home ".config/remocaml/config.sexp")

let load ~state_dir path =
	let load_file path =
		Log.info (fun m->m "Loading config from %s" path);
		try
			Sexp.load_sexps path
		with
			| Unix.Unix_error (Unix.ENOENT, _, _)
			| Sys_error _ -> []
	in
	R.bind (R.wrap load_file path) (fun config ->
		let initial_config = {
			state_directory = state_dir;
			config_path = path;
			jobs = [];
			irank = false;
			music = {
				mpris_priority = [];
				encourage_rating = [];
			};
		} in
		config |> List.fold_left accum_config (Ok initial_config)
	)

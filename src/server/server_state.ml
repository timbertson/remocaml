open Remo_common
open Util
module R = Rresult_ext
(* open Astring *)
(* open Sexplib *)
open Sexplib.Std

module Unix = struct
	include Unix
	let int_of_file_descr : file_descr -> int = Obj.magic
	let file_descr_of_int : int -> file_descr = Obj.magic
	let sexp_of_file_descr = sexp_of_int % int_of_file_descr
	let file_descr_of_sexp = file_descr_of_int % int_of_sexp
end

type running_job = {
	running_job_id: Job.job_identity;
	pid: int;
	stdout: Unix.file_descr; (* TODO: how to specify sexp? *)
	output_buffer: string list option;
	display_output: bool;
} [@@deriving sexp]

type state = {
	server_config: Server_config.config;
	server_music_state: Music.state;
	server_jobs: running_job list;
} [@@deriving sexp]

let pid_status =
	(* TODO: Unix.kill? *)
	Job.Exited None

(* open Sexp *)

let load = R.wrap (fun server_config ->
	(* let dir = config.Server_config.state_directory in *)
	(* let files = Unix.readdir config.Server_config.state_directory in *)
	(* let pids = List.map (String.cut ~rev:true sep:".") |> List.filter_map (function *)
	(* 	| pid, "" -> *)
	(* 			let pid = try Some int_of_string pid with Failure _ -> None in *)
	(* 			{ pid; state = Job.pid_status pid; } *)
  (*  *)
	(* 				pid =  *)
	(* 				state = ext) with Failure -> None *)
	(* 			try (Some { *)
	(* 				pid = int_of_string pid; *)
	(* 				state = ext) with Failure -> None *)
	(* 	| pid, ext ->  *)
	(* in *)
	{
		server_config;
		server_music_state = Music.init ();
		server_jobs = []; (* TODO *)
	}
)

let running_client_job job =
	Job.({
		job = job.running_job_id;
		state = {
			running = true; (* Status enum? *)
			output = if job.display_output then job.output_buffer else None;
		}
	})

let client_state state =
	State.({
		music_state = state.server_music_state;
		job_state = {jobs = state.server_jobs |> List.map running_client_job };
	})


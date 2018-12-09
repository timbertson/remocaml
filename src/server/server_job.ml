open Remo_common
module List = List_ext
module R = Rresult_ext
open Astring
open Sexplib
open Sexplib.Std
open Sexplib.Conv
module Log = (val (Logs.src_log (Logs.Src.create "server_state")))
module StringMap = Map.Make(String)
open Job

(* A job execution. Either running or recently-run *)
type job_execution = {
	job_id: string;
	pid: int;
	ex_state: Job.process_state;
	stdout: (Unix.file_descr, Sexp.t) result Lazy.t sexp_opaque;
	output_buffer: string list option;
	display_output: bool;
} [@@deriving sexp_of]

(* a server's representation of a (possibly executing) job *)
type job = {
	job_configuration: Server_config.job_configuration;
	execution: job_execution option;
} [@@deriving sexp_of]

(* serialized to CONFIG_DIR/<job-id>.status *)
type pid_status = {
	ps_pid: int;
	ps_state: Job.process_state;
} [@@deriving sexp]

let is_running pid =
	let open Unix in
	try
		kill pid 0;
		true
	with
		Unix_error (ESRCH, _, _) -> false

let update_process_state pid = let open Job in function
	| Exited _ as state -> state
	| Running -> if is_running pid then Running else Exited None

let load_state config state_dir =
	R.wrap Sys.readdir state_dir |> R.map (fun files ->
		(* TODO: delete old files! *)
		let pid_states = files |> Array.to_list |> List.filter_map (fun filename ->
			match String.cut ~rev:true ~sep:"." filename with
				| Some (job_id, "status") ->
						let full_path = Filename.concat state_dir filename in
						Some (full_path |> R.wrap (fun path ->
							(job_id, pid_status_of_sexp (Sexp.load_sexp ~strict:true path))
						) |> R.reword_error (fun cause -> let open Sexp in
							List [ List [Atom "path"; Atom full_path]; cause]
						))
				| _ -> None
		) in
		let pid_states, pid_errs = R.partition pid_states in
		pid_errs |> List.iter (fun err ->
			Log.warn (fun m->m"%s" (Sexp.to_string err))
		);

		let executions = pid_states |> List.map (fun (job_id, st) ->
			let stdout_path = Filename.concat state_dir job_id ^ ".out" in
			let open_stdout () = Unix.openfile stdout_path Unix.[O_RDONLY; O_CLOEXEC] 0o600 in
			{
				job_id;
				pid = st.ps_pid;
				ex_state = update_process_state st.ps_pid st.ps_state;
				stdout = lazy (R.wrap open_stdout ());
				output_buffer = None;
				display_output = false;
			}
		) in

		(* Make a map of (ref config, ref running_job) *)
		let job_map = config.Server_config.jobs |> List.fold_left (fun map job_conf ->
			StringMap.add (job_conf.Server_config.job.Job.id) (Some job_conf, None) map
		) StringMap.empty in

		let job_map = executions |> List.fold_left (fun map job ->
			let record = match StringMap.find_opt job.job_id map with
				| Some (conf, _) -> (conf, Some job)
				| None -> (None, Some job)
			in
			StringMap.add job.job_id record map
		) job_map in

		let server_jobs = StringMap.fold (fun _key value jobs ->
			match value with
				| None, None -> jobs (* can't actually happen *)
				| None, Some job ->
						Log.warn (fun m->m"Running job has no corresponding configuration: %s" job.job_id);
						jobs
				| Some conf, execution ->
					{ job_configuration = conf; execution } :: jobs
		) job_map [] in
		server_jobs
	)

let running_client_job job =
	Job.({
		job = job.job_configuration.Server_config.job;
		state = job.execution |> Option.map (fun execution ->
			{
				process_state = execution.ex_state;
				output = if execution.display_output then execution.output_buffer else None;
			}
		)
	})

let stop job =
	job.execution |> Option.map (function { ex_state; pid; _ } ->
		let open Unix in
		match ex_state with
			| Exited _ as ex -> Ok (Process_state ex)
			| Running ->
				R.wrap (kill pid) 15 |> R.map (fun () ->
					let (_pid, pid_status) = waitpid [] pid in
					let state = match pid_status with
						| WEXITED code -> Exited (Some code)
						| WSIGNALED _ | WSTOPPED _ -> Exited (Some 127)
					in
					Process_state state
				)
	) |> Option.default (Ok (Job_state None))

let invoke : job list -> Job.command -> (unit, Sexplib.Sexp.t) result Lwt.t = fun jobs (id, cmd) ->
	let job = jobs |> List.find_opt (fun job -> job.job_configuration.job.id = id) in
	Lwt.return (job |> Option.map (fun job ->
		(match cmd with
			| Start -> failwith "TODO"
			| Stop -> stop job
			| Refresh -> failwith "TODO"
			| Show_output _show -> failwith "TODO"
			(* TODO: broadcast should be the job of the server, not this module *)
		) |> R.map (fun event -> Connections.broadcast (Ok (Job_event (id, event))))
	) |> Option.default (Error (Sexp.Atom "No such job")))

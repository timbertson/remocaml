open Remo_common
module List = List_ext
module R = Rresult_ext
open Astring
open Sexplib
open Sexplib.Conv
module Log = (val (Logs.src_log (Logs.Src.create "server_job")))
module StringMap = Map.Make(String)
open Job

let devnull = Unix.(openfile "/dev/null" [O_RDONLY; O_CLOEXEC]) 0o600

(* A job execution. Either running or recently-run *)
type job_execution = {
	job_id: string;
	pid: int;
	ex_state: Job.process_state;
	stdout : string Lwt_stream.t option sexp_opaque;
	termination: int option Lwt.t sexp_opaque;
} [@@deriving sexp_of]

(* a server's representation of a (possibly executing) job *)
type job = {
	job_configuration: Server_config.job_configuration;
	execution: job_execution option;
} [@@deriving sexp_of]

type state = job list

(* serialized to CONFIG_DIR/<job-id>.status *)
type pid_status = {
	ps_pid: int;
	ps_state: Job.process_state;
} [@@deriving sexp]

type internal_event =
	| External of Job.job_event
	| Job_executing of job_execution

let update_internal : state:state -> string -> internal_event -> (state * Event.event option)
	= fun ~state id -> function
		| External event -> (state, Some (Job_event (id, event)))
		| Job_executing _execution ->
				(* TODO *)
				(state, None)

let watch_termination pid =
	let open Lwt_unix in
	let%lwt (_pid, pid_status) = waitpid [] pid in
	Lwt.return (match pid_status with
		| WEXITED code -> Some code
		| WSIGNALED _ | WSTOPPED _ -> Some 127
	)

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

let log_filename ~state_dir ~job_id =
	Filename.concat state_dir (job_id ^ ".out")

let open_readable path = Unix.openfile path Unix.[O_RDONLY; O_CLOEXEC] 0o600
let open_writeable path = Unix.openfile path Unix.[O_WRONLY; O_TRUNC; O_CLOEXEC] 0o600

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
			{
				job_id;
				pid = st.ps_pid;
				ex_state = update_process_state st.ps_pid st.ps_state;
				stdout = None;
				termination = watch_termination st.ps_pid;
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
				output = None; (* TODO *)
			}
		)
	})

let stop job =
	job.execution |> Option.map (function { ex_state; pid; _ } ->
		match ex_state with
			| Exited _ as ex -> Ok (Some (Process_state ex))
			| Running -> R.wrap (Unix.kill pid) Sys.sigint |> R.map (fun () -> None)
	) |> Option.default (Ok (Some (Job_state None)))

let start ~state_dir job = (
	job.execution |> Option.fold (Ok ()) (function { ex_state; _ } ->
		match ex_state with
			| Running -> Error (Sexp.Atom "Job is already running")
			| _finished -> Ok ()
	) |> R.bindr (fun () ->
		let config = job.job_configuration in
		let log_filename = log_filename ~state_dir ~job_id:config.job.id in
		let log_file = open_writeable log_filename in
		R.wrap (Unix.create_process "todo" [|"todo"|] devnull log_file) log_file
		|> R.map (fun pid ->
			Job_executing {
				job_id = config.job.id;
				pid = pid;
				ex_state = Running;
				stdout = None;
				termination = watch_termination pid;
			}
		)
	)
)

let invoke : state -> Job.command -> Event.event option R.std_result Lwt.t = fun jobs (id, cmd) ->
	let job = jobs |> List.find_opt (fun job -> job.job_configuration.job.id = id) in
	job |> Option.map (fun job ->
		(* TODO: update job status in case it's changed behind us? *)
		(match cmd with
			| Start -> failwith "TODO"
			| Stop -> Lwt.return (stop job)
			| Refresh -> failwith "TODO"
			| Show_output _show -> failwith "TODO"
		) |> Lwt.map (R.map (Option.map (fun event -> Event.Job_event (id, event))))
	) |> Option.default (Lwt.return (Error (Sexp.Atom "No such job")))

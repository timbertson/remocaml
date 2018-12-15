open Remo_common
module List = List_ext
module R = Rresult_ext
open Astring
open Sexplib
open Sexplib.Conv
open Job

module Log = (val (Logs.src_log (Logs.Src.create "server_job")))
module StringMap = struct
	include Map.Make(String)
	let build : ('a -> key * 'b) -> 'a list -> 'b t = fun fn items ->
		List.fold_left (fun map item ->
			let k,v = fn item in
			add k v map
		) empty items

	let build_keyed : ('a -> key) -> 'a list -> 'a t = fun fn items ->
		List.fold_left (fun map item ->
			let k = fn item in
			add k item map
		) empty items
end

let devnull = Unix.(openfile "/dev/null" [O_RDONLY; O_CLOEXEC]) 0o600

(* A job execution. Either running or recently-run *)
type job_execution = {
	job_id: string;
	pid: int;
	ex_state: Job.process_state;
	stdout : string Lwt_stream.t option sexp_opaque;
	termination: int option Lwt.t sexp_opaque;
} [@@deriving sexp_of]

let id_of_job_execution ex = ex.job_id

(* a server's representation of a (possibly executing) job *)
type job = {
	job_configuration: Server_config.job_configuration;
	execution: job_execution option;
} [@@deriving sexp_of]

type jobs = job StringMap.t (* [@@deriving sexp_of] *)
let sexp_of_jobs = fun map ->
	Sexp.List (map |> StringMap.bindings |> List.map (fun (_, v) ->
		sexp_of_job v
	))

type state = {
	jobs: jobs;
	dir: string;
} [@@deriving sexp_of]


(* serialized to CONFIG_DIR/<job-id>.status *)
type pid_status = {
	ps_pid: int;
	ps_state: Job.process_state;
} [@@deriving sexp]

type internal_event =
	| External of Job.job_event
	| Job_executing of job_execution

let update_internal : state:state -> string -> internal_event -> (jobs * Event.event) option
	= fun ~state id -> function
		| External event -> Some (state.jobs, Job_event (id, event))
		| Job_executing _execution ->
				(* TODO *)
				None

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

let log_filename ~state ~job_id =
	Filename.concat state.dir (job_id ^ ".out")

let open_readable path = Unix.openfile path Unix.[O_RDONLY; O_CLOEXEC] 0o600
let open_writeable path = Unix.openfile path Unix.[O_WRONLY; O_TRUNC; O_CLOEXEC] 0o600

let load_state config state_dir : state R.std_result =
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

		(* Make a map of job configs first *)
		let job_map = config.Server_config.jobs
			|> StringMap.build_keyed Server_config.id_of_job_configuration in

		(* then merge it with executions *)
		let execution_map = executions |> StringMap.build_keyed id_of_job_execution in
		let jobs = StringMap.mapi (fun id conf ->
			{
				job_configuration = conf;
				execution = StringMap.find_opt id execution_map;
			}
		) job_map in

		execution_map |> StringMap.iter (fun id _ ->
			if not (StringMap.mem id jobs) then
				Log.warn (fun m->m"Running job has no corresponding configuration, ignoring: %s" id);
		);

		{ dir = state_dir; jobs }
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

let start ~state job = (
	job.execution |> Option.fold (Ok ()) (function { ex_state; _ } ->
		match ex_state with
			| Running -> Error (Sexp.Atom "Job is already running")
			| _finished -> Ok ()
	) |> R.bindr (fun () ->
		let config = job.job_configuration in
		let log_filename = log_filename ~state ~job_id:config.job.id in
		let log_file = open_writeable log_filename in
		R.wrap (Unix.create_process "todo" [|"todo"|] devnull log_file) log_file
		|> R.map (fun pid ->
			Some (Job_executing {
				job_id = config.job.id;
				pid = pid;
				ex_state = Running;
				stdout = None;
				termination = watch_termination pid;
			})
		)
	)
)

let invoke : state -> Job.command -> (jobs * Event.event) option R.std_result = fun state (id, cmd) ->
	let job = state.jobs |> StringMap.find_opt id in
	job |> Option.map (fun job ->
		(* TODO: update job status in case it's changed behind us? *)
		(match cmd with
			| Start -> start ~state job
			| Stop -> stop job |> R.map (Option.map (fun x -> External x))
			| Refresh -> failwith "TODO"
			| Show_output _show -> failwith "TODO"
		) |> R.map (Option.bind (fun internal_event ->
			update_internal ~state id internal_event
		))
	) |> Option.default (Error (Sexp.Atom "No such job"))

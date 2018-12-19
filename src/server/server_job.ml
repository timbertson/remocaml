open Remo_common
module List = List_ext
module R = Rresult_ext
open Astring
open Sexplib
open Sexplib.Conv
open Job
open React

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
	output_watch: unit Lwt.t option sexp_opaque;
} [@@deriving sexp_of]

let id_of_job_execution ex = ex.job_id

(* a server's representation of a (possibly executing) job *)
type job = {
	job_configuration: Server_config.job_configuration;
	execution: job_execution option;
} [@@deriving sexp_of]
let id_of_job job = Server_config.id_of_job_configuration job.job_configuration

type jobs = job StringMap.t (* [@@deriving sexp_of] *)
let sexp_of_jobs = fun map ->
	Sexp.List (map |> StringMap.bindings |> List.map (fun (_, v) ->
		sexp_of_job v
	))

type state = {
	jobs: jobs;
	dir: string;
	events: Event.event R.std_result E.t sexp_opaque;
	emit: (Job.event R.std_result -> unit) sexp_opaque;
} [@@deriving sexp_of]


let log_ext = "out"
let state_ext = "state"
let log_filename ~state ~job_id =
	Filename.concat state.dir (job_id ^ "." ^ log_ext)

let state_filename ~state ~job_id =
	Filename.concat state.dir (job_id ^ "." ^ state_ext)

let open_readable path =
	Unix.openfile path Unix.[O_RDONLY; O_CLOEXEC] 0o600

let open_writeable path =
	Unix.openfile path Unix.[O_WRONLY; O_CREAT; O_TRUNC; O_CLOEXEC] 0o600

(* serialized to CONFIG_DIR/<job-id>.state *)
type pid_status = {
	ps_pid: int;
	ps_state: Job.process_state;
} [@@deriving sexp]

let pid_status_of_job job = job.execution |> Option.map (fun ex -> {
	ps_pid = ex.pid;
	ps_state = ex.ex_state;
})

type internal_event =
	| External of Job.job_event
	| Job_executing of job_execution

let external_of_job job =
	Job.({
		job = job.job_configuration.Server_config.job;
		state = job.execution |> Option.map (fun execution -> execution.ex_state);
		output = None; (* TODO *)
	})

let update_pid_status ~state job =
	let path = state_filename ~state ~job_id:(id_of_job job) in
	match pid_status_of_job job with
		| None -> Unix_ext.ensure_unlinked path
		| Some status ->
			let tmp = path ^ ".tmp" in
			let contents = Sexp.to_string (sexp_of_pid_status status) |> Bytes.of_string in
			let f = open_writeable tmp in
			let () = try
				let _:int = Unix.write f contents 0 (Bytes.length contents) in
				Unix.close f;
			with e -> (
				Unix.close f; raise e
			) in
			Unix.rename tmp path

let update_internal : state:state -> job -> internal_event -> (jobs * Event.event)
	= fun ~state job event ->
	let update_status job =
		update_pid_status ~state job;
		Some job
	in

	let updated_job, event = match event with
		| External event ->
			let update_ex_state job ex_state =
				update_status ({ job with
					execution = job.execution |> Option.map (fun ex -> { ex with ex_state })
				})
			in
			(match event with
				| Process_state ex_state as event ->
					(update_ex_state job ex_state, event)
				| Output_line _ as event ->
					(None, event)
			)

		| Job_executing execution ->
			let job = { job with execution = Some execution } in
			(update_status job, Process_state (execution.ex_state))
	in
	let id = id_of_job job in
	
	let jobs = updated_job |> Option.fold state.jobs (fun job ->
		StringMap.add id job state.jobs
	) in
	(jobs, Job_event (id, event))

let watch_termination pid =
	let open Lwt_unix in
	let%lwt (_pid, pid_status) = waitpid [] pid in
	Lwt.return (match pid_status with
		| WEXITED code -> Some code
		| WSIGNALED _ | WSTOPPED _ -> Some 127
	)

let watch_output ~id ~emit filename =
	let%lwt channel = Lwt_io.(open_file ~mode:Input filename) in
	Log.debug(fun m->m"watching output file: %s" filename);
	let rec read () =
		Lwt.bind (Lwt_io.read_line_opt channel) (fun line ->
			Log.debug(fun m->m"saw %s for job %s" (if Option.is_some line then "line" else "EOF") id);
			match line with
				| Some line ->
					emit (Ok (id, Output_line line));
					read ()
				| None -> Lwt.return_unit
		)
	in
	(try%lwt
		read ()
	with e -> raise e
	) [%lwt.finally
		Lwt_io.close channel
	]

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

let load_state config state_dir : state R.std_result =
	Unix_ext.mkdir_p state_dir;
	R.wrap Sys.readdir state_dir |> R.map (fun files ->
		(* TODO: delete old files? *)
		let pid_states = files |> Array.to_list |> List.filter_map (fun filename ->
			match String.cut ~rev:true ~sep:"." filename with
				| Some (job_id, ext) when ext = state_ext ->
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
				output_watch = None;
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

		let events, emit = E.create () in
		let emit = fun e -> e |> R.map (fun e -> Event.Job_event e) |> emit in
		{
			dir = state_dir;
			jobs; events; emit
		}
	)

let stop job =
	job.execution |> Option.map (function { ex_state; pid; _ } ->
		match ex_state with
			| Exited _ as ex -> Ok (Some (Process_state ex))
			| Running -> R.wrap (Unix.kill pid) Sys.sigint |> R.map (fun () -> None)
	) |> Option.default (Ok None)

let start ~state job = (
	job.execution |> Option.fold (Ok ()) (function { ex_state; _ } ->
		match ex_state with
			| Running -> Error (Sexp.Atom "Job is already running")
			| _finished -> Ok ()
	) |> R.bindr (fun () ->
		let config = job.job_configuration in
		let log_filename = log_filename ~state ~job_id:config.job.id in
		R.wrap open_writeable log_filename
			|> R.prefix_error ("Can't open job output file")
			|> R.bindr (fun log_file ->
			let argv = config.command in
			let result = R.wrap (Unix.create_process (List.hd argv) (Array.of_list argv) devnull log_file) log_file
				|> R.map (fun pid ->
					Some (Job_executing {
						job_id = config.job.id;
						pid = pid;
						ex_state = Running;
						stdout = None;
						termination = watch_termination pid;
						output_watch = Some (watch_output ~id:config.job.id ~emit:state.emit log_filename);
					})
				)
			in
			Unix.close log_file;
			result
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
		) |> R.map (Option.map (fun internal_event ->
			update_internal ~state job internal_event
		))
	) |> Option.default (Error (Sexp.Atom "No such job"))

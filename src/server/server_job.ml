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
	termination: (int Lwt.t [@sexp.opaque]);
	output_watch: (unit Lwt.t option [@sexp.opaque]);
} [@@deriving sexp_of]

let id_of_job_execution ex = ex.job_id

(* a server's representation of a (possibly executing) job *)
type job = {
	job_configuration: Server_config.job_configuration;
	external_job: Job.job;
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
	events: (Event.event R.std_result E.t [@sexp.opaque]);
	emit: ((Job.event R.std_result -> unit) [@sexp.opaque]);
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
	ps_state: Job.process_state option;
} [@@deriving sexp]

let pid_status_of_job job = job.execution |> Option.map (fun ex -> {
	ps_pid = ex.pid;
	ps_state = job.external_job.state;
})

type internal_event =
	| External of Job.job_event
	| Job_execution of job_execution

let external_of_job job = job.external_job

let update_pid_status ~state ~id status =
	let path = state_filename ~state ~job_id:id in
	Log.debug(fun m->m"updating pid status at %s" path);
	match status with
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

let update_internal : state:state -> job -> internal_event list -> (jobs * Event.event list)
	= fun ~state job events ->
	let initial_status = pid_status_of_job job in
	let id = id_of_job job in

	let (job, events) : job * Job.job_event list = List.fold_left (fun (job, acc) event ->
		let (job, new_events) = match event with
			| External event ->
				{ job with external_job = Job.update_job job.external_job event }, [event]

			| Job_execution execution ->
				{ job with execution = Some execution }, []
		in
		(job, acc @ new_events)
	) (job, []) events
	in
	let jobs = StringMap.add id job state.jobs in

	let pid_status = pid_status_of_job job in
	(* keep on disk version accurate *)
	if (initial_status <> pid_status) then (
		update_pid_status ~state ~id pid_status
	);

	let events = events |> List.map (fun e -> Event.Job_event (id, e)) in
	(jobs, events)

let is_running pid =
	let open Unix in
	try
		kill pid 0;
		true
	with
		Unix_error (ESRCH, _, _) -> false

let get_process_state pid = let open Job in function
	| Exited _ as state -> state
	| Running -> if is_running pid then Running else Exited None

let watch_termination ~id ~emit pid =
	let open Lwt_unix in
	emit (Ok (id, Process_state Running));
	let%lwt (_pid, pid_status) = waitpid [] pid in
	let status = match pid_status with
		| WEXITED code -> code
		| WSIGNALED _ | WSTOPPED _ -> 127
	in
	Log.info (fun m->m "PID %d terminated with status %d" pid status);
	emit (Ok (id, Process_state (Exited (Some status))));
	Lwt.return status

let output_delay_max = 10.0
let output_delay_min = 0.5
let output_delay_scale = 1.1

let watch_output ~id ~termination ~emit filename =
	let%lwt channel = Lwt_io.(open_file ~mode:Input filename) in
	Log.debug(fun m->m"watching output file: %s" filename);
	let buffer = Buffer.create 1024 in
	let emit_line () =
		let line = Buffer.contents buffer in
		Buffer.clear buffer;
		emit (Ok (id, Output_line line))
	in
	emit (Ok (id, Output (Job.Output.Output [])));
	let rec read next_timeout =
		Lwt.bind (Lwt_io.read_char_opt channel) (function
			| Some '\n' ->
					Log.debug(fun m->m"[%s] saw line" id);
				emit_line ();
				read None
			| Some ch ->
				Buffer.add_char buffer ch;
				read None
			| None ->
				let read_after_delay t =
					(* TODO inotify / select? *)
					Log.debug(fun m->m"[%s] saw EOF, sleeping for %f seconds" id t);
					let%lwt () = Lwt_unix.sleep t in
					let t = min output_delay_max (t *. output_delay_scale) in
					read (Some t)
				in
				(match next_timeout with
					| None -> read_after_delay output_delay_min
					| Some t ->
						(* this isn't the first EOF, break if process has ended. This is an attempt
						 * to avoid the race condition where we see the process end before we read the last byte *)
						if Lwt.is_sleeping termination then
							(* still running *)
							read_after_delay t
						else (
							(* if there's a trailing line, emit it before stopping *)
							if (Buffer.length buffer > 0) then (
								emit_line ()
							);
							Log.debug(fun m->m"output_watch for %s terminated" id);
							Lwt.return_unit
						)
				)
		)
	in
	(try%lwt
		read None
	with e -> raise e
	) [%lwt.finally
		Lwt_io.close channel
	]

let load_state config state_dir : state R.std_result =
	Unix_ext.mkdir_p state_dir;
	R.wrap Sys.readdir state_dir |> R.map (fun files ->
		(* TODO: delete old files? *)
		let pid_states = files |> Array.to_list |> List.filter_map (fun filename ->
			match String.cut ~rev:true ~sep:"." filename with
				| Some (job_id, ext) when ext = state_ext -> (
						let full_path = Filename.concat state_dir filename in
						Log.debug (fun m->m"Loading job_state %s" full_path);
						Some (full_path |> R.wrap (fun path ->
							let loaded = (Sexp.load_sexp ~strict:true path) in
							Log.debug (fun m->m"Loaded: %a" Sexp.pp loaded);
							(job_id, pid_status_of_sexp loaded)
						) |> R.reword_error (fun cause -> let open Sexp in
							List [ List [Atom "path"; Atom full_path]; cause]
						))
				)
				| _ -> None
		) in
		let pid_states, pid_errs = R.partition pid_states in
		pid_errs |> List.iter (fun err ->
			Log.warn (fun m->m"%s" (Sexp.to_string err))
		);

		(* TODO: represent events as a react stream with compositions of log & status, rather
		 * than imperatively emitting events *)
		let events, emit = E.create () in
		let emit = fun e -> e |> R.map (fun e -> Event.Job_event e) |> emit in

		let executions = pid_states |> List.map (fun (job_id, st) ->
			let pid = st.ps_pid in
			let termination = watch_termination ~id:job_id ~emit pid in
			let pid_status = st.ps_state |> Option.map (get_process_state st.ps_pid) in
			({
				job_id; pid; termination;
				output_watch = None;
			}, pid_status)
		) in

		(* Make a map of job configs first *)
		let job_map = config.Server_config.jobs
			|> StringMap.build_keyed Server_config.id_of_job_configuration in

		(* then merge it with executions *)
		let execution_map = executions |> StringMap.build_keyed (fun (ex,_) -> id_of_job_execution ex) in
		let jobs = StringMap.mapi (fun id conf ->

			let execution, pid_status = match StringMap.find_opt id execution_map with
				| Some (ex, pid_status) -> Some ex, pid_status
				| None -> None, None
			in
			Log.debug (fun m->m "Found execution %s with status %s for job %s (output_watch: %s)"
				(Option.to_string Sexp.to_string (execution |> Option.map sexp_of_job_execution))
				(Option.to_string Sexp.to_string (pid_status |> Option.map Job.sexp_of_process_state))
				id
				(match (execution |> Option.bind (fun ex -> ex.output_watch)) with | None -> "None" | Some _ -> "Some")
			);
			{
				job_configuration = conf;
				execution;
				external_job = {
					job = conf.Server_config.job;
					state = pid_status;
					output = Job.Output.Undefined;
				};
			}
		) job_map in

		execution_map |> StringMap.iter (fun id _ ->
			if not (StringMap.mem id jobs) then
				Log.warn (fun m->m"Running job has no corresponding configuration, ignoring: %s" id);
		);

		{
			dir = state_dir;
			jobs; events; emit
		}
	)

let stop job : unit R.std_result =
	job.execution |> Option.map (function { pid; termination; _ } ->
		Log.info (fun m->m"stopping job with PID %d" pid);
		if Lwt.is_sleeping termination then (
				Log.debug (fun m->m"Killing with %d..." Sys.sigint);
				R.wrap (Unix.kill (-pid)) Sys.sigint
		) else (
			Log.debug (fun m->m"Already terminated...");
			Ok ()
		)
	) |> Option.default (Ok ())

let create_detached_process exe argv stdin stdout =
	R.wrap Unix.fork () |> R.map (function
		| 0 -> (
			Unix.dup2 stdin Unix.stdin;
			Unix.dup2 stdout Unix.stdout;
			Unix.dup2 stdout Unix.stderr;
			Unix.close stdin;
			Unix.close stdout;
			let (_: int) = Unix.setsid () in
			Unix.execvp exe argv
		)
		| pid -> pid
	)

let start_watching_output ~state ~(config:Server_config.job_configuration) execution = (
	let log_filename = log_filename ~state ~job_id:config.job.id in
	{ execution with output_watch =
		Some (watch_output
			~id:execution.job_id
			~termination:execution.termination
			~emit:state.emit
			log_filename
		);
	}
)

let show_output ~state job show = (
	job.execution |> Option.map (fun execution ->
		match show, execution.output_watch with
			| true, Some(_) | false, None ->
					Log.info (fun m->m"Not toggling output display to %b, it already is" show);
				Ok []

			| true, None ->
				let config = job.job_configuration in
				Ok [Job_execution (start_watching_output ~state ~config execution)]

			| false, Some(watch) ->
				Lwt.cancel watch;
				Ok [
					Job_execution { execution with output_watch = None };
					External (Output Job.Output.Undefined); (* disable display *)
				]
	) |> Option.default (Ok [])
)

let start ~state job : internal_event list R.std_result = (
	job.external_job.state |> Option.fold (Ok ()) (function job_state ->
		match job_state with
			| Running -> Error (Sexp.Atom "Job is already running")
			| Exited _ -> Ok ()
	) |> R.bindr (fun () ->
		let config = job.job_configuration in
		let log_filename = log_filename ~state ~job_id:config.job.id in
		R.wrap open_writeable log_filename
			|> R.prefix_error ("Can't open job output file")
			|> R.bindr (fun log_file ->
			let argv = config.command in
			let result = create_detached_process (List.hd argv) (Array.of_list argv) devnull log_file
				|> R.map (fun pid ->
					let termination = watch_termination ~id:config.job.id ~emit:state.emit pid in
					[Job_execution (start_watching_output ~state ~config {
						job_id = config.job.id;
						pid = pid;
						termination;
						output_watch = None;
					})]
				)
			in
			Unix.close log_file;
			result
		)
	)
)

let invoke : state -> Job.command -> (jobs * Event.event list) R.std_result = fun state (id, cmd) ->
	let job = state.jobs |> StringMap.find_opt id in
	job |> Option.map (fun job ->
		(* TODO: update job status in case it's changed behind us? *)
		(match cmd with
			| Start -> start ~state job
			| Stop -> stop job |> R.map (fun () -> [])
			| Refresh -> failwith "TODO: refresh"
			| Show_output show -> show_output ~state job show
		) |> R.map (fun internal_events ->
			update_internal ~state job internal_events
		)
	) |> Option.default (Error (Sexp.Atom "No such job"))

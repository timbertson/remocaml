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
	let from_list : (key * 'a) list -> 'a t = fun items ->
		List.fold_left (fun map item ->
			let k,v = item in
			add k v map
		) empty items

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
	termination: (unit Lwt.t option [@sexp.opaque]);
	output_watch: (unit Lwt.t option [@sexp.opaque]);
}

let sexp_of_job_execution = fun ex ->
	let open Sexp in
	List [
		List [ Atom "job_id"; Atom ex.job_id ];
		List [ Atom "termination"; Atom (
			match ex.termination with
				| Some _ -> "Some"
				| None -> "None"
		)];
		List [ Atom "output_watch"; Atom (
			match ex.output_watch with
				| Some _ -> "Some"
				| None -> "None"
		)];
	]

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

let state_filename ~state_dir ~job_id =
	Filename.concat state_dir (job_id ^ "." ^ state_ext)

let open_readable path =
	Unix.openfile path Unix.[O_RDONLY; O_CLOEXEC] 0o600

let open_writeable path =
	Unix.openfile path Unix.[O_WRONLY; O_CREAT; O_TRUNC; O_CLOEXEC] 0o600

type internal_event =
	| External of Job.job_event
	| Job_execution of (Job.process_state * job_execution)
	[@@deriving sexp_of]

let external_of_job job = job.external_job

type emit_internal = internal_event R.std_result -> unit

let persist_process_state ~state_dir ~id state =
	let path = state_filename ~state_dir ~job_id:id in
	Log.debug(fun m->m"updating pid state at %s" path);
	let tmp = path ^ ".tmp" in
	let contents = Sexp.to_string (Job.sexp_of_process_state state) |> Bytes.of_string in
	let f = open_writeable tmp in
	let () = try
		let _:int = Unix.write f contents 0 (Bytes.length contents) in
		Unix.close f;
	with e -> (
		Unix.close f; raise e
	) in
	Unix.rename tmp path

(* emit an internal event by:
- translating into a public event
- updating server state (and filesystem) if necessary
*)
let emit_and_update_internal : id:string -> internal_event R.std_result -> state -> state
	= fun ~id (event: internal_event R.std_result) state ->
	state.jobs |> StringMap.find_opt id |> Option.map (fun initial_job ->
		Log.debug (fun m->m"Emitting internal event: %a" Sexp.pp (R.sexp_of_result sexp_of_internal_event event));
		let initial_state = initial_job.external_job.state in
		let id = id_of_job initial_job in
		let job = match event with
			| Ok (External event) ->
				state.emit (Ok (id, event));
				{ initial_job with external_job = Job.update_job initial_job.external_job event }

			| Ok (Job_execution (process_state, execution)) -> (
				let initial_output = initial_job.execution |> Option.bind (fun ex -> ex.output_watch) in
				let output_event = (match (initial_output, execution.output_watch) with
					| (None, None) | (Some _, Some _) -> None
					| (None, Some _) -> Some Job.Output.initial
					| (Some _, None) -> Some Job.Output.Undefined
				) in

				output_event |> Option.may (fun e ->
					state.emit (Ok (id, Output e))
				);
				Log.debug(fun m->m"internal %a == latest %a ?"
					Sexp.pp (Job.sexp_of_process_state initial_job.external_job.state)
					Sexp.pp (Job.sexp_of_process_state process_state)
				);
					
				if initial_job.external_job.state <> process_state then (
					state.emit (Ok (id, Process_state process_state))
				);

				{ initial_job with
					execution = Some execution;
					external_job = { initial_job.external_job with state = process_state };
				}
			)

			| Error e ->
				state.emit (Error e);
				initial_job
		in
		let new_state = { state with jobs = StringMap.add id job state.jobs } in

		(* keep on disk version accurate *)
		if (initial_state <> job.external_job.state) then (
			persist_process_state ~state_dir:state.dir ~id job.external_job.state
		);
		new_state
	) |> Option.default_fn (fun () ->
		state.emit (Error (Sexp.Atom "No such job"));
		state
	)

let is_running pid =
	let open Unix in
	try
		kill pid 0;
		true
	with
		Unix_error (ESRCH, _, _) -> false

let check_process_state = let open Job in function
	| Exited _ | Not_running as state -> state
	| Running pid -> if is_running pid then Running pid else Exited None

let poll_delay_max = 2.0
let poll_delay_min = 0.5
let poll_delay_scale = 1.1

let with_delay_loop : 'a. desc:string -> (int -> (unit -> 'a Lwt.t) -> 'a Lwt.t) -> 'a Lwt.t = fun ~desc fn ->
	let rec continue_after_delay count delay () =
		Log.debug(fun m->m"[%s] sleeping for %f seconds" desc delay);
		let%lwt () = Lwt_unix.sleep delay in
		let next_delay = min poll_delay_max (delay *. poll_delay_scale) in
		let count = count + 1 in
		fn count (continue_after_delay count next_delay)
	in
	fn 0 (continue_after_delay 0 poll_delay_min)

let watch_termination ~state_dir ~id ~(emit_internal:emit_internal) pid =
	let open Lwt_unix in
	Log.info (fun m->m "Watching termination of PID %d" pid);
	let desc = Printf.sprintf "%s-exit" id in
	let%lwt exit_code = (try%lwt
			(
				waitpid [] pid |> Lwt.map (fun (_pid, exit_status) ->
					Some (match exit_status with
						| WEXITED code -> code
						| WSIGNALED _ | WSTOPPED _ -> 127
					)
				)
			)
		with e -> (
			(* waitpid only works if we're the parent process; this
			loop is worse but robust to server restarts *)
			Log.info (fun m->
				m"Falling back to polling for pid: %d (error: %s)"
				pid (Printexc.to_string e)
			);
			with_delay_loop ~desc (fun _attempt_no next ->
				if is_running pid then (
					next ()
				) else (
					(* we don't know its state, but it's dead *)
					Lwt.return None
				)
			)
		)
	) in
	Log.info (fun m->m "PID %d terminated with status %s" pid (Option.to_string string_of_int exit_code));
	emit_internal (Ok (External (Process_state (Exited exit_code))));
	Lwt.return_unit

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
	let desc = Printf.sprintf "%s-output" id in
	let rec read () =
		with_delay_loop ~desc (fun attempt_no next ->
			(* Log.debug(fun m->m"readchar attempt %d" attempt_no); *)
			let%lwt ch = Lwt_io.read_char_opt channel in
			match ch with
				| Some '\n' ->
						Log.debug(fun m->m"[%s] saw line" id);
					emit_line ();
					read ()
				| Some ch ->
					Buffer.add_char buffer ch;
					read ()
					
				(* Note: EOF is the only time we invoke next, which internally
				accumulates longer delays. Other branches call read, which
				effectively resets the timer *)
				| None -> (
					if attempt_no < 1 || Lwt.is_sleeping termination then
						(* still running *)
						next ()
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
		read ()
	with e -> raise e
	) [%lwt.finally
		Lwt_io.close channel
	]

let load_state config state_dir : state R.std_result =
	Unix_ext.mkdir_p state_dir;
	R.wrap Sys.readdir state_dir |> R.map (fun files ->
		(* TODO: delete old files? *)
		let process_states = files |> Array.to_list |> List.filter_map (fun filename ->
			match String.cut ~rev:true ~sep:"." filename with
				| Some (job_id, ext) when ext = state_ext -> (
						let full_path = Filename.concat state_dir filename in
						Log.debug (fun m->m"Loading job_state %s" full_path);
						Some (full_path |> R.wrap (fun path ->
							let loaded = (Sexp.load_sexp ~strict:true path) in
							Log.debug (fun m->m"Loaded: %a" Sexp.pp loaded);
							(job_id, Job.process_state_of_sexp loaded)
						) |> R.reword_error (fun cause -> let open Sexp in
							List [ List [Atom "path"; Atom full_path]; cause]
						))
				)
				| _ -> None
		) in
		let process_states, pid_errs = R.partition process_states in
		pid_errs |> List.iter (fun err ->
			Log.warn (fun m->m"%s" (Sexp.to_string err))
		);
		let process_map = process_states |> StringMap.from_list in

		(* TODO: represent events as a react stream with compositions of log & status, rather
		 * than imperatively emitting events *)
		let events, emit = E.create () in
		let emit = fun e -> e |> R.map (fun e -> Event.Job_event e) |> emit in

		(* Make a map of job configs first *)
		let job_map = config.Server_config.jobs
			|> StringMap.build_keyed Server_config.id_of_job_configuration in

		(* then merge it with executions *)
		let jobs = StringMap.mapi (fun id conf ->

			let (execution, process_state) = match StringMap.find_opt id process_map with
				| Some process_state -> (
					let execution = {
						job_id = id;
						termination = None;
						output_watch = None;
					} in
					Some execution, check_process_state process_state
				)
				| None -> None, Not_running
			in
			Log.debug (fun m->m "Found execution %s with status %s for job %s (output_watch: %s)"
				(Option.to_string Sexp.to_string (execution |> Option.map sexp_of_job_execution))
				(Sexp.to_string (Job.sexp_of_process_state process_state))
				id
				(match (execution |> Option.bind (fun ex -> ex.output_watch)) with | None -> "None" | Some _ -> "Some")
			);
			{
				job_configuration = conf;
				execution;
				external_job = {
					job = conf.Server_config.job;
					state = process_state;
					output = Job.Output.Undefined;
				};
			}
		) job_map in

		process_map |> StringMap.iter (fun id _ ->
			if not (StringMap.mem id jobs) then
				Log.warn (fun m->m"Running job has no corresponding configuration, ignoring: %s" id);
		);

		{
			dir = state_dir;
			jobs; events; emit
		}
	)

let stop job : unit R.std_result =
	match job.external_job.state with
		| Running pid -> (
			Log.info (fun m->m"stopping job with PID %d" pid);
			R.wrap (Unix.kill (-pid)) Sys.sigint
		)
		| Not_running | Exited _ -> (
			Log.warn (fun m->m"can't stop job %s in state %a"
				job.job_configuration.job.id
				Sexp.pp (Job.sexp_of_process_state job.external_job.state)
			);
			Ok ()
		)

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

let start_watching_output ~state ~(config:Server_config.job_configuration) ~termination execution = (
	let log_filename = log_filename ~state ~job_id:config.job.id in
	{ execution with output_watch =
		Some (watch_output
			~id:execution.job_id
			~termination
			~emit:state.emit
			log_filename
		);
	}
)

let show_output ~(emit_internal:emit_internal) ~state job show: unit R.std_result = (
	job.execution |> Option.map (fun execution ->
		if show then (
			match execution.termination with
				| Some termination -> (
					let config = job.job_configuration in
					execution.output_watch |> Option.may Lwt.cancel;
					emit_internal (Ok (Job_execution (
						job.external_job.state,
						start_watching_output ~state ~config ~termination execution
					)));
					Ok ()
				)
				| None ->
					Error (Sexp.Atom "Process is not yet initialized")
		) else (
			execution.output_watch |> Option.may Lwt.cancel;
			emit_internal (Ok (Job_execution (
				job.external_job.state,
				{ execution with output_watch = None }
			)));
			Ok ()
		)
	) |> Option.default (Ok ())
)

let init_job ~(emit_internal:emit_internal) ~state job : unit R.std_result = (
	(* populate termination. This must happen _after_ state is fully loaded,
	since it must be able to modify state *)
	job.execution |> Option.map (fun execution ->
		match execution.termination with
			| Some t -> Ok ()
			| None -> (
				let termination = match job.external_job.state with
					| Running pid -> watch_termination
						~state_dir:state.dir ~id:execution.job_id ~emit_internal pid
					| Not_running | Exited _ -> Lwt.return_unit
				in
				emit_internal
					(Ok (Job_execution
						(job.external_job.state,
						{ execution with termination = Some termination })
					));
				Ok ()
			)
	) |> Option.default (Error (Sexp.Atom "init_job: execution is not set"))
)

let start ~(emit_internal:emit_internal) ~state job : unit R.std_result = (
	(match job.external_job.state with
		| Running _ -> Error (Sexp.Atom "Job is already running")
		| Not_running | Exited _ -> Ok ()
	) |> R.bindr (fun () ->
		let config = job.job_configuration in
		let log_filename = log_filename ~state ~job_id:config.job.id in
		R.wrap open_writeable log_filename
			|> R.prefix_error ("Can't open job output file")
			|> R.bindr (fun log_file ->
			let argv = config.command in
			let result = create_detached_process (List.hd argv) (Array.of_list argv) devnull log_file
				|> R.map (fun pid ->
					let termination =
						watch_termination
							~state_dir:state.dir
							~id:config.job.id
							~emit_internal
							pid
					in

					emit_internal (Ok (
						Job_execution (Running pid, start_watching_output ~state ~config ~termination {
							job_id = config.job.id;
							termination = Some termination;
							output_watch = None;
						})
					))
				)
			in
			Unix.close log_file;
			result
		)
	)
)

let invoke : ((state -> state) -> unit) -> state -> Job.command -> unit =
	fun update_state state (id, cmd) -> (
		Log.info (fun m->m"invoke %a" Sexp.pp (sexp_of_command (id, cmd)));
		let emit_internal : emit_internal = fun event -> update_state (emit_and_update_internal ~id event) in
		let job = state.jobs |> StringMap.find_opt id in
		job |> Option.map (fun job ->
			match cmd with
				| Init -> init_job ~emit_internal ~state job
				| Start -> start ~emit_internal ~state job
				| Stop -> stop job
				| Refresh -> failwith "TODO: refresh"
				| Show_output show -> show_output ~emit_internal ~state job show
		) |> Option.default (Error (Sexp.Atom "No such job")) |> (function
			| Ok () -> ()
			| Error e -> state.emit (Error e)
		)
	)

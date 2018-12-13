open Sexplib.Std
module Log = (val (Logs.src_log (Logs.Src.create "job")))

type id = string [@@deriving sexp]

type job_identity = {
	id: string;
	name: string;
} [@@deriving sexp]

type process_state =
	| Running
	| Exited of int option
	[@@deriving sexp]

type job_state = {
	process_state: process_state;
	output: string list option;
} [@@deriving sexp, fields]

type job = {
	job: job_identity;
	state: job_state option;
} [@@deriving sexp]

type job_command =
	| Start
	| Stop
	| Refresh
	| Show_output of bool
	[@@deriving sexp]

type command = id * job_command
	[@@deriving sexp]

type job_event =
	| Process_state of process_state
	| Job_state of job_state option
	[@@deriving sexp]

type event = id * job_event
	[@@deriving sexp]

(* TODO: should this just be a flat list? *)
type state = {
	jobs: job list;
} [@@deriving sexp]

let init () = {
	jobs = [];
}

let modify_list_item modifier items =
	items |> List.map (fun item ->
		modifier item |> Option.default item
	)

(* let modify_list_item modifier items = *)
(* 	let rec apply acc_rev = function *)
(* 		| [] -> Ok (List.rev acc_rev) *)
(* 		| head::tail -> (match (modifier head) with *)
(* 			| None -> apply (head :: acc_rev) tail *)
(* 			| Some (Ok updated) -> Ok ((List.rev acc_rev) @ (updated :: tail)) *)
(* 			| Some (Error _ as err) -> err *)
(* 		) *)
(* 	in *)
(* 	apply [] items *)

let update state (id, event) =
	let modifier = match event with
		| Process_state process_state -> fun job ->
			let state = Some (match job.state with
				| Some state -> { state with process_state }
				| None ->
					Log.warn (fun m->m"saw Process_state update to a job without a current state");
					{ process_state; output = None }
			) in
			{ job with state }
		| Job_state state -> fun job -> { job with state }
	in
	{ jobs = state.jobs |> modify_list_item (fun job ->
		if job.job.id = id then Some (modifier job) else None
	) }

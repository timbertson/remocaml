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

type job = {
	job: job_identity;
	state: process_state option;
	output: string list option;
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
	| Output_line of string
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

let update state (id, event) =
	let modifier = match event with
		| Process_state state -> fun job -> { job with state = Some state }
		| Output_line line -> fun job -> { job with
			output = job.output |> Option.map (fun o -> o @ [line])
		}
	in
	{ jobs = state.jobs |> modify_list_item (fun job ->
		if job.job.id = id then Some (modifier job) else None
	) }

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


module Output = struct
	(* This could be `string list option`, but Sexp serializes that
	ambiguously - both None and Some [] end up as `()` *)
	type t =
		| Undefined
		| Output of string list
		[@@deriving sexp]

	let desc = function
		| Undefined -> "None"
		| Output _ -> "Some(_)"

	let map fn = function
		| Undefined -> Undefined
		| Output x -> Output (fn x)

	let fold dfl fn = function
		| Undefined -> dfl
		| Output x -> fn x
end

type job = {
	job: job_identity;
	state: process_state option;
	output: Output.t;
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
	| Output of Output.t
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

let update_job job = function
	| Process_state state -> { job with state = Some state }
	| Output output -> { job with output = output }
	| Output_line line ->
			Log.info(fun m->m"adding line (is currently %s)" (Output.desc job.output));
			{ job with output = job.output |> Output.map (fun o -> o @ [line])
	}

let update state (id, event) =
	{ jobs = state.jobs |> modify_list_item (fun job ->
		if job.job.id = id then Some (update_job job event) else None
	) }

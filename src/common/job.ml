open Sexplib.Std

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

type event =
	Job_running of bool
	[@@deriving sexp]

type state = {
	jobs: job list;
} [@@deriving sexp]

let init () = {
	jobs = [];
}

let update state = function
	| Job_running _ -> state

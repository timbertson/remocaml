open Sexplib.Std

type job_identity = {
	id: string;
	name: string;
} [@@deriving sexp]

type job_state = {
	running: bool;
	output: string list option;
} [@@deriving sexp, fields]

type job = {
	job: job_identity;
	state: job_state;
} [@@deriving sexp]

type command =
	Run
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

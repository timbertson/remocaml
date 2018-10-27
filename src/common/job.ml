open Sexplib.Std

type job = {
	id: string;
	name: string;
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

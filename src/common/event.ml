(* open Sexplib *)

type command =
	| Music_command of Music.command
	| Job_command of Job.command
	[@@deriving sexp]

type event =
	| Music_event of Music.event
	| Job_event of Job.event
	[@@deriving sexp]

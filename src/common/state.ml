(* open Sexplib.Std *)

type state = {
	music_state: Music.state;
	job_state: Job.state;
} [@@deriving sexp, fields]

let init () = {
	music_state = Music.init ();
	job_state = Job.init ();
}

let update : state -> Event.event -> state = fun state -> function
	| Music_event _ -> state
	| Job_event _ -> state

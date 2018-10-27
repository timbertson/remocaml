(* open Sexplib.Std *)

type state = {
	music_state: Music.state;
	job_state: Job.state;
} [@@deriving sexp, sexp_of]

let init () = {
	music_state = Music.init ();
	job_state = Job.init ();
}

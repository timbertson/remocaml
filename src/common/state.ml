(* open Sexplib.Std *)

type state = {
	music_state: Music.state;
	job_state: Job.state;
} [@@deriving sexp, fields]

let init () = {
	music_state = Music.init ();
	job_state = Job.init ();
}

let fake () = let base = init () in { base with
	music_state = {
		playing = true;
		volume = Some 0.75;
		artist = Some "Singy McGee";
		title = Some "I can't believe it's not singing";
	}
}

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
		volume = Some 0.75;
		track = Some {
			artist = "Singy McGee";
			title = "I can't believe it's not singing";
		};
	}
}

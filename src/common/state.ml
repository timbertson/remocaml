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
		track = {
			artist = Some "Singy McGee";
			title = Some "I can't believe it's not singing";
		};
		irank = Some Irank.[
			{ rating_name = "Rating"; rating_value = 3 };
			{ rating_name = "Pop"; rating_value = 5 };
			{ rating_name = "Nostalgia"; rating_value = 0 };
		];
	}
}

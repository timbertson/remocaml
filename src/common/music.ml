open Sexplib.Std

type track = {
	artist: string option;
	title: string option;
	url: string option;
	ratings: Irank.t option;
} [@@deriving sexp]

type state = {
	playing: bool;
	volume: float option;
	track: track;
} [@@deriving sexp]

type command =
	| Previous
	| PlayPause
	| Next
	| Louder
	| Quieter
	| Rate of (string * Irank.t)
	[@@deriving sexp]

type event =
	| Current_track of track
	| Current_volume of float option
	| Current_playing of bool
	[@@deriving sexp]

let unknown_track ~ratings () = {
	artist = None;
	title = None;
	url = None;
	ratings = ratings;
}

let init () = {
	playing = false;
	volume = None;
	track = unknown_track ~ratings:None ();
}

let update state = function
	| Current_track track -> { state with track }
	| Current_volume volume -> { state with volume }
	| Current_playing playing -> { state with playing }

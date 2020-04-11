open Sexplib.Std

type track = {
	artist: string option;
	title: string option;
} [@@deriving sexp]

type state = {
	playing: bool;
	volume: float option;
	irank: Irank.t option;
	track: track;
} [@@deriving sexp]

type command =
	| Previous
	| PlayPause
	| Next
	| Louder
	| Quieter
	| Rate of Irank.rating
	[@@deriving sexp]

type event =
	| Current_track of track
	| Current_volume of float option
	| Current_playing of bool
	[@@deriving sexp]

let unknown_track = {
	artist = None;
	title = None;
}

let init () = {
	playing = false;
	volume = None;
	track = unknown_track;
	irank = None;
}

let update state = function
	| Current_track track -> { state with track }
	| Current_volume volume -> { state with volume }
	| Current_playing playing -> { state with playing }

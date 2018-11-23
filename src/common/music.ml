open Sexplib.Std

type state = {
	playing: bool;
	volume: float option;
	artist: string option;
	title: string option;
} [@@deriving sexp]

type command =
	| Previous
	| PlayPause
	| Next
	| Louder
	| Quieter
	[@@deriving sexp]

type event =
	| Current_artist of string option
	| Current_title of string option
	| Current_volume of float option
	| Current_playing of bool
	[@@deriving sexp]

let init () = {
	playing = false;
	volume = None;
	artist = None;
	title = None;
}

let update state = function
	| Current_artist artist -> { state with artist }
	| Current_title title -> { state with title }
	| Current_volume volume -> { state with volume }
	| Current_playing playing -> { state with playing }

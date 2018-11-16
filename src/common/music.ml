open Sexplib.Std

type track = {
	artist: string;
	title: string;
} [@@deriving sexp]

type state = {
	volume: float option;
	track: track option;
} [@@deriving sexp]

type command =
	| Previous
	| Play
	| Pause
	| Next
	| Louder
	| Quieter
	[@@deriving sexp]

type event =
	Current_track of string option
	[@@deriving sexp]

let init () = {
	volume = None;
	track = None;
}

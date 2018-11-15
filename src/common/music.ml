open Sexplib.Std

type state = {
	volume: float option;
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
	volume = None
}

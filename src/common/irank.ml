open Sexplib.Std

type rating = {
	rating_name: string;
	rating_value: int;
} [@@deriving sexp]

type t = rating list [@@deriving sexp]

open Sexplib.Std

type rating = {
	rating_name: string;
	rating_value: int;
} [@@deriving sexp]

let find name ratings = List.find_opt (fun rating -> rating.rating_name = name) ratings

type t = rating list [@@deriving sexp]

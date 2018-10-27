include Rresult.R
open Sexplib
open Sexp
let sexp_of_result = function
	| Ok s -> List [Atom "Ok"; s]
	| Error s -> List [Atom "Error"; s]


let result_of_sexp = function
	| List [Atom "Ok"; s] -> Ok s
	| List [Atom "Error"; s] -> Error s
	| other -> Error (List [Atom "No_variant_match"; other])

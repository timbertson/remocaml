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

let catch_exn : 'a. (unit -> 'a) -> ('a, Sexp.t) result = fun f ->
	try Ok (f ())
	with err ->
		Error (Conv.sexp_of_exn err)

let wrap : 'a 'b. ('a -> 'b) -> 'a -> ('b, Sexp.t) result = fun f arg ->
	try Ok (f arg)
	with err ->
		Error (Conv.sexp_of_exn err)

let force : 'a. ('a, Sexp.t) result -> 'a = function
	| Ok result -> result
	| Error err -> failwith (Sexp.to_string err)

let bindr fn a = bind a fn

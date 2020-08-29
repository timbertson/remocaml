include Rresult.R
open Sexplib
open Sexp

type ('a,'b) result = ('a,'b) Stdlib.result (* alias for compatibility with sexp_conv *)

(* handy alias *)
type 'a std_result = ('a, Sexplib.Sexp.t) result

let sexp_of_error e = List [Atom "Error"; e]

let prefix_error str = reword_error (fun err ->
	Sexp.List [Sexp.Atom str; err]
)

let wrap : 'a 'b. ('a -> 'b) -> 'a -> ('b, Sexp.t) result = fun f arg ->
	try Ok (f arg)
	with err ->
		Error (Conv.sexp_of_exn err)

let sexp_of_result sexp_of__a = function
	| Ok a -> List [Atom "Ok"; (sexp_of__a a)]
	| Error e -> sexp_of_error e

let result_of_sexp a_of_sexp = function
	| List [Atom "Ok"; a] -> wrap a_of_sexp a
	| List [Atom "Error"; e] -> Error e
	| other -> Error (Conv.of_sexp_error "result_of_sexp" other)

let wrap_lwt : 'a 'b. ('a -> 'b Lwt.t) -> 'a -> ('b, Sexp.t) result Lwt.t = fun f arg ->
	try%lwt
		let%lwt ok = f arg in
		Lwt.return (Ok ok)
	with err ->
		Lwt.return (Error (Conv.sexp_of_exn err))

let map_lwt : 'a 'b 'c. ('a -> 'c Lwt.t) -> ('a, 'b) result -> ('c, 'b) result Lwt.t = fun fn arg ->
	match arg with
		| Ok x -> (fn x) |> Lwt.map (fun x -> Ok x)
		| Error _ as err -> Lwt.return err

let bind_lwt : 'a 'b 'e. ('a -> ('b, 'e) result Lwt.t) -> ('a, 'e) result -> ('b, 'e) result Lwt.t = fun fn arg ->
	match arg with
		| Ok x -> fn x
		| Error _ as err -> Lwt.return err

let force : 'a. ('a, Sexp.t) result -> 'a = function
	| Ok result -> result
	| Error err -> failwith (Sexp.to_string err)

let bindr fn a = bind a fn

let collect results = results |> List.fold_left (fun acc item ->
	match (acc, item) with
		| Ok acc, Ok item -> Ok (item :: acc)
		| Error _ as err, _ | Ok _, (Error _ as err) -> err
) (Ok []) |> map (List.rev)

let partition results =
	let ok = ref [] in
	let err = ref [] in
	results |> List.iter (function
		| Ok x -> ok := x :: !ok
		| Error x -> err := x :: !err
	);
	(List.rev !ok, List.rev !err)

open Remo_common
module R = Rresult_ext
open Sexplib
open Sexplib.Std
open Fieldslib
open Js_of_ocaml

module Log = (val (Logs.src_log (Logs.Src.create "ui_state")))

type t = {
	server_state: State.state;
	pending_ratings: (string * Irank.t) option;
	error: Sexp.t option;
	log: string option;
	state_override: State.state option; (* used for testing *)
} [@@deriving sexp, fields]

let init ~fake () = {
	server_state = State.init ();
	error = None;
	log = None;
	pending_ratings = None;
	state_override = if fake then Some (State.fake ()) else None;
}

let eq : t -> t -> bool = fun a b ->
	let use op = fun field ->
		op (Field.get field a) (Field.get field b)
	in
	Fields.for_all
		~server_state:(use (=))
		~pending_ratings:(use (=))
		~state_override:(use (=))
		~error:(use (=))
		~log:(use (=))

type event_result = (Event.event, Sexp.t) R.result
let sexp_of_event_result = R.sexp_of_result Event.sexp_of_event

type event =
	| Reconnect
	| Server_event of event_result
	| Pending_rating of (string * Irank.rating) option
	| Invoke of Event.command
	[@@deriving sexp_of]

let update state : event -> t = function
	| Server_event (Error err) -> { state with error = Some err }
	| Server_event (Ok evt) ->
		Log.info(fun m->m"applying server event: %s" (Sexp.to_string (Event.sexp_of_event evt)));
		let server_state = Event.update state.server_state evt in
		Log.info(fun m->m"updated; server state = %s" (Sexp.to_string (State.sexp_of_state server_state)));
		let pending_ratings_override = state.pending_ratings |> Option.bind (fun (pending_url, pending_ratings) ->
			match evt with
				(* on `Current_track` with pending ratings, clear any which now match the server state *)
				| Music_event (Current_track track) when track.url = Some pending_url ->
					let server_ratings = track.ratings |> Option.default [] in
					let pending_ratings = pending_ratings |> List.filter (fun pending -> not (List.mem pending server_ratings)) in
					Some (if pending_ratings = [] then None else (Some (pending_url, pending_ratings)))
				| _ -> None
		) in
		{ state with
			server_state = server_state;
			pending_ratings = pending_ratings_override |> Option.default state.pending_ratings
		}

	| Pending_rating None -> { state with pending_ratings = None }
	| Pending_rating (Some (url, new_rating)) ->
		let open Irank in
		let pending_ratings = match state.pending_ratings with
			| Some (pending_url, pending_ratings) when url = pending_url ->
					let remaining_ratings = pending_ratings |> List.filter (fun rating ->
						rating.rating_name <> new_rating.rating_name
					) in
					(url, new_rating :: remaining_ratings)
			| _ -> (url, [new_rating])
		in
		{ state with pending_ratings = Some pending_ratings }

	| Reconnect | Invoke _ -> state

let update state event = { (update state event) with log = match event with
	| Server_event _ -> Some (Sexp.to_string (sexp_of_event event))
	| Reconnect | Invoke _ | Pending_rating _ -> state.log
}

let command instance = fun _state -> function
	| Reconnect -> assert false
	| Server_event _ | Pending_rating _ -> None
	| Invoke command -> Some (
			let payload = (Sexp.to_string (Event.sexp_of_command command)) in
			Log.info (fun m->m"invoking command: %s" payload);
			let open Url in
			let path = "invoke" in
			let relative_url url = {
				hu_host = url.hu_host;
				hu_port = url.hu_port;
				hu_path = path_of_path_string path;
				hu_path_string = path;
				hu_arguments = [];
				hu_fragment = "";
			} in
			let dest = match Url.Current.get () with
				| Some (Http u) -> Http (relative_url u)
				| Some (Https u) -> Https (relative_url u)
				| _ -> failwith "invalid URL"
			in
			let%lwt response = Lwt_xmlHttpRequest.perform
				~contents:(`String payload)
				dest
			in
			Lwt.return (match response.code with
				| 200 -> ()
				| _ ->
						let error = try
							Sexp.of_string response.content
						with _ -> Sexp.Atom response.content
						in
						Vdoml.Ui.emit instance (Server_event (Error error))
			)
	)


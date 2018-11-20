open Sexplib
open Remo_common
module Log = (val (Logs.src_log (Logs.Src.create "connections")))

(* for consistency, we maintain a single event stream which
 * gets replicated to every open connection *)

type push_fn = (Event.event, Sexp.t) result option -> unit
type conn = Cohttp_lwt_unix.Server.conn

let conns : (conn * push_fn) list ref = ref []

let conn_closed closed =
	Log.info(fun m->m"Connection closed");
	let initial_cons = !conns |> List.length in
	conns := !conns |> List.filter (fun (conn, push) ->
		if (conn = closed) then (
			push None; true
		) else false
	);
	let final_cons = !conns |> List.length in
	Log.info(fun m->m"open conns is %d (was %d)" final_cons initial_cons)

let add_event_stream conn initial_events =
	let (stream, push) = Lwt_stream.create () in
	conns := (conn, push) :: !conns;
	initial_events |> List.iter (fun event -> push (Some event));
	stream

let broadcast event =
	!conns |> List.iter (fun (_conn, push) -> push (Some event))

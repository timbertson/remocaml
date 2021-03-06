open Remo_common
module R = Rresult_ext
module Log = (val (Logs.src_log (Logs.Src.create "connections")))

(* for consistency, we maintain a single event stream which
 * gets replicated to every open connection *)

type push_fn = Event.event R.std_result option -> unit
type conn = Cohttp_lwt_unix.Server.conn

let conns : (conn * push_fn) list ref = ref []

module Timeout = struct
	let ephemeral = ref None
	let set_ephemeral eph =
		ephemeral := eph

	let current : Lwt_timeout.t option ref = ref None
	let clear () =
		!current |> Option.may (fun prev ->
			Lwt_timeout.stop prev;
			current := None
		)

	let start () =
		!ephemeral |> Option.may (fun timeout ->
			Log.info (fun m->m"no remaining connections, timing out after %ds" timeout);
			current := Some (Lwt_timeout.create timeout (fun () -> exit 1))
		)
end

let conn_closed closed =
	Log.info(fun m->m"Connection closed");
	let initial_cons = !conns |> List.length in
	conns := !conns |> List.filter (fun (conn, push) ->
		if (conn = closed) then (
			push None; true
		) else false
	);
	let final_cons = !conns |> List.length in
	Log.info(fun m->m"open conns is %d (was %d)" final_cons initial_cons);
	if (final_cons = 0) then Timeout.start ()

let add_event_stream conn initial_events =
	let (stream, push) = Lwt_stream.create () in
	conns := (conn, push) :: !conns;
	Timeout.clear ();
	initial_events |> List.iter (fun event -> push (Some event));
	stream

let broadcast event =
	!conns |> List.iter (fun (_conn, push) -> push (Some (Ok event)))

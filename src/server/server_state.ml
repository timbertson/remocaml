open Remo_common
module List = List_ext
module R = Rresult_ext
open Astring
open Sexplib.Conv
module Log = (val (Logs.src_log (Logs.Src.create "server_state")))
module StringMap = Map.Make(String)

(* entire server state *)
type state = {
	server_config: Server_config.config;
	server_music_state: Server_music.state;
	server_jobs: Server_job.job list;
} [@@deriving sexp_of]

let ensure_config_dir config =
	let rec ensure_exists dir =
		try let _:Unix.stats = Unix.stat dir in ()
		with Unix.Unix_error (Unix.ENOENT, _, _) -> (
			ensure_exists (Filename.dirname dir);
			Unix.mkdir dir 0o700
		) in
	ensure_exists config.Server_config.state_directory;
	config.Server_config.state_directory

let load config =
	let state_dir = ensure_config_dir config in
	Server_job.load_state config state_dir |> R.map (fun server_jobs ->
		{
			server_config = config;
			server_music_state = Server_music.init ();
			server_jobs;
		}
	)

let client_state state =
	State.({
		music_state = state.server_music_state.music_state;
		job_state = {
			jobs = state.server_jobs
				|> List.map Server_job.running_client_job;
		};
	})

let invoke state : Event.command -> (unit, Sexplib.Sexp.t) result Lwt.t =
	let open Event in
	function
	| Music_command cmd ->
		Server_music.invoke state.server_music_state cmd
	| Job_command cmd ->
		Server_job.invoke state.server_jobs cmd

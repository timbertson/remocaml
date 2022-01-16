open Remo_common
module List = List_ext
module R = Rresult_ext
open Astring
module Log = (val (Logs.src_log (Logs.Src.create "server_state")))
module StringMap = Map.Make(String)

(* entire server state *)
type state = {
	server_config: Server_config.config;
	server_music_state: Server_music.state;
	server_jobs: Server_job.state;
} [@@deriving sexp_of]

let ensure_config_dir config =
	Unix_ext.mkdir_p config.Server_config.state_directory;
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

let invoke_job_command state_ref cmd =
	(* when we run a command, it needs to be able to autonomously update the job
	state upon termination *)
	let update_state : (Server_job.state -> Server_job.state) -> unit =
		fun update ->
			let state = !state_ref in
			state_ref := { state with server_jobs = update state.server_jobs }
	in
	Server_job.invoke update_state !state_ref.server_jobs cmd

let post_init state_ref =
	(* After loading the state ref, init all jobs. This sets up
	watchers, automatically updating the state ref on termination *)
	(!state_ref).server_jobs.jobs |> StringMap.iter (fun id job ->
		invoke_job_command state_ref (id, Init)
	)

let client_state state =
	State.({
		music_state = Music.init ();
		job_state = {
			jobs = state.server_jobs.jobs
				|> StringMap.bindings
				|> List.map snd
				|> List.sort (fun a b ->
					let open Server_job in
					let open Server_config in
					compare a.job_configuration.sort_order b.job_configuration.sort_order
				) |> List.map Server_job.external_of_job;
		};
	})
	
let invoke state_ref : Event.command -> Event.event list R.std_result Lwt.t = fun command ->
	let state = !state_ref in
	let open Event in
	match command with
	| Music_command cmd ->
		Server_music.invoke state.server_music_state cmd |> Lwt.map (R.map Option.to_list)
	| Job_command cmd ->
		invoke_job_command state_ref cmd;
		Lwt.return (Ok [])

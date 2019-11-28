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

let client_state state =
	State.({
		music_state = state.server_music_state.music_state;
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

let invoke state_ref : Event.command -> Event.event list R.std_result Lwt.t =
	let open Event in
	let state = !state_ref in
	function
	| Music_command cmd ->
		Server_music.invoke state.server_music_state cmd |> Lwt.map (R.map Option.to_list)
	| Job_command cmd ->
			Lwt.return (Server_job.invoke state.server_jobs cmd |> R.map (fun (job_state, events) ->
			state_ref := { state with server_jobs = { state.server_jobs with jobs = job_state }};
			events
		))

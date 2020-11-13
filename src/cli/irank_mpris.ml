open Remo_server
open Remo_common
open Util
open Server_music
open Sexplib

let rating_width = lazy (
	let names = Lazy.force Server_irank.rating_names in
	names |> List.map String.length |> List.fold_left max 0
)

let rec repeat ch len =
	if len <= 0 then () else (
		print_char ch; repeat ch (len - 1)
	)

let path_of_track t = t.Music.url |> Option.bind (fun url ->
	let url = Uri.of_string url in
	match Uri.scheme url with
		| Some "file" -> Some (url |> Uri.path |> Uri.pct_decode)
		| _ -> None
)

let filename_of_track t = path_of_track t |> Option.map (Filename.remove_extension % Filename.basename)

let render state =
	Logs.debug (fun m->m"rendering...");
	let open Music in
	let open Irank in
	let track = state.track in
	match path_of_track track with
		| None -> print_endline "No current track"
		| Some path ->
			let filename = path |> Filename.basename |> Filename.remove_extension in
			print_endline filename;
			track.ratings |> Option.may (List.iter (fun rating ->
				repeat ' ' ((Lazy.force rating_width) - (String.length rating.rating_name));
				print_string rating.rating_name;
				print_char ' ';
				repeat '*' rating.rating_value;
				repeat ' ' (Irank.stars - rating.rating_value);
				print_endline ""
			))

type input =
	| Music_event of Music.event
	| Edit
	| Discard
	| Delete
	| Keep
	[@@deriving sexp]

let run_cmd cmd =
	let open Unix in
	let failed desc i = Error Sexp.(List [
		List [Atom "cmd"; List (List.map (fun a -> Atom a) cmd)];
		List [Atom desc; Atom (string_of_int i)]
	]) in
	Logs.debug (fun m->m "+ %s" (String.concat " " cmd));
	Lwt_process.exec (cmd |> List.hd, cmd |> Array.of_list) |> Lwt.map (function
		| WEXITED 0 -> Ok ()
		| WEXITED nonzero -> failed "exit-status" nonzero
		| WSIGNALED s -> failed "signal" s
		| WSTOPPED s -> failed "signal" s
	)

let run_irank_cmd track action =
	match path_of_track track with
		| None -> Lwt.return (Error (Sexp.Atom "No current track"))
		| Some path -> run_cmd ["irank"; action; path]

let noop_schedule_nag ~(encouraged: string list) state =
	Lwt.return_unit

let schedule_nag ~(encouraged: string list) state =
	let open Music in
	let sleep_time = 90.0 in
	Log.debug (fun m->m "Scheduling nag for %s (in %0.0fs)" (Option.to_string Fun.id (filename_of_track !state.track)) sleep_time);
	let%lwt () = Lwt_unix.sleep sleep_time in
	let filename = filename_of_track !state.track in
	let ratings = !state.track.ratings |> Option.default [] in
	Log.debug (fun m->m "Evaluating nag conditions for %s: encouraged = [%s], ratings = %s"
		(Option.to_string Fun.id filename)
		(String.concat ", " encouraged)
		(Irank.sexp_of_t ratings |>  Sexp.to_string)
	);
	let%lwt () = match filename with
		| Some(filename) -> (
			let unrated key = (Irank.find key ratings |> Option.map (fun r -> r.Irank.rating_value) |> Option.default 0) = 0 in
			let needs_encouragement = encouraged |> List.exists unrated in
			if needs_encouragement then (
				Log.debug (fun m->m "Triggering notification");
				let%lwt result = run_cmd [
					"notify-send";
					"--hint"; "int:transient:1";
					"Time to rate?"; filename;
				] in
				let () = match result with
					| Ok(_) -> ()
					| Error(e) -> Log.debug(fun m->m "Notification failed: %s" (Sexp.to_string e))
				in
				Lwt.return_unit
			) else Lwt.return_unit
		)
		| _ -> Lwt.return_unit
	in Lwt.return_unit

let run () =
	Server_logs.init ();
	let config = Server_config.(load ~state_dir config_path) |> R.force in
	let music_config = config.music in
	let%lwt bus = OBus_bus.session () in
	let%lwt player = first_mpris_service music_config bus in
	let%lwt player = player |> Option.fold (Lwt.fail_with "No player found") Lwt.return in
	let state = ref (Music.init ()) in
	let music_events = player_events ~default_ratings:(Some (Server_irank.blank_ratings ())) player
		|> Lwt_stream.map (R.bindr (function
			| Event.Music_event event -> Ok (Music_event event)
			| _ -> Error (Sexp.Atom "Got a non-music event...")
			))
	in


	(* We can't use Lwt_stream of inlut lines here, because it would
	   keep reading in the background, stealing input from e.g. irank-edit *)
	let get_command () = Lwt_io.(read_line stdin) |> Lwt.map (function
		| "" -> Ok Edit
		| "y" -> Ok Discard
		| "d" -> Ok Delete
		| "k" -> Ok Keep
		| other -> Error (Sexp.Atom ("Unknown input: " ^ other))
	) in
	let pending_nag = ref None in
	let schedule_nag = if Unix_ext.getenv_opt "nag" = Some("1") then schedule_nag else noop_schedule_nag in
	let get_music_event () = music_events |> Lwt_stream.next in
	let rec loop () = Lwt.bind (Lwt.pick [get_command (); get_music_event () ]) (fun event ->
		Logs.debug (fun m->m "Applying event: %s" (Sexp.to_string (R.sexp_of_result sexp_of_input event)));
		let%lwt result = match event with
			| Ok (Music_event event) -> (
				let prev_state = !state in
				state := Music.update prev_state event;
				Log.debug(fun m->m "Track: %s -> %s"
					(Option.to_string Fun.id (prev_state.track.url))
					(Option.to_string Fun.id (!state.track.url))
				);

				if !state.track.Music.url <> prev_state.track.Music.url then (
					!pending_nag |> Option.may Lwt.cancel;
					pending_nag := !state.track.Music.url |> Option.map(fun url ->
						(* URL changed *)
						schedule_nag ~encouraged:config.music.encourage_rating state
					)
				);
				Lwt.return (Ok ())
			)
			| Ok (Edit) -> run_irank_cmd (!state).track "edit"
			| Ok (Delete) -> run_irank_cmd (!state).track "delete"
			| Ok (Discard) -> run_irank_cmd (!state).track "discard"
			| Ok (Keep) -> run_irank_cmd (!state).track "keep"
			| (Error _) as err -> Lwt.return err
		in
		let%lwt _ = match Logs.level () with
			| Some Logs.Debug -> Lwt.return_unit
			| _ -> Lwt_process.exec ("clear", [| "clear" |]) |> Lwt.map ignore
		in
		render !state;
		result |> Result.iter_error (fun e ->
			print_endline "------";
			print_endline ("Error: " ^ (Sexp.to_string e))
		);
		loop ()
	) in
	loop ()

let () = try
	Lwt_main.run (run ())
with End_of_file -> ()

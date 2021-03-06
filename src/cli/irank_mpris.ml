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

let run_irank_cmd track action =
	let open Unix in
	let irank = "irank" in
	let failed desc i = Error Sexp.(List [
		List [Atom "cmd"; List [Atom irank; Atom action]];
		List [Atom desc; Atom (string_of_int i)]
	]) in
	match path_of_track track with
		| None -> Lwt.return (Error (Sexp.Atom "No current track"))
		| Some path ->
			Logs.debug (fun m->m "+ %s %s %s" irank action path);
			Lwt_process.exec (irank, [| irank; action; path |]) |> Lwt.map (function
			| WEXITED 0 -> Ok ()
			| WEXITED nonzero -> failed "exit-status" nonzero
			| WSIGNALED s -> failed "signal" s
			| WSTOPPED s -> failed "signal" s
		)
	
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
	let get_music_event () = music_events |> Lwt_stream.next in
	let rec loop () = Lwt.bind (Lwt.pick [get_command (); get_music_event () ]) (fun event ->
		Logs.debug (fun m->m "Applying event: %s" (Sexp.to_string (R.sexp_of_result sexp_of_input event)));
		let%lwt result = match event with
			| Ok (Music_event event) ->
				state := Music.update !state event;
				Lwt.return (Ok ())
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

let () = Lwt_main.run (run ())

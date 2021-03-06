include Unix
let rec mkdir_p path =
	try
		mkdir path 0o700
	with
		| Unix_error (EEXIST, _, _) -> ()
		| Unix_error (ENOENT, _, _) ->
			mkdir_p (Filename.dirname path);
			mkdir_p path

let ensure_unlinked path =
	try
		unlink path
	with Unix_error (ENOENT, _, _) -> ()
	
let getenv_opt key =
	try Some (Unix.getenv key) with Not_found -> None

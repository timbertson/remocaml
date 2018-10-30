type command =
	| Music_command of Music.command
	| Job_command of Job.command
	[@@deriving sexp]

type event =
	| Reset_state of State.state
	| Music_event of Music.event
	| Job_event of Job.event
	[@@deriving sexp]

let update : State.state -> event -> State.state = fun state -> function
	| Music_event _ -> state
	| Job_event _ -> state
	| Reset_state s -> s

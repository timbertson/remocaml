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
	| Music_event e -> { state with music_state = Music.update state.music_state e }
	| Job_event e -> { state with job_state = Job.update state.job_state e }
	| Reset_state s -> s

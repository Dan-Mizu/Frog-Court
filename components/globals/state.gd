extends Node

# state
var broadcaster_user: TwitchUser
var round_data: RoundData = RoundData.new()
var selected_accusation: ResponseAccusation

#region Twitch Connection
func connect_to_twitch() -> bool:
	# Start the setup process (handles authentication)
	# Returns true on success, false on failure (e.g., login run in timeout)
	var setup_successful: bool = await Twitch.setup()

	if setup_successful:
		# fetch broadcasters twitch user data
		await _get_broadcaster_info()

		# connect to twitch events
		_connect_to_twitch_events()

		# register the twitch chat commands used by this game
		_register_commands()

	return setup_successful

func _get_broadcaster_info() -> void:
	# get connected twitch user
	broadcaster_user = await Twitch.get_current_user()

	if broadcaster_user:
		# DEBUG
		print("Authenticated as: %s (ID: %s)" % [broadcaster_user.display_name, broadcaster_user.id])

	else:
		# DEBUG
		printerr("Could not get current user info.")
#endregion

#region Events
func _connect_to_twitch_events() -> void:
	# connect to event sub
	await Twitch.wait_for_eventsub_connection()

	# listen to chat message event
	await Twitch.subscribe_event(TwitchEventsubDefinition.CHANNEL_CHAT_MESSAGE, {
		&"broadcaster_user_id": broadcaster_user.id,
		&"user_id": broadcaster_user.id
	})
	if not Twitch.eventsub.event_received.is_connected(_on_chat_message): Twitch.eventsub.event_received.connect(_on_chat_message)

#endregion

#region Commands
var commands: Dictionary = {
	"accuse": { "callback": _on_accuse_command, "takes_message": true, "takes_target_user_arg": true, "phase": Phase.ACCUSATION },
	"yea": { "callback": _on_yea_command, "phase": Phase.DELIBERATION },
	"nay": { "callback": _on_nay_command, "phase": Phase.DELIBERATION },
}

func _register_commands() -> void:
	# register each command
	for command_name in commands.keys():
		# get command data
		var command_data: Dictionary = commands[command_name]

		# get the chat message if set in command config
		var args_length: Dictionary[String, int] = {}
		if command_data.get("takes_message", false): args_length = { "args_min": 1, "args_max": -1 }

		# make twitcher listen for this command
		Twitch.add_command(
			command_name,
			_receive_command,
			args_length.get("args_min", 0),
			args_length.get("args_max", 0)
		)

func _receive_command(_from_username: String, info: TwitchCommandInfo, args: PackedStringArray) -> void:
	# get command identifier
	var command_name: String = info.command.command

	# command doesnt exist
	if not commands.has(command_name): return

	# get command data
	var command_data: Dictionary = commands[command_name]

	# incorrect phase
	if command_data.has("phase") and command_data["phase"] != round_data.phase: return

	# invalid command
	if command_data.get("callback", null) is not Callable: return

	# get command's method
	var command: Callable = command_data["callback"] as Callable

	# get chat message
	var chat_message: TwitchChatMessage = info.original_message as TwitchChatMessage

	# init response
	var new_response: Response

	# accusation response 
	if command_data.get("takes_target_user_arg", false):
		# doesn't have enough args
		if args.size() < 2: return

		# accused name is first arg
		var accused_name: String = args[0].strip_edges()
		if accused_name.begins_with("@"): accused_name = accused_name.substr(1)
		if accused_name.ends_with(","): accused_name = accused_name.substr(0, accused_name.length() - 1)

		# get claim
		var claim: String = " ".join(args.slice(1, args.size())).strip_edges()

		# submit response
		new_response = ResponseAccusation.new(
			round_data.phase,
			chat_message.chatter_user_id,
			chat_message.chatter_user_name,
			claim,
			accused_name
		)

	# message response
	elif command_data.get("takes_message", false): new_response = ResponseMessage.new(round_data.phase, chat_message.chatter_user_id, chat_message.chatter_user_name, " ".join(args))

	# default response
	else: new_response = Response.new(round_data.phase, chat_message.chatter_user_id, chat_message.chatter_user_name)

	# run command
	command.call(new_response)

func _on_accuse_command(response: ResponseAccusation) -> void:
	# add new accusation 
	round_data.accusations.add_response(response)

	## DEBUG
	#print("%s claims against %s: %s" % response. response.user_display_name)

func _on_yea_command(response: Response) -> void:
	# store response
	round_data.jury_votes.vote_yea(response)

	## DEBUG
	#print("%s agrees!" % response.user_display_name)

func _on_nay_command(response: Response) -> void:
	# store response
	round_data.jury_votes.vote_nay(response)

	## DEBUG
	#print("%s disagrees!" % response.user_display_name)

func _on_chat_message(event: TwitchEventsub.Event) -> void:
	# not defense phase
	if round_data.phase != Phase.DEFENSE: return

	# get chat message data
	var chat_message: TwitchChatMessage = TwitchChatMessage.from_json(event.data)

	# not the defendant
	if chat_message.chatter_user_id != round_data.accused_user_id: return

	# get message text
	var text: String = chat_message.message.text.strip_edges()
	if text.is_empty(): return

	# defendant sent chat message
	#var defense = ResponseMessage.new(round_data.phase, chat_message.chatter_user_id, chat_message.chatter_user_name, text)
	#round_data.defenses.add_response(defense)
#endregion

#region Rounds and Phases
# all phases
enum Phase {
	NONE,
	ACCUSATION,
	DEFENSE,
	DELIBERATION
}

class RoundData extends RefCounted:
	# signals
	signal phase_changed(new_phase: Phase)

	# state
	var phase: Phase = Phase.NONE:
		set(value):
			# new phase
			if phase != value:
				# emit phase change signal
				phase_changed.emit(value)

				# store
				phase = value
	var selected_accusation: ResponseAccusation = null
	var accuser_user_id: String = ""
	var accused_user_id: String = ""

	# responses
	var accusations: Responses = Responses.new().init([filter_no_duplicates, make_filter_user_limit(2)])
	var jury_votes: Votes = Votes.new().init([filter_one_vote])

	# blocks duplicates across all users
	func filter_no_duplicates(response: Response, container: Responses) -> bool:
		if response is ResponseMessage:
			var new_msg = response.message.strip_edges().to_lower()
			for r in container.responses:
				if r is ResponseMessage and r.message.strip_edges().to_lower() == new_msg:
					## DEBUG
					#print("Duplicate ignored: %s" % new_msg)
					return false
		return true

	# limits how many responses a single user can add
	func make_filter_user_limit(limit: int) -> Callable:
		return func(response: Response, container: Responses) -> bool:
			var count := 0
			for r in container.responses:
				if r.user_id == response.user_id:
					count += 1
			if count >= limit:
				## DEBUG
				#print("%s exceeded limit (%d)" % [response.user_display_name, limit])
				return false
			return true

	# allow only one vote total per user
	func filter_one_vote(response: Response, container: Responses) -> bool:
		for r in container.responses:
			if r.user_id == response.user_id:
				## DEBUG
				#print("%s already voted!" % response.user_display_name)
				return false
		return true

class Filtered extends RefCounted:
	# properties
	var filters: Array[Callable] = []

	# initialize properties
	func init(_filters: Array[Callable] = []) -> Filtered:
		filters = _filters
		return self

class Responses extends Filtered:
	# signals
	signal response_added(response: Response)

	# state
	var responses: Array[Response] = []

	func add_response(response: Response) -> void:
		# check filters
		for filter in filters: if not filter.call(response, self): return

		# store
		responses.append(response)

		# emit signal that a response was added
		response_added.emit(response)

class Votes extends Filtered:
	# enums
	enum Outcome {
		YEA,
		NAY,
		TIE
	}

	# signals
	signal yea_voted(response: Response)
	signal nay_voted(response: Response)

	# state
	var yea_count: int = 0
	var nay_count: int = 0
	var total_count: int:
		get: return yea_count + nay_count
	var yea_responses: Array[Response] = []
	var nay_responses: Array[Response] = []

	func vote_yea(response: Response) -> void: 
		# check filters
		for filter in filters: if not filter.call(response, self): return

		# store
		yea_responses.push_back(response)
		yea_count += 1

		# event
		yea_voted.emit(response)

	func vote_nay(response: Response) -> void:
		# check filters
		for filter in filters: if not filter.call(response, self): return

		# store
		nay_responses.push_back(response)
		nay_count += 1

		# event
		nay_voted.emit(response)

	func get_outcome() -> Outcome:
		# yays have it
		if yea_count > nay_count: return Outcome.YEA

		# nays have it
		elif nay_count > yea_count: return Outcome.NAY

		# its a tie
		return Outcome.TIE

class Response extends RefCounted:
	# state
	var phase: Phase
	var user_id: String
	var user_display_name: String

	# setup
	func _init(_phase: Phase = Phase.NONE, _user_id: String = "", _user_display_name: String = "") -> void:
		phase = _phase
		user_id = _user_id
		user_display_name = _user_display_name

class ResponseMessage extends Response:
	# the difference between this class and Response is that this one additionally contains a message
	var message: String

	# setup
	func _init(_phase: Phase = Phase.NONE, _user_id: String = "", _user_display_name: String = "", _message: String = "") -> void:
		super._init(_phase, _user_id, _user_display_name)
		message = _message

class ResponseAccusation extends ResponseMessage:
	# state
	var accused_name: String
	var accuser_id: String

	# setup
	func _init(_phase: Phase = Phase.NONE, _user_id: String = "", _user_display_name: String = "", _message: String = "", _accused_name: String = "", ) -> void:
		super._init(_phase, _user_id, _user_display_name, _message)
		accused_name = _accused_name
#endregion

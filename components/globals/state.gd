extends Node

# state
var broadcaster_user: TwitchUser

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

#region Events
func _connect_to_twitch_events() -> void:
	# connect to event sub
	await Twitch.wait_for_eventsub_connection()

	# listen to chat message event
	await Twitch.subscribe_event(TwitchEventsubDefinition.CHANNEL_CHAT_MESSAGE, {
		&"broadcaster_user_id": broadcaster_user.id,
		&"user_id": broadcaster_user.id
	})
	#Twitch.eventsub.event_received.connect(_on_chat_message)

	## DEBUG sends twitch chat message
	#Twitch.chat("/me event connected")

#func _on_chat_message(event: TwitchEventsub.Event) -> void:
	## get chat message data
	#var chat_message: TwitchChatMessage = TwitchChatMessage.from_json(event.data)

	## get message text
	#var text: String = chat_message.message.text.strip_edges()

	## no message
	#if text.is_empty(): return

	## split command and args
	#var parts: PackedStringArray = text.split(" ", false, 1)
	#var cmd: String = parts[0].to_lower()
	#var args: String = parts[1] if parts.size() > 1 else ""

	## check if command found
	#if commands.has(cmd):
		#var handler: Callable = commands[cmd]

		## run command
		#handler.call(chat_message, args)
#endregion

#region Commands
var commands: Dictionary = {
	"claim": { "callback": _on_claim_command, "args_min": 1, "args_max": -1 },
	"defend": { "callback": _on_defend_command, "args_min": 1, "args_max": -1 },
	"agree": { "callback": _on_agree_command, "args_min": 0, "args_max": 0 },
	"disagree": { "callback": _on_disagree_command, "args_min": 0, "args_max": 0 },
	"object": { "callback": _on_object_command, "args_min": 1, "args_max": -1 },
}

func _register_commands() -> void:
	# register each command
	for command_name in commands.keys():
		# get command data
		var command_data: Dictionary = commands[command_name]

		# make twitcher listen for this command
		Twitch.add_command(
			command_name,
			_receive_command,
			command_data.get("args_min", 0),
			command_data.get("args_max", -1)
		)

func _receive_command(_from_username: String, info: TwitchCommandInfo, args: PackedStringArray) -> void:
	# get command identifier
	var command_name: String = info.command.command

	# invalid command
	if not commands.has(command_name) \
	or not commands[command_name].has("callback") \
	or not commands[command_name]["callback"] is Callable: return

	# get command's method
	var command: Callable = commands[command_name]["callback"] as Callable

	# get chat message
	var chat_message: TwitchChatMessage = info.original_message as TwitchChatMessage

	# get (properly formatted) name and message
	var display_name: String = chat_message.chatter_user_name
	var message: String = " ".join(args)

	# run command
	command.call(display_name, message)

func _on_claim_command(display_name: String, message: String) -> void:
	# DEBUG
	print("%s claims: %s" % [display_name, message])

func _on_defend_command(display_name: String, message: String) -> void:
	# DEBUG
	print("%s defends: %s" % [display_name, message])

func _on_agree_command(display_name: String, _message: String) -> void:
	# DEBUG
	print("%s agrees!" % display_name)

func _on_disagree_command(display_name: String, _message: String) -> void:
	# DEBUG
	print("%s disagrees!" % display_name)

func _on_object_command(display_name: String, message: String) -> void:
	# DEBUG
	print("%s objects: %s" % [display_name, message])
#endregion

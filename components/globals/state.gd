extends Node

# state
var broadcaster_user: TwitchUser

func connect_to_twitch() -> bool:
	# Start the setup process (handles authentication)
	# Returns true on success, false on failure (e.g., login run in timeout)
	var setup_successful: bool = await Twitch.setup()

	# connect to twitch events
	if setup_successful: 
		await _get_broadcaster_info()
		_connect_to_twitch_events()

	return setup_successful

func _connect_to_twitch_events() -> void:
	# connect to event sub
	await Twitch.wait_for_eventsub_connection()

	# listen to chat message event
	await Twitch.subscribe_event(TwitchEventsubDefinition.CHANNEL_CHAT_MESSAGE, {
		&"broadcaster_user_id": broadcaster_user.id,
		&"user_id": broadcaster_user.id
	})
	Twitch.eventsub.event_received.connect(_on_chat_message)

	# DEBUG sends twitch chat message
	#Twitch.chat("event connected")

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
func _on_chat_message(event: TwitchEventsub.Event) -> void:
	# get chat message data
	var chat_message: TwitchChatMessage = TwitchChatMessage.from_json(event.data)

	# get message text
	var text: String = chat_message.message.text.strip_edges()

	# no message
	if text.is_empty(): return

	# split command and args
	var parts: PackedStringArray = text.split(" ", false, 1)
	var cmd: String = parts[0].to_lower()
	var args: String = parts[1] if parts.size() > 1 else ""

	# check if command found
	if commands.has(cmd):
		var handler: Callable = commands[cmd]

		# run command
		handler.call(chat_message, args)
#endregion

#region Commands
var commands: Dictionary[String, Callable] = {
		"!claim": _run_command_claim,
		"!defend": _run_command_defend,
		"!agree": _run_command_agree,
		"!disagree": _run_command_disagree,
		"!object": _run_command_object,
	}

func _run_command_claim(msg: TwitchChatMessage, args: String) -> void:
	print("%s claims: %s" % [msg.chatter_user_name, args])
func _run_command_defend(msg: TwitchChatMessage, args: String) -> void:
	print("%s defends: %s" % [msg.chatter_user_name, args])
func _run_command_agree(msg: TwitchChatMessage, _args: String) -> void:
	print("%s agrees!" % msg.chatter_user_name)
func _run_command_disagree(msg: TwitchChatMessage, _args: String) -> void:
	print("%s disagrees!" % msg.chatter_user_name)
func _run_command_object(msg: TwitchChatMessage, args: String) -> void:
	print("%s objects: %s" % [msg.chatter_user_name, args])
#endregion

extends CanvasLayer

# references
@onready var twitch_connect_button: Button = %TwitchConnectButton
@onready var loading_spinner: TextureProgressBar = %LoadingSpinner
@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _on_connect_to_twitch_pressed() -> void:
	# hide button
	twitch_connect_button.visible = false

	# show loading spinner
	loading_spinner.visible = true

	# Start the setup process (handles authentication)
	# Returns true on success, false on failure (e.g., login run in timeout)
	var setup_successful: bool = await Twitch.setup()

	if setup_successful:
		# DEBUG
		print("Twitch Service successfully set up and authenticated!")

		# get connected users info
		await get_self_info()

	else:
		# DEBUG
		printerr("Twitch Service setup failed. Check authentication.")

func get_self_info():
	# get connected twitch user
	var current_user: TwitchUser = await Twitch.get_current_user()

	if current_user:
		# DEBUG
		print("Authenticated as: %s (ID: %s)" % [current_user.display_name, current_user.id])

		# hide twitch modal
		animation_player.play("hide")

	else:
		# DEBUG
		printerr("Could not get current user info.")

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

	# connect to twitch
	var setup_successful: bool = await State.connect_to_twitch()

	# successfully connected
	if setup_successful and State.broadcaster_user:
		# hide twitch modal
		animation_player.play("hide")

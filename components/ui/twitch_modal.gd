extends CanvasLayer

signal modal_finished

# references
@onready var twitch_connect_button: Button = %TwitchConnectButton
@onready var loading_spinner: TextureProgressBar = %LoadingSpinner
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@export var click_sfx: AudioStream

func _on_connect_to_twitch_pressed() -> void:
	# click SFX
	SoundManager.play_sound(click_sfx, "UI")

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

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	# finished hiding
	if anim_name == "hide": modal_finished.emit()

extends Node3D

@export_category("References")
@export var message_balloon: PackedScene
@export var intro_dialogue: DialogueResource
@export_group("SFX")
@export var crowd_murmur_sfx: AudioStream
@export var gavel_sfx: AudioStream

# internal
var crowd_murmur_sfx_player: AudioStreamPlayer

func _ready() -> void:
	# play crowd murmur SFX
	crowd_murmur_sfx_player = SoundManager.play_ambient_sound(crowd_murmur_sfx.duplicate(), 3.0)

func _start_game() -> void:
	DialogueManager.show_dialogue_balloon(intro_dialogue, "start")

func _on_twitch_modal_finished() -> void:
	# start the game once fully authenticated with twitch and the modal is fully hidden
	_start_game()

func play_and_wait_sound(sound: AudioStream) -> void:
	await play_sound(sound).finished

func play_sound(sound: AudioStream) -> AudioStreamPlayer:
	return SoundManager.play_sound(sound)

func fade_out_sound(player: AudioStreamPlayer, duration: float = 1.0) -> void:
	SoundManager.sound_effects.fade_volume(player, player.volume_db, -80.0, duration)

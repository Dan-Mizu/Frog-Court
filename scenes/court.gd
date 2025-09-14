extends Node3D

@export_group("SFX")
@export var crowd_murmur_sfx: AudioStream

func _ready() -> void:
	# play crowd murmur SFX
	SoundManager.play_ambient_sound(crowd_murmur_sfx.duplicate(), 3.0)

func _start_game() -> void:
	pass

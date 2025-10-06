extends Node3D
class_name ChatterCharacter

# enums
enum Anim {
	IDLE,
	DIE,
	SAD,
	WALK,
	RUN,
	HOP,
	JUMP,
	RUN_JUMP
}

# signals
signal finished_animation(finished_anim: Anim)

# references
@export_category("References")
@export var animation_player: AnimationPlayer

func play_anim(anim: Anim) -> void:
	# convert provided enum to the proper animation name and play it
	animation_player.play(Utility.enum_to_string(anim, Anim))

func _on_animation_finished(anim_name: StringName) -> void:
	# get finished animation
	var finished_anim: Anim = Utility.string_to_enum(anim_name, Anim) as Anim

	# go back to idling
	if finished_anim != Anim.IDLE: play_anim(Anim.IDLE)

	# send finished animation event
	finished_animation.emit(finished_anim)

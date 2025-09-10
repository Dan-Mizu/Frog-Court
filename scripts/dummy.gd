class_name Enemy
extends CharacterBody3D

# references
@export_category("References")
@onready var animation_player: AnimationPlayer = %AnimationPlayer

func on_target_lock_start() -> void:
	pass

func on_target_lock_end() -> void:
	pass

func _on_hurtbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player Hitbox"):
		animation_player.stop()
		animation_player.play("dummy_anims/Hit")

func _on_animation_player_animation_finished(_anim_name: String) -> void:
	# revert to idle
	animation_player.play("dummy_anims/Idle")

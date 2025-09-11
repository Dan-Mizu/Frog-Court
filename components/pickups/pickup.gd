class_name Pickup
extends Node3D

# references
@export_category("References")
@onready var model: Node3D = %Model
@onready var animation_player: AnimationPlayer = %AnimationPlayer

# properties
@export_category("Properties")
@export var item_id: String
@export_group("SFX")
@export var pickup_sfx: AudioStream

# options
@export_category("Options")
@export var inventory_view: bool = false

# internal
var picked_up: bool = false

func _ready() -> void:
	if inventory_view:
		model.position.y = 0
		animation_player.play("pickup_anims/Inventory Spin")

	else:
		animation_player.play("pickup_anims/Ground Spin")

func _on_collision(body: Node3D) -> void:
	# player interacted for the first time
	if body is Player and picked_up == false:
		# get player
		var player: Player = body

		# marked as picked up
		picked_up = true

		# play pickup anim
		animation_player.play("pickup_anims/Pickup")

		# play pickup sound
		SoundManager.play_sound(pickup_sfx.duplicate()) # duplicate to prevent sound getting cut-off

		# give player item
		player.on_pickup(item_id)

func _on_pickup_anim_end() -> void:
	# delete node after pickup
	queue_free()

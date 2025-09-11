extends Sprite2D

# references
@export_category("References")
@export var action_name: String
@export var pressed_texture: Texture2D
@onready var initial_texture: Texture2D = texture

# called on every input
func _input(event: InputEvent):
	# apply pressed texture
	if event.is_action_pressed(action_name):
		texture = pressed_texture

	# reset to initial texture
	elif event.is_action_released(action_name):
		texture = initial_texture

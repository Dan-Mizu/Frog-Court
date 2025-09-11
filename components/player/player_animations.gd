class_name PlayerAnimController
extends AnimationTree

# constants
var MOVEMENT_ANIM_SPEED: float = 5.0
var ACTION_BLEND_VALUE: float = 0.75
var ACTION_BLEND_SPEED: float = 3.0

@export_category("References")
@onready var _general_movement_path: StringName = "parameters/General Movement/blend_position"
@onready var _targeting_movement_path: StringName = "parameters/Targeting Movement/blend_position"
@onready var _action_blend_path: StringName = "parameters/Upper Body Action/blend_amount"
@onready var _state_movement_path: StringName = "parameters/Movement/transition_request" 
@onready var _state_action_path: StringName = "parameters/Action/transition_request"
@onready var _state_output_path: StringName = "parameters/Output/transition_request"

@export_category("Parameters")
@export var vertical_movement: float = 0.0
@export var horizontal_movement: float = 0.0

# internal
var _action_blend_target: float = 0.0

# apply movement to blend spaces
func _physics_process(delta: float) -> void:
	# apply general movement blend value
	set(_general_movement_path, lerp(get(_general_movement_path), vertical_movement, delta * MOVEMENT_ANIM_SPEED))

	# apply targeting movement blend value
	set(_targeting_movement_path, lerp(get(_targeting_movement_path), Vector2(horizontal_movement, vertical_movement), delta * MOVEMENT_ANIM_SPEED))

	# apply action blend value
	set(_action_blend_path, lerp(get(_action_blend_path), _action_blend_target, delta * ACTION_BLEND_SPEED))

# set to targeting movement
func set_targeting(targeting: bool) -> void:
	if targeting:
		set(_state_movement_path, "Targeting")
	else:
		set(_state_movement_path, "General")

# play/stop (upper body) action anim
func set_action(anim: String, enabled: bool = true) -> void:
	# set action state
	set(_state_action_path, anim)

	# set blend state
	if enabled:
		_action_blend_target = ACTION_BLEND_VALUE
	else:
		_action_blend_target = 0.0

# play one-shot animation
func play_anim(anim: String) -> void:
	# set state
	set(_state_output_path, anim)

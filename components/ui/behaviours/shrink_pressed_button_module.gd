extends Node
class_name ShrinkPressedButton

## Node that adds shrinking functionality to a button when pressed
## This node should be a child of a Button node

@export_group("Shrink Settings")
## The scale factor to apply when the button is pressed.
## Values less than 1.0 will shrink the button, creating a pressed effect.
@export var shrink_scale: Vector2 = Vector2(0.95, 0.95)

## Duration in seconds for the shrink animation when button is pressed.
## Lower values create snappier animations.
@export var shrink_duration: float = 0.1

## If enabled, modifies custom_minimum_size instead of scale property.
## Useful when scale changes would affect child nodes undesirably.
@export var use_minimum_size: bool = false

## Duration in seconds for the return animation when button is released.
## Lower values create snappier animations.
@export var return_duration: float = 0.1

@export_group("Animation Settings")
## The transition curve type for the animation.
## Determines how the animation accelerates and decelerates.
@export var tween_type: Tween.TransitionType = Tween.TRANS_EXPO

## The easing direction for the transition.
## Controls whether the transition eases in, out, or both.
@export var tween_ease: Tween.EaseType = Tween.EASE_OUT

## Optional control to animate instead of the button itself.
## If not set, the parent button will be animated.
@export var target_control: Control

var parent_button: BaseButton
var active_control: Control
var original_scale: Vector2
var original_min_size: Vector2
var original_size: Vector2
var tween: Tween

func _ready() -> void:
	# Check if parent is a button
	var parent: Node = get_parent()
	if not parent or not parent is BaseButton:
		push_error("ShrinkPressedButtonModule: Parent node must be a Button. Current parent: " + str(parent))
		queue_free()
		return
	
	parent_button = parent as BaseButton
	
	# Determine which control to animate
	if target_control and target_control is Control:
		active_control = target_control
	else:
		active_control = parent_button
	
	original_scale = active_control.scale
	if active_control is Control:
		original_min_size = (active_control as Control).custom_minimum_size
		original_size = (active_control as Control).size
	
	# Set initial pivot offset to center
	_update_pivot_offset()
	
	# Connect button signals
	parent_button.button_down.connect(_on_button_down)
	parent_button.button_up.connect(_on_button_up)
	
	# Connect to size changes to update pivot
	if active_control is Control:
		var control: Control = active_control as Control
		control.resized.connect(_update_pivot_offset)

func _on_button_down() -> void:
	# Cancel any existing tween
	if tween and tween.is_running():
		tween.kill()
	
	# Create shrink animation
	tween = create_tween()
	tween.set_trans(tween_type)
	tween.set_ease(tween_ease)
	if use_minimum_size and active_control is Control:
		var control: Control = active_control as Control
		var current_size: Vector2 = control.size
		var target_size: Vector2 = current_size * shrink_scale
		var target_min_size: Vector2 = control.custom_minimum_size * shrink_scale
		# Tween both minimum size and actual size
		tween.tween_property(control, "custom_minimum_size", target_min_size, shrink_duration)
		tween.parallel().tween_property(control, "size", target_size, shrink_duration)
	else:
		tween.tween_property(active_control, "scale", shrink_scale, shrink_duration)

func _on_button_up() -> void:
	# Cancel any existing tween
	if tween and tween.is_running():
		tween.kill()
	
	# Create return animation
	tween = create_tween()
	tween.set_trans(tween_type)
	tween.set_ease(tween_ease)
	if use_minimum_size and active_control is Control:
		var control: Control = active_control as Control
		# Tween both minimum size and actual size back to original
		tween.tween_property(control, "custom_minimum_size", original_min_size, return_duration)
		tween.parallel().tween_property(control, "size", original_size, return_duration)
	else:
		tween.tween_property(active_control, "scale", original_scale, return_duration)

func _update_pivot_offset() -> void:
	# Update pivot offset to center of the button
	if active_control is Control:
		var control: Control = active_control as Control
		control.pivot_offset = control.size / 2.0

func _exit_tree() -> void:
	# Clean up connections if parent still exists
	if parent_button and not parent_button.is_queued_for_deletion():
		if parent_button.button_down.is_connected(_on_button_down):
			parent_button.button_down.disconnect(_on_button_down)
		if parent_button.button_up.is_connected(_on_button_up):
			parent_button.button_up.disconnect(_on_button_up)
		
	# Disconnect resized signal if connected
	if active_control and not active_control.is_queued_for_deletion():
		if active_control.resized.is_connected(_update_pivot_offset):
			active_control.resized.disconnect(_update_pivot_offset)

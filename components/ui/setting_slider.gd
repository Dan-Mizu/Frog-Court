extends HBoxContainer
class_name SettingSlider

# signals
signal value_changed(value: int)

# references
@export var slider: HSlider
@export var number_input: SpinBox

# internal
var _value: int = 100:
	set(value):
		# store value
		_value = value

		# emit value changed event
		value_changed.emit(_value)

func _ready() -> void: setup()

func setup(value: int = _value) -> void:
	# store value
	if value != _value: _value = value

	# update inputs
	number_input.value = _value
	slider.value = _value

func _on_number_input_value_changed(value: float) -> void:
	# update slider
	slider.value = value

	# save value
	_value = int(value)

func _on_slider_value_changed(value: float) -> void:
	# update number input
	number_input.value = value

	# save value
	_value = int(value)

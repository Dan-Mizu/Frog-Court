extends CanvasLayer
class_name PauseMenu

# references
@export var master_volume_setting_slider: SettingSlider
@export var voices_volume_setting_slider: SettingSlider
@export var ambience_volume_setting_slider: SettingSlider
@export var ui_volume_setting_slider: SettingSlider

# internal
@onready var enabled = false

func _ready() -> void:
	# hide on start
	self.visible = false

	# initialize options
	_init_volume_sliders()

func _on_splashscreen_finished() -> void: 
	# enable the use of the pause menu after the splashscreen is finished showing
	enabled = true

#region Pausing
func _input(event: InputEvent) -> void:
	# not enabled
	if not enabled: return

	# pause key (ESC on keyboard)
	if event.is_action_pressed("ui_cancel"): 
		if self.visible: unpause()
		else: pause()

func _on_resume_pressed() -> void: unpause()

func _on_exit_pressed() -> void: get_tree().quit()

func pause() -> void:
	# pause the game
	get_tree().paused = true

	# show pause menu
	self.visible = true

func unpause() -> void:
	# hide pause menu
	self.visible = false

	# unpause the game
	get_tree().paused = false
#endregion

#region Options
func _init_volume_sliders() -> void:
	master_volume_setting_slider.setup(db_to_slider(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))))
	voices_volume_setting_slider.setup(db_to_slider(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Voices"))))
	ambience_volume_setting_slider.setup(db_to_slider(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambience"))))
	ui_volume_setting_slider.setup(db_to_slider(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("UI"))))

func _on_master_volume_setting_value_changed(value: int) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), slider_to_db(value))

func _on_voices_volume_setting_value_changed(value: int) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Voices"), slider_to_db(value))

func _on_ambience_volume_setting_value_changed(value: int) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), slider_to_db(value))

func _on_ui_volume_setting_value_changed(value: int) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), slider_to_db(value))
#endregion

#region Utility
func slider_to_db(value: int) -> float: return lerp(-80, 0, clamp(value, 0, 100) / 100.0)
func db_to_slider(db: float) -> int: return int(round((clamp(db, -80, 0) + 80) / 80.0 * 100))
#endregion

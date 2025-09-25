extends Node3D

@export_category("References")
@export var speaking_balloon: PackedScene
@export var speaking_dialogue: DialogueResource
@export var phase_panel_scene: PackedScene
enum Cams {
	JUDGE,
	CLAIMANT,
	DEFENDANT,
	PANEL,
	JURY
}
@export var cam_markers: Dictionary[Cams, PhantomCamera3D]

@export_group("SFX")
@export var crowd_murmur_sfx: AudioStream
@export var gavel_sfx: AudioStream

# internal
var crowd_murmur_sfx_player: AudioStreamPlayer

func _ready() -> void:
	# play crowd murmur SFX
	crowd_murmur_sfx_player = SoundManager.play_ambient_sound(crowd_murmur_sfx.duplicate(), 3.0, "Ambience")

#region Events
func _on_twitch_modal_finished() -> void:
	# start the game once fully authenticated with twitch and the modal is fully hidden
	_start_game()

func _start_game() -> void:
	# change cam
	_set_cam(Cams.JUDGE)

	# start intro dialogue
	var intro_dialogue: DialogueBalloon = _play_dialogue("intro")
	intro_dialogue.finished.connect(_start_accusation_phase)

func _start_accusation_phase() -> void:
	# change cam
	_set_cam(Cams.PANEL)

	# start accusation phase
	State.round_data.phase = State.Phase.ACCUSATION
	var phase_panel: PhasePanel = phase_panel_scene.instantiate().init(10)
	self.add_child(phase_panel)
	phase_panel.finished.connect(_on_accusation_phase_finished)

func _on_accusation_phase_finished() -> void:
	# update phase
	State.round_data.phase = State.Phase.NONE

	# change cam
	_set_cam(Cams.JUDGE)

	State.round_data.accusations.responses.size()

	# no accusations provided
	if State.round_data.accusations.responses.is_empty(): _play_dialogue("no_accusations")

	# allow judge to pick an accusation
	else: _play_dialogue("accusations_received")
#endregion

#region Utility
func play_and_wait_sound(sound: AudioStream) -> void:
	await play_sound(sound).finished

func play_sound(sound: AudioStream) -> AudioStreamPlayer:
	return SoundManager.play_sound(sound, "Ambience")

func fade_out_sound(player: AudioStreamPlayer, duration: float = 1.0) -> void:
	SoundManager.sound_effects.fade_volume(player, player.volume_db, -80.0, duration)

func _set_cam(cam: Cams) -> void:
	# loop through all registered camera markers
	for cam_key in cam_markers:
		# get phantom camera 3d node (camera marker)
		var phantom_camera_3d: PhantomCamera3D = cam_markers.get(cam_key) as PhantomCamera3D 

		# switch to the provided one
		if cam_key == cam: phantom_camera_3d.priority = 1

		# reset all others
		else: phantom_camera_3d.priority = 0

func _play_dialogue(dialogue: StringName) -> DialogueBalloon:
	return DialogueManager.show_dialogue_balloon_scene(speaking_balloon, speaking_dialogue, dialogue) as DialogueBalloon
#endregion

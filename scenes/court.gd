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

func _start_game() -> void:
	# go to judge cam
	_set_cam(Cams.JUDGE)

	# start intro dialogue
	var intro_dialogue: DialogueBalloon = DialogueManager.show_dialogue_balloon_scene(speaking_balloon, speaking_dialogue, "intro") as DialogueBalloon
	intro_dialogue.finished.connect(_start_claim_phase)

func _start_claim_phase() -> void:
	# go to judge cam
	_set_cam(Cams.PANEL)

	# start claim phase
	State.round_data.phase = State.Phase.ACCUSATION
	var phase_panel: PhasePanel = phase_panel_scene.instantiate().init(500)
	self.add_child(phase_panel)

	## start claim dialogue
	#var claim_dialogue: DialogueBalloon = DialogueManager.show_dialogue_balloon_scene(speaking_balloon, speaking_dialogue, "intro") as DialogueBalloon
	#claim_dialogue.finished.connect(_start_claim_phase)

func _set_cam(cam: Cams) -> void:
	# loop through all registered camera markers
	for cam_key in cam_markers:
		# get phantom camera 3d node (camera marker)
		var phantom_camera_3d: PhantomCamera3D = cam_markers.get(cam_key) as PhantomCamera3D 

		# switch to the provided one
		if cam_key == cam: phantom_camera_3d.priority = 1

		# reset all others
		else: phantom_camera_3d.priority = 0

func _on_twitch_modal_finished() -> void:
	# start the game once fully authenticated with twitch and the modal is fully hidden
	_start_game()

func play_and_wait_sound(sound: AudioStream) -> void:
	await play_sound(sound).finished

func play_sound(sound: AudioStream) -> AudioStreamPlayer:
	return SoundManager.play_sound(sound, "Ambience")

func fade_out_sound(player: AudioStreamPlayer, duration: float = 1.0) -> void:
	SoundManager.sound_effects.fade_volume(player, player.volume_db, -80.0, duration)

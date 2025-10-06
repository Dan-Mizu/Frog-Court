extends Node3D

@export_category("References")
@export var pause_menu: PauseMenu
@export var speaking_balloon: PackedScene
@export var speaking_dialogue: DialogueResource
@export var phase_panel_scene: PackedScene
@export var accusation_selection_scene: PackedScene
enum Cams {
	JUDGE,
	CLAIMANT,
	DEFENDANT,
	GALLERY,
	JURY,
	JUDGE_CLOSE
}
@export var cam_positions: Dictionary[Cams, PhantomCamera3D]
@export var characters: Array[PackedScene]
@export var claimant_position: Marker3D
@export var defendant_position: Marker3D
@export var jury_positions: Array[Marker3D]
@export var gallery_positions: Array[Marker3D]

@export_group("SFX")
@export var crowd_murmur_sfx: AudioStream
@export var gavel_sfx: AudioStream

# internal
var crowd_murmur_sfx_player: AudioStreamPlayer

# setup scene
func _ready() -> void:
	# add gallery and jury characters
	jury_positions.shuffle()
	for i in range(randi_range(3, 4)): jury_positions[i].add_child(_get_random_character().instantiate())
	gallery_positions.shuffle()
	for i in range(randi_range(4, 6)): gallery_positions[i].add_child(_get_random_character().instantiate())

	# play crowd murmur SFX
	crowd_murmur_sfx_player = SoundManager.play_ambient_sound(crowd_murmur_sfx.duplicate(), 3.0, "Ambience")

#region Events
# start the game once fully authenticated with twitch and the modal is fully hidden
func _on_twitch_modal_finished() -> void: _start_game()

func _start_game() -> void:
	# change cam
	_set_cam(Cams.JUDGE)

	# start intro dialogue
	_play_dialogue("intro").finished.connect(_start_accusation_phase)

# allow chatters to use command to accuse others with a claim
func _start_accusation_phase() -> void:
	# change cam
	_set_cam(Cams.GALLERY)

	# start accusation phase
	State.round_data.phase = State.Phase.ACCUSATION
	var phase_panel: PhasePanel = phase_panel_scene.instantiate()
	self.add_child(phase_panel)
	phase_panel.finished.connect(_on_accusation_phase_finished)

	# notify twitch chat
	Twitch.chat("/me Accusation phase has begun. Type !accuse <user> <claim>")

# reviewing results of claim phase
func _on_accusation_phase_finished() -> void:
	# update phase
	State.round_data.phase = State.Phase.NONE

	# no accusations provided (restart)
	if State.round_data.accusations.responses.is_empty(): 
		# switch to normal judge cam
		_set_cam(Cams.JUDGE)

		# disable pause menu
		pause_menu.enabled = false

		# start judge dialogue
		_play_dialogue("no_accusations").finished.connect(_restart)

	# allow judge to pick an accusation
	else: 
		# switch to closer cam
		_set_cam(Cams.JUDGE_CLOSE)

		# start judge dialogue
		_play_dialogue("accusations_received").finished.connect(_start_accusation_selection)

# restart game
func _restart() -> void: get_tree().reload_current_scene()

# let judge pick an accusation
func _start_accusation_selection() -> void:
	# show accusation form clipboard UI
	var accusation_selection_ui: AccusationSelectionUI = accusation_selection_scene.instantiate()
	self.add_child(accusation_selection_ui)

	# connect events
	accusation_selection_ui.no_claims_selected.connect(_on_no_accusation_selected)
	accusation_selection_ui.claim_selected.connect(_on_accusation_selected)

func _on_no_accusation_selected() -> void:
	# disable pause menu
	pause_menu.enabled = false

	# restart
	_play_dialogue("no_selected_accusation").finished.connect(_restart)

func _on_accusation_selected(claim: State.ResponseAccusation) -> void:
	# store
	State.selected_accusation = claim

	# start the accused's defense
	_play_dialogue("accusation_selected").finished.connect(_start_accusation_defense)

func _start_accusation_defense() -> void:
	# show accuser's character
	var accuser_character: ChatterCharacter = _get_character_from_id(State.selected_accusation.user_id).instantiate()
	claimant_position.add_child(accuser_character)

	# switch to accuser cam and make them emote
	_set_cam(Cams.CLAIMANT)
	accuser_character.play_anim(ChatterCharacter.Anim.SAD)

	# focus the accused when the focus on the accuser is finished
	accuser_character.finished_animation.connect(func(_anim: ChatterCharacter.Anim): _on_finished_accuser_focus(), ConnectFlags.CONNECT_ONE_SHOT)

func _on_finished_accuser_focus() -> void:
	# accused is not in chat
	if State.selected_accusation.accuser_id.is_empty(): 
		# start jury phase instead
		

		return

	# show accused's character
	var accused_character: ChatterCharacter = _get_character_from_id(State.selected_accusation.accuser_id).instantiate()
	defendant_position.add_child(accused_character)

	# switch to accused cam
	_set_cam(Cams.DEFENDANT)
	accused_character.play_anim(ChatterCharacter.Anim.HOP)

	# begin capturing accused's chat messages and displaying them
	
#endregion

#region Utility
func _play_dialogue(dialogue: StringName) -> DialogueBalloon: return DialogueManager.show_dialogue_balloon_scene(speaking_balloon, speaking_dialogue, dialogue) as DialogueBalloon

func _set_cam(cam: Cams) -> void:
	# loop through all registered camera markers
	for cam_key in cam_positions:
		# get phantom camera 3d node (camera marker)
		var phantom_camera_3d: PhantomCamera3D = cam_positions.get(cam_key) as PhantomCamera3D 

		# switch to the provided one
		if cam_key == cam: phantom_camera_3d.priority = 1

		# reset all others
		else: phantom_camera_3d.priority = 0

func _get_character_from_id(_id: String) -> PackedScene:
	# convert ID to int
	var id: int = int(_id)

	# always give back the same character scene, given the same input
	return characters[id % characters.size()]

var _character_pool: Array[PackedScene]
func _get_random_character() -> PackedScene:
	# refresh pool
	if _character_pool.is_empty(): 
		_character_pool = characters.duplicate()
		_character_pool.shuffle()

	return _character_pool.pop_back()
#endregion

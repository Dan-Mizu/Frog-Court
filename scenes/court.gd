extends Node3D

@export_category("References")
@export var pause_menu: PauseMenu
@export var fade_overlay_animation_player: AnimationPlayer
@export var speaking_balloon: PackedScene
@export var speaking_dialogue: DialogueResource
@export var runtime_balloon: PackedScene
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
@export var crowd_gasp_sfx: AudioStream
@export var gavel_sfx: AudioStream

# internal
@onready var _loaded_characters: Array[ChatterCharacter] = []

# phase panel data
@onready var phase_panels_data: Dictionary[State.Phase, PhasePanel.PhasePanelData] = {
	State.Phase.ACCUSATION: PhasePanel.PhasePanelData.new().init("!accuse <user> <claim>", [
			"!accuse Nymn Didn't go live on time.",
			"!accuse Erobb221 Scamming a charity.",
			"!accuse Chatter Posting an ascii phallus in chat.",
			"!accuse Chatter Furry tendencies.",
			"!accuse Pokelawls Swollen balls.",
			"!accuse Forsen Primary suspect in nina's disappearance."
		], true),
	#State.Phase.DEFENSE: PhasePanel.PhasePanelData.new().init("defend yourself"),
	State.Phase.DELIBERATION: PhasePanel.PhasePanelData.new().init("is the defendant guilty? vote !yea / !nay", [], true)
}

# internal
@onready var crowd_murmur_sfx_player: AudioStreamPlayer = null

# setup scene
func _ready() -> void:
	# add background characters
	_setup_characters()

	# play crowd murmur SFX
	crowd_murmur_sfx_player = SoundManager.play_ambient_sound(crowd_murmur_sfx, 3.0, "Ambience")

func _setup_characters() -> void:
	# delete previous characters
	for old_character in _loaded_characters: old_character.free()
	_loaded_characters.clear()

	# add gallery and jury characters
	jury_positions.shuffle()
	for i in range(randi_range(3, 4)): 
		var character: ChatterCharacter = _get_random_character().instantiate()
		jury_positions[i].add_child(character)
		_loaded_characters.append(character)
	gallery_positions.shuffle()
	for i in range(randi_range(4, 6)): 
		var character: ChatterCharacter = _get_random_character().instantiate()
		gallery_positions[i].add_child(character)
		_loaded_characters.append(character)

# restart game
func _restart() -> void:
	# fade to black
	fade_overlay_animation_player.play("fade_in")

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
	var phase_panel: PhasePanel = phase_panel_scene.instantiate().init(phase_panels_data.get(State.round_data.phase))
	self.add_child(phase_panel)
	phase_panel.finished.connect(_on_accusation_phase_finished)

	# notify twitch chat
	Twitch.announcment("📣 Accusation phase has begun. Type !accuse <user> <claim>")

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
	State.round_data.selected_accusation = claim

	# start the accused's defense
	_play_dialogue("accusation_selected").finished.connect(_start_accusation_defense)

func _start_accusation_defense() -> void:
	# show accuser's character
	var accuser_character: ChatterCharacter = _get_character_from_id(State.round_data.selected_accusation.user_id).instantiate()
	claimant_position.add_child(accuser_character)
	_loaded_characters.append(accuser_character)

	# switch to accuser cam and make them emote
	_set_cam(Cams.CLAIMANT)
	accuser_character.play_anim(ChatterCharacter.Anim.SAD)

	# play accuser dialogue
	_play_dialogue("accuser_claim").finished.connect(_on_finished_accuser_focus)

func _on_finished_accuser_focus() -> void:
	# accused is not in chat- start deliberation phase instead
	if State.round_data.selected_accusation.accused_id.is_empty():
		# judge cam
		_set_cam(Cams.JUDGE)

		# start judge dialogue
		_play_dialogue("begin_deliberation").finished.connect(_start_deliberation_phase)

		# skip showing defendant
		return

	# show accused's character
	var accused_character: ChatterCharacter = _get_character_from_id(State.round_data.selected_accusation.accused_id).instantiate()
	defendant_position.add_child(accused_character)
	_loaded_characters.append(accused_character)

	# switch to accused cam
	_set_cam(Cams.DEFENDANT)
	accused_character.play_anim(ChatterCharacter.Anim.HOP)

	# start defense phase
	State.round_data.phase = State.Phase.DEFENSE
	var phase_panel: PhasePanel = phase_panel_scene.instantiate().init(PhasePanel.PhasePanelData.new().init("defend yourself, %s!" % State.round_data.selected_accusation.accused_name), 90.)
	self.add_child(phase_panel)
	phase_panel.finished.connect(_on_defense_phase_finished)

	# begin capturing accused's chat messages and displaying them
	var defendant_balloon: RuntimeBalloon = runtime_balloon.instantiate()
	self.add_child(defendant_balloon)
	phase_panel.hiding.connect(func(): defendant_balloon.animation_player.play("hide"))

	# notify twitch chat
	Twitch.announcment("🛡️ @%s, defend yourself!" % State.round_data.selected_accusation.accused_name)

func _on_defense_phase_finished() -> void:
	# update phase
	State.round_data.phase = State.Phase.NONE

	# judge cam
	_set_cam(Cams.JUDGE)

	# start judge dialogue
	_play_dialogue("defense_finished").finished.connect(_start_deliberation_phase)

func _start_deliberation_phase() -> void:
	# switch to jury cam
	_set_cam(Cams.JURY)

	# start deliberation phase
	State.round_data.phase = State.Phase.DELIBERATION
	var phase_panel: PhasePanel = phase_panel_scene.instantiate().init(phase_panels_data.get(State.round_data.phase))
	self.add_child(phase_panel)
	phase_panel.finished.connect(_on_deliberation_phase_finished)

	# notify twitch chat
	Twitch.announcment("🗳️ Deliberation phase has begun. Type !yea or !nay if the defendant is guilty or not.")

func _on_deliberation_phase_finished() -> void:
	# update phase
	State.round_data.phase = State.Phase.NONE

	# close judge cam
	_set_cam(Cams.JUDGE_CLOSE)

	# disable pause menu
	pause_menu.enabled = false

	# judge delivers final verdict
	_play_dialogue("deliberation_over").finished.connect(_restart)

func _on_fade_in() -> void:
	# reset round data
	State.round_data = State.RoundData.new()

	# reset characters
	_setup_characters()

	# change cam
	_set_cam(Cams.JURY, _on_cam_reset)

func _on_cam_reset() -> void:
	# fade from black
	fade_overlay_animation_player.play("fade_out")

func _on_fade_out() -> void:
	# change cam
	_set_cam(Cams.JUDGE)

	# start new day dialogue
	_play_dialogue("another_day").finished.connect(_start_accusation_phase)

	# enable pause menu
	pause_menu.enabled = true
#endregion

#region Utility
func _play_dialogue(dialogue: StringName) -> DialogueBalloon: return DialogueManager.show_dialogue_balloon_scene(speaking_balloon, speaking_dialogue, dialogue) as DialogueBalloon

func _set_cam(cam: Cams, call_once: Callable = func(): pass ) -> void:
	# loop through all registered camera markers
	for cam_key in cam_positions:
		# get phantom camera 3d node (camera marker)
		var phantom_camera_3d: PhantomCamera3D = cam_positions.get(cam_key) as PhantomCamera3D 

		# switch to the provided one
		if cam_key == cam: 
			phantom_camera_3d.priority = 1
			phantom_camera_3d.tween_completed.connect(call_once, ConnectFlags.CONNECT_ONE_SHOT)

		# reset all others
		else: phantom_camera_3d.priority = 0

func _get_character_from_id(_id: String) -> PackedScene:
	# convert ID to int
	var id: int = int(_id)

	# always give back the same character scene, given the same input
	return characters[id % characters.size()]

@onready var _character_pool: Array[PackedScene] = []
func _get_random_character() -> PackedScene:
	# refresh pool
	if _character_pool.is_empty(): 
		_character_pool = characters.duplicate()
		_character_pool.shuffle()

	return _character_pool.pop_back()
#endregion

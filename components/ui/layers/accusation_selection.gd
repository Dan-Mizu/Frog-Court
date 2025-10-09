extends CanvasLayer
class_name AccusationSelectionUI

# signals
signal claim_selected(claim: State.ResponseAccusation)
signal no_claims_selected

# references
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var accuser_name_label: Label = %"Accuser Name"
@onready var accused_name_label: Label = %"Accused Name"
@onready var claim_label: Label = %Claim
@onready var buttons_container: VBoxContainer = %Buttons

@export var page_turn_sfx: AudioStream

# internal
var _current_accusation: State.ResponseAccusation
@onready var _selected: bool = false
var _chatters: Array[String]

# get first accusation
func _ready() -> void:
	# get list of chatters
	_chatters = await get_all_chatters(State.broadcaster_user.id)

	# hide buttons
	buttons_container.visible = false

	# shuffle responses randomly
	State.round_data.accusations.responses.shuffle()

	# get first accusation
	await _get_next_accusation()

	# show clipboard
	animation_player.play("show")

func _get_next_accusation() -> void:
	# get next shuffled response
	_current_accusation = State.round_data.accusations.responses.pop_back()

	# fetch accused twitch user
	var user: TwitchUser = await Twitch.get_user(_current_accusation.accused_name)

	# found user- check if in chat room
	if user:
		# update accused name
		_current_accusation.accused_name = user.display_name

		# is currently in chat- store ID
		if user.id in _chatters: _current_accusation.accused_id = user.id

	# setup UI form
	accuser_name_label.text = _current_accusation.user_display_name
	accused_name_label.text = _current_accusation.accused_name
	claim_label.text = _current_accusation.message

	# play page turn sound
	Utility.play_sound(page_turn_sfx)

	# show buttons
	buttons_container.visible = true

func _on_dismiss_button_pressed() -> void:
	# hide buttons
	buttons_container.visible = false

	# next accusation
	if not State.round_data.accusations.responses.is_empty(): _get_next_accusation()

	# out of accusations (hide clipboard)
	else: animation_player.play("hide")

func _on_proceed_button_pressed() -> void:
	# hide buttons
	buttons_container.visible = false

	# mark accusation as selected
	_selected = true

	# hide clipboard
	animation_player.play("hide")

func _on_clipboard_fully_hidden() -> void:
	# accusation selected
	if _selected: claim_selected.emit(_current_accusation)

	# no accusation selected
	else: no_claims_selected.emit()

	# end
	self.queue_free()

func get_all_chatters(auth_user_id: String) -> Array[String]:
	# init
	var all_chatters: Array[String] = []

	# options
	var opt := TwitchGetChatters.Opt.create()
	opt.first = 1000  # maximum allowed per page

	# fetch
	var response: TwitchGetChatters.Response = await Twitch.api.get_chatters(opt, auth_user_id, auth_user_id)
	while response != null:
		# get chatters from this page
		for chatter in response.data: all_chatters.append(chatter.user_id)

		# no more pagination
		if not response._has_pagination(): break

		# next page
		response = await response.next_page()

	return all_chatters

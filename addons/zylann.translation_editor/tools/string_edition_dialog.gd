@tool
extends AcceptDialog

signal submitted(str_id, prev_str_id)

@onready var _line_edit : LineEdit = $VBoxContainer/LineEdit
@onready var _hint_label : Label = $VBoxContainer/HintLabel

var _validator_func : Callable
var _prev_str_id := ""

var valid := false

func _ready() -> void:
	get_ok_button().disabled = true

func set_replaced_str_id(str_id: String):
	_prev_str_id = str_id
	_line_edit.text = str_id


func set_validator(f: Callable):
	_validator_func = f


func _notification(what: int):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			if _prev_str_id == "":
				title = "New string ID"
			else:
				title = str("Replace `", _prev_str_id, "`")
			_line_edit.grab_focus()
			_validate()


func _on_LineEdit_text_changed(new_text: String):
	_validate()


func _validate():
	var new_text := _line_edit.text.strip_edges()
	valid = not new_text.is_empty()
	var hint_message := ""

	if _validator_func != null:
		var res = _validator_func.call(new_text)
		assert(typeof(res) == TYPE_BOOL or typeof(res) == TYPE_STRING)
		if typeof(res) != TYPE_BOOL or res == false:
			hint_message = res
			valid = false

	_hint_label.text = hint_message
	if hint_message.is_empty():
		_hint_label.hide()
	get_ok_button().disabled = not valid


func _on_LineEdit_text_entered(new_text: String):
	submit()


func submit():
	if not valid:
		return
	var s := _line_edit.text.strip_edges()
	emit_signal("submitted", s, _prev_str_id)
	hide()


func _on_canceled() -> void:
	hide()

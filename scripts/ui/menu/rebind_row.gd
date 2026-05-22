class_name RebindRow
extends HBoxContainer
## One control-remapping row: an action label + a button that, when pressed,
## listens for the next key/mouse press and rebinds the action via Profiles.

var action: StringName
var _btn: Button
var _listening: bool = false

func setup(a: StringName, human: String) -> void:
	action = a
	add_theme_constant_override(&"separation", 4)
	var label := Label.new()
	label.text = human
	label.custom_minimum_size.x = 70
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(label)
	_btn = Button.new()
	_btn.custom_minimum_size.x = 72
	_btn.pressed.connect(_begin_listen)
	add_child(_btn)
	refresh_label()

func refresh_label() -> void:
	if _listening:
		return
	var evs: Array = Profiles.get_action_events(action)
	_btn.text = Profiles.event_label(evs[0]) if evs.size() > 0 else "<unset>"

func _begin_listen() -> void:
	_listening = true
	_btn.text = "Press a key..."
	_btn.release_focus()  # so Space/Enter from the click isn't captured as the binding

func _input(event: InputEvent) -> void:
	if not _listening:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_listening = false
		refresh_label()
		get_viewport().set_input_as_handled()
		return
	var ok: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed)
	if not ok:
		return
	# Ignore modifier-only key presses (Shift/Ctrl/Alt/Meta on their own).
	if event is InputEventKey and event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
		return
	_listening = false
	Profiles.rebind_action(action, event)
	Profiles.save_active()
	refresh_label()
	get_viewport().set_input_as_handled()  # swallow so the menu doesn't also act on it

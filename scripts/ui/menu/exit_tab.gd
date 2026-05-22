extends Control
## Exit: manage named profiles (create / select / delete) and quit the game.

var _list: ItemList
var _new_name: LineEdit

func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override(StringName("margin_" + side), 6)
	add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 4)
	margin.add_child(vb)

	var heading := Label.new()
	heading.text = "Profiles"
	heading.modulate = Color(0.55, 0.78, 1, 1)
	vb.add_child(heading)

	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(220, 90)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_activated.connect(func(_idx: int) -> void: _select())
	vb.add_child(_list)

	var create_row := HBoxContainer.new()
	_new_name = LineEdit.new()
	_new_name.placeholder_text = "New profile name"
	_new_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_new_name.text_submitted.connect(func(_t: String) -> void: _create())
	create_row.add_child(_new_name)
	var create_btn := Button.new()
	create_btn.text = "Create"
	create_btn.pressed.connect(_create)
	create_row.add_child(create_btn)
	vb.add_child(create_row)

	var action_row := HBoxContainer.new()
	var select_btn := Button.new()
	select_btn.text = "Set Active"
	select_btn.pressed.connect(_select)
	action_row.add_child(select_btn)
	var delete_btn := Button.new()
	delete_btn.text = "Delete"
	delete_btn.pressed.connect(_delete)
	action_row.add_child(delete_btn)
	vb.add_child(action_row)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 4
	vb.add_child(spacer)

	var exit_btn := Button.new()
	exit_btn.text = "Exit Game"
	exit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	exit_btn.pressed.connect(func() -> void: get_tree().quit())
	vb.add_child(exit_btn)

	Profiles.active_profile_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	_list.clear()
	var active := Profiles.active_slug()
	for slug in Profiles.list_profiles():
		var label := Profiles.profile_display_name(slug)
		if slug == active:
			label += "  (active)"
		var idx := _list.add_item(label)
		_list.set_item_metadata(idx, slug)

func _selected_slug() -> String:
	var sel := _list.get_selected_items()
	if sel.is_empty():
		return ""
	return String(_list.get_item_metadata(sel[0]))

func _create() -> void:
	var profile_name := _new_name.text.strip_edges()
	if profile_name == "":
		return
	_new_name.clear()
	Profiles.create_profile(profile_name)  # emits active_profile_changed -> _refresh

func _select() -> void:
	var slug := _selected_slug()
	if slug != "":
		Profiles.select_profile(slug)  # emits active_profile_changed -> _refresh

func _delete() -> void:
	var slug := _selected_slug()
	if slug != "":
		Profiles.delete_profile(slug)
		_refresh()

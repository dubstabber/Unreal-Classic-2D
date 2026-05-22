extends Control
## Player: edit the active profile's name + body color, and remap controls.

const RebindRowScript := preload("res://scripts/ui/menu/rebind_row.gd")

# Curated palette subset offered as body-color swatches.
const SWATCHES: Array[Color] = [
	Color(0.30, 0.55, 0.85, 1),  # armor_mid
	Color(0.40, 0.95, 0.50, 1),  # hp_full
	Color(1.00, 0.55, 0.15, 1),  # flak_orange
	Color(0.70, 0.40, 1.00, 1),  # shock_purple
	Color(0.40, 0.85, 1.00, 1),  # laser_blue
	Color(0.85, 0.30, 0.20, 1),  # rocket
	Color(0.95, 0.80, 0.30, 1),  # ammo
	Color(0.85, 0.90, 1.00, 1),  # pale
]

var _name_edit: LineEdit
var _preview: TextureRect
var _rows: Array = []

func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override(StringName("margin_" + side), 6)
	add_child(margin)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 14)
	margin.add_child(hb)

	hb.add_child(_build_left())
	hb.add_child(_build_right())
	Profiles.active_profile_changed.connect(_reload)

func _build_left() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 4)
	vb.custom_minimum_size.x = 150

	vb.add_child(_heading("Profile"))

	var name_row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = "Name"
	name_label.custom_minimum_size.x = 48
	name_row.add_child(name_label)
	_name_edit = LineEdit.new()
	_name_edit.text = Profiles.player_name()
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.text_submitted.connect(func(_t: String) -> void: _commit_name())
	_name_edit.focus_exited.connect(_commit_name)
	name_row.add_child(_name_edit)
	vb.add_child(name_row)

	vb.add_child(_heading("Body Color"))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override(&"h_separation", 4)
	grid.add_theme_constant_override(&"v_separation", 4)
	for c in SWATCHES:
		grid.add_child(_swatch_button(c))
	vb.add_child(grid)

	_preview = TextureRect.new()
	_preview.texture = SpriteBaker.get_texture(&"pawn_torso")
	_preview.custom_minimum_size = Vector2(48, 48)
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.modulate = Profiles.player_color()
	vb.add_child(_preview)

	return vb

func _build_right() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 4)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	vb.add_child(_heading("Controls"))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(180, 120)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override(&"separation", 2)
	for action in Profiles.REBINDABLE:
		var row := RebindRowScript.new()
		list.add_child(row)
		row.setup(action, Profiles.action_label(action))
		_rows.append(row)
	scroll.add_child(list)
	vb.add_child(scroll)

	var reset := Button.new()
	reset.text = "Reset to Defaults"
	reset.pressed.connect(func() -> void:
		Profiles.reset_all_bindings()
		Profiles.save_active()
		for r in _rows:
			r.refresh_label())
	vb.add_child(reset)

	return vb

func _heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.modulate = Color(0.55, 0.78, 1, 1)
	return l

func _swatch_button(c: Color) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(20, 20)
	for state in [&"normal", &"hover", &"pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = c
		sb.border_color = Color(0.05, 0.07, 0.12, 1)
		sb.set_border_width_all(1)
		b.add_theme_stylebox_override(state, sb)
	b.pressed.connect(func() -> void:
		Profiles.active.body_color = c
		_preview.modulate = c
		Profiles.save_active())
	return b

func _commit_name() -> void:
	var t := _name_edit.text.strip_edges()
	if t == "":
		t = "Player"
		_name_edit.text = t
	Profiles.active.name = t
	Profiles.save_active()

func _reload() -> void:
	_name_edit.text = Profiles.player_name()
	_preview.modulate = Profiles.player_color()
	for r in _rows:
		r.refresh_label()

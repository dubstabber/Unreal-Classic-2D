extends Control
## Options: Video / Audio / Gameplay sub-tabs. Each control applies its change
## live through Profiles and persists it to the active profile.

# Cached controls so we can refresh them when the active profile changes.
var _window_mode: OptionButton
var _vsync: CheckBox
var _integer_scaling: CheckBox
var _audio_sliders: Dictionary = {}   # StringName bus -> HSlider
var _audio_pct: Dictionary = {}       # StringName bus -> Label
var _crosshair_style: OptionButton
var _crosshair_color: ColorPickerButton
var _screen_shake: HSlider
var _damage_numbers: CheckBox

func _ready() -> void:
	var inner := TabContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(inner)
	var video := _build_video()
	video.name = "Video"
	inner.add_child(video)
	var audio := _build_audio()
	audio.name = "Audio"
	inner.add_child(audio)
	var gameplay := _build_gameplay()
	gameplay.name = "Gameplay"
	inner.add_child(gameplay)
	Profiles.active_profile_changed.connect(_reload)

# ---------------------------------------------------------------- builders

func _panel() -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override(StringName("margin_" + side), 6)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 4)
	margin.add_child(vb)
	# Attach the VBox's owning margin as the panel root via meta lookup.
	vb.set_meta(&"root", margin)
	return vb

func _wrap(vb: VBoxContainer) -> Control:
	return vb.get_meta(&"root")

func _row(grid: GridContainer, label_text: String, control: Control) -> void:
	var label := Label.new()
	label.text = label_text
	grid.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.custom_minimum_size.x = 120
	grid.add_child(control)

func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 8)
	grid.add_theme_constant_override(&"v_separation", 4)
	return grid

func _build_video() -> Control:
	var vb := _panel()
	var grid := _grid()
	vb.add_child(grid)
	var v: Dictionary = Profiles.active.options.video

	_window_mode = OptionButton.new()
	_window_mode.add_item("Windowed")
	_window_mode.add_item("Fullscreen")
	_window_mode.selected = int(v.window_mode)
	_window_mode.item_selected.connect(func(idx: int) -> void:
		Profiles.set_window_mode(idx)
		Profiles.save_active())
	_row(grid, "Window Mode", _window_mode)

	_vsync = CheckBox.new()
	_vsync.button_pressed = bool(v.vsync)
	_vsync.toggled.connect(func(on: bool) -> void:
		Profiles.set_vsync(on)
		Profiles.save_active())
	_row(grid, "VSync", _vsync)

	_integer_scaling = CheckBox.new()
	_integer_scaling.button_pressed = bool(v.integer_scaling)
	_integer_scaling.toggled.connect(func(on: bool) -> void:
		Profiles.set_integer_scaling(on)
		Profiles.save_active())
	_row(grid, "Integer Scaling", _integer_scaling)

	return _wrap(vb)

func _build_audio() -> Control:
	var vb := _panel()
	var grid := _grid()
	vb.add_child(grid)
	var a: Dictionary = Profiles.active.options.audio
	_add_audio_row(grid, "Master", &"Master", float(a.master))
	_add_audio_row(grid, "Music", &"Music", float(a.music))
	_add_audio_row(grid, "SFX", &"SFX", float(a.sfx))
	return _wrap(vb)

func _add_audio_row(grid: GridContainer, label_text: String, bus: StringName, value: float) -> void:
	var box := HBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 120
	var pct := Label.new()
	pct.custom_minimum_size.x = 36
	pct.text = "%d%%" % roundi(value * 100.0)
	slider.value_changed.connect(func(v: float) -> void:
		Profiles.set_audio_volume(bus, v)
		pct.text = "%d%%" % roundi(v * 100.0)
		Profiles.save_active())
	box.add_child(slider)
	box.add_child(pct)
	_audio_sliders[bus] = slider
	_audio_pct[bus] = pct
	_row(grid, label_text, box)

func _build_gameplay() -> Control:
	var vb := _panel()
	var grid := _grid()
	vb.add_child(grid)
	var g: Dictionary = Profiles.active.options.gameplay

	_crosshair_style = OptionButton.new()
	for n in ["Cross", "Dot", "Circle"]:
		_crosshair_style.add_item(n)
	_crosshair_style.selected = int(g.crosshair_style)
	_crosshair_style.item_selected.connect(func(idx: int) -> void:
		Profiles.active.options.gameplay.crosshair_style = idx
		Profiles.save_active())
	_row(grid, "Crosshair Style", _crosshair_style)

	_crosshair_color = ColorPickerButton.new()
	_crosshair_color.color = g.crosshair_color
	_crosshair_color.edit_alpha = false
	_crosshair_color.color_changed.connect(func(c: Color) -> void:
		Profiles.active.options.gameplay.crosshair_color = c
		Profiles.save_active())
	_row(grid, "Crosshair Color", _crosshair_color)

	_screen_shake = HSlider.new()
	_screen_shake.min_value = 0.0
	_screen_shake.max_value = 1.0
	_screen_shake.step = 0.05
	_screen_shake.value = float(g.screen_shake)
	_screen_shake.value_changed.connect(func(v: float) -> void:
		Profiles.active.options.gameplay.screen_shake = v
		Profiles.save_active())
	_row(grid, "Screen Shake", _screen_shake)

	_damage_numbers = CheckBox.new()
	_damage_numbers.button_pressed = bool(g.damage_numbers)
	_damage_numbers.toggled.connect(func(on: bool) -> void:
		Profiles.active.options.gameplay.damage_numbers = on
		Profiles.save_active())
	_row(grid, "Damage Numbers", _damage_numbers)

	return _wrap(vb)

# ---------------------------------------------------------------- reload on profile switch

func _reload() -> void:
	var v: Dictionary = Profiles.active.options.video
	_window_mode.selected = int(v.window_mode)
	_vsync.button_pressed = bool(v.vsync)
	_integer_scaling.button_pressed = bool(v.integer_scaling)
	var a: Dictionary = Profiles.active.options.audio
	_audio_sliders[&"Master"].value = float(a.master)
	_audio_sliders[&"Music"].value = float(a.music)
	_audio_sliders[&"SFX"].value = float(a.sfx)
	var g: Dictionary = Profiles.active.options.gameplay
	_crosshair_style.selected = int(g.crosshair_style)
	_crosshair_color.color = g.crosshair_color
	_screen_shake.value = float(g.screen_shake)
	_damage_numbers.button_pressed = bool(g.damage_numbers)

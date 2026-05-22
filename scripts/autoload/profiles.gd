extends Node
## Autoload. Settings + player-profile manager.
##
## Snapshots the project.godot InputMap at boot (the DEFAULT bindings), loads the
## active profile from user://, and applies its control bindings, audio bus
## volumes, and video settings. Exposes the active player's name/color so the
## match scene can dress the player pawn.
##
## Persistence: ConfigFile. One file per profile at user://profiles/<slug>.cfg,
## plus an index at user://profiles.cfg tracking the active profile and order.
## Saved bindings are SPARSE — only actions that differ from the snapshot are
## stored; anything absent falls back to the snapshot default.
##
## NOTE: no `class_name` — that would collide with the `Profiles` autoload name.
## Reference it everywhere as the global `Profiles`.

const PROFILES_DIR := "user://profiles"
const INDEX_PATH := "user://profiles.cfg"

## Actions the player may rebind (engine ui_* actions are intentionally excluded).
const REBINDABLE: Array[StringName] = [
	&"move_left", &"move_right", &"jump", &"crouch",
	&"primary_fire", &"secondary_fire",
	&"slot_1", &"slot_2", &"slot_3", &"slot_4", &"slot_5",
	&"slot_6", &"slot_7", &"slot_8", &"slot_9", &"slot_0",
]

const ACTION_LABELS := {
	&"move_left": "Move Left", &"move_right": "Move Right",
	&"jump": "Jump", &"crouch": "Crouch",
	&"primary_fire": "Primary Fire", &"secondary_fire": "Alt Fire",
	&"slot_1": "Weapon 1", &"slot_2": "Weapon 2", &"slot_3": "Weapon 3",
	&"slot_4": "Weapon 4", &"slot_5": "Weapon 5", &"slot_6": "Weapon 6",
	&"slot_7": "Weapon 7", &"slot_8": "Weapon 8", &"slot_9": "Weapon 9",
	&"slot_0": "Weapon 10",
}

const DEFAULT_BODY_COLOR := Color(0.30, 0.55, 0.85, 1.0)  # armor_mid

signal active_profile_changed

var active: Dictionary = {}

var _default_bindings: Dictionary = {}   # StringName -> Array[InputEvent]
var _profiles_order: Array = []          # Array[String] of slugs
var _active_slug: String = ""

# ---------------------------------------------------------------- boot

func _ready() -> void:
	_snapshot_defaults()
	_ensure_dir()
	_load_index()
	if _profiles_order.is_empty():
		create_profile("Player")
	else:
		if _active_slug == "" or not _profiles_order.has(_active_slug):
			_active_slug = _profiles_order[0]
		active = _load_profile(_active_slug)
		apply_all()

func _snapshot_defaults() -> void:
	_default_bindings.clear()
	for action in InputMap.get_actions():
		var events: Array[InputEvent] = []
		for ev in InputMap.action_get_events(action):
			events.append(ev.duplicate())  # duplicate so later erase/add can't corrupt the snapshot
		_default_bindings[action] = events

func _ensure_dir() -> void:
	if not DirAccess.dir_exists_absolute(PROFILES_DIR):
		DirAccess.make_dir_recursive_absolute(PROFILES_DIR)

# ---------------------------------------------------------------- queries

func player_name() -> String:
	return String(active.get("name", "Player"))

func player_color() -> Color:
	return active.get("body_color", DEFAULT_BODY_COLOR)

func gameplay() -> Dictionary:
	if active.has("options"):
		return active.options.gameplay
	return _default_options().gameplay

func list_profiles() -> Array:
	return _profiles_order.duplicate()

func active_slug() -> String:
	return _active_slug

func profile_display_name(slug: String) -> String:
	var cfg := ConfigFile.new()
	if cfg.load(_profile_path(slug)) == OK:
		return String(cfg.get_value("profile", "name", slug))
	return slug

func action_label(action: StringName) -> String:
	return ACTION_LABELS.get(action, String(action))

# ---------------------------------------------------------------- profile management

func create_profile(display_name: String) -> String:
	var slug := _make_slug(display_name)
	var p := _new_default_profile(slug)
	p.name = display_name.strip_edges() if display_name.strip_edges() != "" else "Player"
	_profiles_order.append(slug)
	active = p
	_active_slug = slug
	save_active()
	apply_all()
	active_profile_changed.emit()
	return slug

func select_profile(slug: String) -> void:
	if not _profiles_order.has(slug) or slug == _active_slug:
		return
	active = _load_profile(slug)
	_active_slug = slug
	apply_all()
	_save_index()
	active_profile_changed.emit()

func delete_profile(slug: String) -> void:
	if _profiles_order.size() <= 1:
		return  # never delete the last profile
	if not _profiles_order.has(slug):
		return
	DirAccess.remove_absolute(_profile_path(slug))
	_profiles_order.erase(slug)
	if _active_slug == slug:
		active = _load_profile(_profiles_order[0])
		_active_slug = _profiles_order[0]
		apply_all()
		_save_index()
		active_profile_changed.emit()
	else:
		_save_index()

# ---------------------------------------------------------------- persistence

func save_active() -> void:
	if active.is_empty():
		return
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "name", active.name)
	cfg.set_value("profile", "body_color", active.body_color)
	for action: StringName in active.bindings:
		cfg.set_value("bindings", String(action), active.bindings[action])
	var o: Dictionary = active.options
	for k in o.video: cfg.set_value("video", k, o.video[k])
	for k in o.audio: cfg.set_value("audio", k, o.audio[k])
	for k in o.gameplay: cfg.set_value("gameplay", k, o.gameplay[k])
	cfg.save(_profile_path(active.slug))
	_save_index()

func _load_profile(slug: String) -> Dictionary:
	var p := _new_default_profile(slug)
	var cfg := ConfigFile.new()
	if cfg.load(_profile_path(slug)) == OK:
		p.name = cfg.get_value("profile", "name", p.name)
		p.body_color = cfg.get_value("profile", "body_color", p.body_color)
		if cfg.has_section("bindings"):
			for action in cfg.get_section_keys("bindings"):
				p.bindings[StringName(action)] = cfg.get_value("bindings", action, [])
		for section in ["video", "audio", "gameplay"]:
			var dict: Dictionary = p.options[section]
			for k in dict:
				dict[k] = cfg.get_value(section, k, dict[k])
	return p

func _load_index() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(INDEX_PATH) != OK:
		return
	_profiles_order = []
	for s in cfg.get_value("index", "order", []):
		_profiles_order.append(String(s))
	_active_slug = String(cfg.get_value("index", "active", ""))

func _save_index() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("index", "active", _active_slug)
	cfg.set_value("index", "order", _profiles_order)
	cfg.save(INDEX_PATH)

func _profile_path(slug: String) -> String:
	return "%s/%s.cfg" % [PROFILES_DIR, slug]

# ---------------------------------------------------------------- bindings

## Effective events for an action: profile override if present, else snapshot default.
func get_action_events(action: StringName) -> Array:
	if active.has("bindings") and active.bindings.has(action):
		var evs: Array = []
		for d in active.bindings[action]:
			var e := _dict_to_event(d)
			if e != null:
				evs.append(e)
		return evs
	return _default_bindings.get(action, [])

func rebind_action(action: StringName, event: InputEvent) -> void:
	active.bindings[action] = [_event_to_dict(event)]
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)

func reset_action_to_default(action: StringName) -> void:
	active.bindings.erase(action)
	if not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	for e in _default_bindings.get(action, []):
		InputMap.action_add_event(action, e)

func reset_all_bindings() -> void:
	active.bindings.clear()
	_apply_bindings()

func _apply_bindings() -> void:
	for action in REBINDABLE:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for e in get_action_events(action):
			InputMap.action_add_event(action, e)

func _event_to_dict(ev: InputEvent) -> Dictionary:
	if ev is InputEventKey:
		return {"type": "key", "physical_keycode": ev.physical_keycode, "keycode": ev.keycode}
	if ev is InputEventMouseButton:
		return {"type": "mouse", "button_index": ev.button_index}
	return {}

func _dict_to_event(d: Dictionary) -> InputEvent:
	match String(d.get("type", "")):
		"key":
			var e := InputEventKey.new()
			var pk := int(d.get("physical_keycode", 0))
			if pk != 0:
				e.physical_keycode = pk
			else:
				e.keycode = int(d.get("keycode", 0))
			return e
		"mouse":
			var e := InputEventMouseButton.new()
			e.button_index = int(d.get("button_index", MOUSE_BUTTON_LEFT))
			return e
	return null

func event_label(ev: InputEvent) -> String:
	if ev is InputEventKey:
		var pk: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
		return OS.get_keycode_string(pk)
	if ev is InputEventMouseButton:
		match ev.button_index:
			MOUSE_BUTTON_LEFT: return "Mouse Left"
			MOUSE_BUTTON_RIGHT: return "Mouse Right"
			MOUSE_BUTTON_MIDDLE: return "Mouse Middle"
			_: return "Mouse %d" % ev.button_index
	return "?"

# ---------------------------------------------------------------- audio

func set_audio_volume(bus: StringName, linear: float) -> void:
	match bus:
		&"Master": active.options.audio.master = linear
		&"Music": active.options.audio.music = linear
		&"SFX": active.options.audio.sfx = linear
	var idx := _ensure_bus(bus)
	AudioServer.set_bus_volume_db(idx, -80.0 if linear <= 0.001 else linear_to_db(linear))

func _apply_audio() -> void:
	var a: Dictionary = active.options.audio
	set_audio_volume(&"Master", a.master)
	set_audio_volume(&"Music", a.music)
	set_audio_volume(&"SFX", a.sfx)

func _ensure_bus(bus_name: StringName) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, &"Master")
	return idx

# ---------------------------------------------------------------- video

func set_window_mode(mode: int) -> void:
	active.options.video.window_mode = mode
	_apply_video()

func set_vsync(on: bool) -> void:
	active.options.video.vsync = on
	_apply_video()

func set_integer_scaling(on: bool) -> void:
	active.options.video.integer_scaling = on
	_apply_video()

## Front-end scenes call this so Control/UI rasterizes at the real window
## resolution (crisp text at any window size) instead of the 480x270 framebuffer.
func use_ui_presentation() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var w := get_window()
	if w != null:
		w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS

## Gameplay scenes call this to keep the 480x270 pixel-art look (the project default).
func use_game_presentation() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var w := get_window()
	if w != null:
		w.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT

func _apply_video() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var v: Dictionary = active.options.video
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if int(v.window_mode) == 1 else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if v.vsync else DisplayServer.VSYNC_DISABLED)
	var w := get_window()
	if w != null:
		# Project uses stretch mode "viewport"; toggle only the stretch granularity.
		w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		w.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER if v.integer_scaling else Window.CONTENT_SCALE_STRETCH_FRACTIONAL

# ---------------------------------------------------------------- apply / defaults

func apply_all() -> void:
	_apply_bindings()
	_apply_audio()
	_apply_video()

func _new_default_profile(slug: String) -> Dictionary:
	return {
		"slug": slug,
		"name": "Player",
		"body_color": DEFAULT_BODY_COLOR,
		"bindings": {},
		"options": _default_options(),
	}

func _default_options() -> Dictionary:
	return {
		"video": {"window_mode": 0, "vsync": true, "integer_scaling": false},
		"audio": {"master": 1.0, "music": 0.7, "sfx": 1.0},
		"gameplay": {
			"crosshair_style": 0,
			"crosshair_color": Color(1, 1, 1, 1),
			"screen_shake": 1.0,
			"damage_numbers": true,
		},
	}

func _make_slug(display_name: String) -> String:
	var base := display_name.strip_edges().to_lower()
	var s := ""
	for ch in base:
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			s += ch
		else:
			s += "_"
	if s == "":
		s = "profile"
	var unique := s
	var n := 1
	while _profiles_order.has(unique):
		unique = "%s_%d" % [s, n]
		n += 1
	return unique

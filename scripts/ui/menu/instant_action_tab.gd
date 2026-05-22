extends Control
## Instant Action: pick mode/map/bots/difficulty/limits and launch a match.

const ARENA_PATHS := [
	"res://scenes/arenas/arena_01.tscn",
	"res://scenes/arenas/arena_02.tscn",
]
const ARENA_NAMES := ["Foundry", "Vortex"]
const MATCH_SCENE := "res://scenes/main/match.tscn"

func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override(StringName("margin_" + side), 6)
	add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override(&"separation", 3)
	margin.add_child(vb)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 8)
	grid.add_theme_constant_override(&"v_separation", 3)
	vb.add_child(grid)

	var mode := OptionButton.new()
	mode.add_item("Deathmatch")
	mode.disabled = true  # only mode for now
	_row(grid, "Game Mode", mode)

	var map := OptionButton.new()
	for i in ARENA_NAMES.size():
		map.add_item(ARENA_NAMES[i], i)
	var cur := ARENA_PATHS.find(GameState.selected_arena_path)
	map.selected = cur if cur >= 0 else 0
	map.item_selected.connect(func(idx: int) -> void:
		GameState.selected_arena_path = ARENA_PATHS[idx])
	_row(grid, "Map", map)

	var bots := SpinBox.new()
	bots.min_value = 1
	bots.max_value = 6
	bots.value = clampi(GameState.bot_count, 1, 6)
	bots.value_changed.connect(func(v: float) -> void:
		GameState.bot_count = int(v))
	_row(grid, "Bots", bots)

	var diff := OptionButton.new()
	for n in ["Easy", "Normal", "Hard", "Insane"]:
		diff.add_item(n)
	diff.selected = int(GameState.difficulty)
	diff.item_selected.connect(func(idx: int) -> void:
		GameState.difficulty = idx as GameState.Difficulty)
	_row(grid, "Difficulty", diff)

	var frag := SpinBox.new()
	frag.min_value = 0
	frag.max_value = 100
	frag.value = GameState.frag_limit
	frag.value_changed.connect(func(v: float) -> void:
		GameState.frag_limit = int(v))
	_row(grid, "Frag Limit (0 = none)", frag)

	var tlimit := SpinBox.new()
	tlimit.min_value = 0
	tlimit.max_value = 3600
	tlimit.step = 30
	tlimit.value = GameState.time_limit_seconds
	tlimit.value_changed.connect(func(v: float) -> void:
		GameState.time_limit_seconds = float(v))
	_row(grid, "Time Limit s (0 = none)", tlimit)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 4
	vb.add_child(spacer)

	var start := Button.new()
	start.text = "Start Match"
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(MATCH_SCENE))
	vb.add_child(start)
	start.grab_focus.call_deferred()

func _row(grid: GridContainer, label_text: String, control: Control) -> void:
	var label := Label.new()
	label.text = label_text
	grid.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.custom_minimum_size.x = 110
	grid.add_child(control)

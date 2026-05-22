extends Control

const MATCH_SCENE_PATH := "res://scenes/main/match.tscn"
const SANDBOX_SCENE_PATH := "res://scenes/main/dev_test.tscn"

const ARENA_PATHS := [
	"res://scenes/arenas/arena_01.tscn",
	"res://scenes/arenas/arena_02.tscn",
]
const ARENA_NAMES := ["Foundry", "Vortex"]

@onready var _difficulty: OptionButton = $VBox/Difficulty
@onready var _arena_picker: OptionButton = $VBox/Arena

func _ready() -> void:
	$VBox/StartButton.pressed.connect(_on_start)
	$VBox/SandboxButton.pressed.connect(_on_sandbox)
	$VBox/QuitButton.pressed.connect(_on_quit)
	_difficulty.item_selected.connect(_on_difficulty_changed)
	_arena_picker.item_selected.connect(_on_arena_changed)
	# Populate arena picker
	_arena_picker.clear()
	for i in ARENA_NAMES.size():
		_arena_picker.add_item(ARENA_NAMES[i], i)
	# Reflect current state
	_difficulty.selected = int(GameState.difficulty)
	var current_idx: int = ARENA_PATHS.find(GameState.selected_arena_path)
	_arena_picker.selected = current_idx if current_idx >= 0 else 0
	$VBox/StartButton.grab_focus()

func _on_difficulty_changed(idx: int) -> void:
	GameState.difficulty = idx as GameState.Difficulty

func _on_arena_changed(idx: int) -> void:
	GameState.selected_arena_path = ARENA_PATHS[idx]

func _on_start() -> void:
	get_tree().change_scene_to_file(MATCH_SCENE_PATH)

func _on_sandbox() -> void:
	get_tree().change_scene_to_file(SANDBOX_SCENE_PATH)

func _on_quit() -> void:
	get_tree().quit()

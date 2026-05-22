extends Control

const MATCH_PATH := "res://scenes/main/match.tscn"
const MENU_PATH := "res://scenes/main/main_menu.tscn"

func _ready() -> void:
	Profiles.use_ui_presentation()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$VBox/PlayAgain.pressed.connect(_on_play_again)
	$VBox/Menu.pressed.connect(_on_menu)
	$VBox/Quit.pressed.connect(_on_quit)
	$VBox/PlayAgain.grab_focus()
	_fill_scoreboard()

func _fill_scoreboard() -> void:
	var scoreboard: VBoxContainer = $Scoreboard
	for child in scoreboard.get_children():
		child.queue_free()
	# Sort ids by score
	var ids: Array = GameState.scores.keys()
	ids.sort_custom(func(a, b): return GameState.scores[a] > GameState.scores[b])
	var winner_id: StringName = ids[0] if not ids.is_empty() else &""
	for id in ids:
		var l := Label.new()
		var prefix: String = "★ " if id == winner_id else "  "
		l.text = "%s%s — %d frags" % [prefix, String(id), GameState.scores[id]]
		scoreboard.add_child(l)

func _on_play_again() -> void:
	get_tree().change_scene_to_file(MATCH_PATH)

func _on_menu() -> void:
	get_tree().change_scene_to_file(MENU_PATH)

func _on_quit() -> void:
	get_tree().quit()

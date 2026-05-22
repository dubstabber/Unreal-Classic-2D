extends Node2D
## Production match scene. Loads the selected arena (which provides geometry,
## nav nodes, player starts, and pickups), then spawns the player + bot and
## runs the MatchDirector.

const PAWN_SCENE := preload("res://scenes/pawn/pawn.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const RESULTS_PATH := "res://scenes/main/results.tscn"

const ENFORCER_DATA := preload("res://resources/weapons/enforcer.tres")

## Distinct tints so each bot is visually distinguishable (cycled by bot index).
const BOT_TINTS: Array[Color] = [
	Color(1.00, 0.55, 0.55, 1), Color(0.55, 1.00, 0.60, 1), Color(0.65, 0.70, 1.00, 1),
	Color(1.00, 0.85, 0.45, 1), Color(0.85, 0.55, 1.00, 1), Color(0.55, 0.95, 1.00, 1),
]

var _arena: Arena
var _director: MatchDirector
var _nav_graph: NavGraph
var _player: Pawn
var _bots: Array[Pawn] = []
var _hud: HUD

func _ready() -> void:
	Profiles.use_game_presentation()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_load_arena()
	_setup_nav_graph()
	var spawns: Array[Vector2] = _gather_spawn_points()
	_spawn_player(spawns[0] if spawns.size() > 0 else Vector2(80, 188))
	var bot_count: int = maxi(0, GameState.bot_count)
	for i in bot_count:
		var at: Vector2 = _bot_spawn(spawns, i)
		_spawn_bot(i, at)
	_setup_director()
	_setup_hud()
	EventBus.pawn_killed.connect(_on_any_pawn_killed)
	GameState.match_ended.connect(_on_match_ended)
	_director.start_match()

func _load_arena() -> void:
	var path: String = GameState.selected_arena_path
	if not ResourceLoader.exists(path):
		path = "res://scenes/arenas/arena_01.tscn"
	var packed: PackedScene = load(path) as PackedScene
	_arena = packed.instantiate() as Arena
	add_child(_arena)

func _setup_nav_graph() -> void:
	_nav_graph = NavGraph.new()
	_nav_graph.require_los = false
	add_child(_nav_graph)

func _gather_spawn_points() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for n in get_tree().get_nodes_in_group(&"player_start"):
		if n is Marker2D:
			result.append((n as Marker2D).global_position)
	result.shuffle()
	return result

## Pick a spawn marker for bot index `i`: skip the player's marker (index 0),
## cycle through the rest, fall back to a fixed point when none are available.
func _bot_spawn(spawns: Array[Vector2], i: int) -> Vector2:
	if spawns.size() <= 1:
		return Vector2(400, 188)
	return spawns[1 + (i % (spawns.size() - 1))]

func _spawn_player(at: Vector2) -> void:
	_player = PAWN_SCENE.instantiate()
	_player.id = &"player"
	_player.display_name = Profiles.player_name()
	add_child(_player)
	# Rig is built in Pawn._ready() on tree entry, so tint after add_child.
	var tint: Color = Profiles.player_color()
	_player.set_team_color(tint)
	_player.set_controller(PlayerController.new())
	var cam := CameraRig.new()
	# Clamp camera to arena bounds (480x270 base resolution)
	cam.limit_left = 0
	cam.limit_right = Arena.VIEWPORT_W
	cam.limit_top = 0
	cam.limit_bottom = Arena.VIEWPORT_H
	_player.add_child(cam)
	var enforcer := Enforcer.new()
	enforcer.data = ENFORCER_DATA
	_player.equip_weapon(enforcer)
	_player.global_position = at
	# "This is you" arrow above the local player on spawn + each respawn.
	var indicator := SpawnIndicator.new()
	indicator.color = tint
	_player.add_child(indicator)
	indicator.show_for(2.5)
	_player.respawned.connect(func() -> void: indicator.show_for(2.5))

func _spawn_bot(index: int, at: Vector2) -> void:
	var bot: Pawn = PAWN_SCENE.instantiate()
	bot.id = StringName("bot_%d" % index)
	bot.display_name = "Bot %d" % (index + 1)
	add_child(bot)
	bot.global_position = at
	var tint: Color = BOT_TINTS[index % BOT_TINTS.size()]
	bot.set_team_color(tint)
	var bc := BotController.new()
	bot.set_controller(bc)
	bc.set_nav_graph(_nav_graph)
	var enforcer := Enforcer.new()
	enforcer.data = ENFORCER_DATA
	bot.equip_weapon(enforcer)
	_bots.append(bot)

func _setup_director() -> void:
	_director = MatchDirector.new()
	_director.frag_limit = GameState.frag_limit if GameState.frag_limit > 0 else 10
	_director.time_limit_seconds = GameState.time_limit_seconds
	_director.respawn_delay = 1.5
	add_child(_director)
	_director.auto_register_starts(self)

func _setup_hud() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	_hud.bind(_player)

func _on_any_pawn_killed(victim: Pawn, killer: Node) -> void:
	if killer == _player and victim != _player and Profiles.gameplay().get("damage_numbers", true):
		FloatingText.spawn(self, _player.global_position + Vector2(0, -18), "+1",
			Color(0.4, 0.95, 0.5, 1))

func _on_match_ended(_winner: StringName) -> void:
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		get_tree().change_scene_to_file(RESULTS_PATH))

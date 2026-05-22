extends Node2D
## Production match scene. Loads the selected arena (which provides geometry,
## nav nodes, player starts, and pickups), then spawns the player + bot and
## runs the MatchDirector.

const PAWN_SCENE := preload("res://scenes/pawn/pawn.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const RESULTS_PATH := "res://scenes/main/results.tscn"

const SHOCK_DATA := preload("res://resources/weapons/shock_rifle.tres")
const ROCKET_DATA := preload("res://resources/weapons/rocket_launcher.tres")
const FLAK_DATA := preload("res://resources/weapons/flak_cannon.tres")
const SNIPER_DATA := preload("res://resources/weapons/sniper_rifle.tres")
const BIO_DATA := preload("res://resources/weapons/bio_rifle.tres")
const ENFORCER_DATA := preload("res://resources/weapons/enforcer.tres")
const HAMMER_DATA := preload("res://resources/weapons/impact_hammer.tres")

var _arena: Arena
var _director: MatchDirector
var _nav_graph: NavGraph
var _player: Pawn
var _bot: Pawn
var _hud: HUD

func _ready() -> void:
	_load_arena()
	_setup_nav_graph()
	var spawns: Array[Vector2] = _gather_spawn_points()
	_spawn_player(spawns[0] if spawns.size() > 0 else Vector2(80, 188))
	_spawn_bot(spawns[1] if spawns.size() > 1 else Vector2(400, 188))
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

func _spawn_player(at: Vector2) -> void:
	_player = PAWN_SCENE.instantiate()
	_player.id = &"player"
	_player.display_name = "Player"
	add_child(_player)
	_player.set_controller(PlayerController.new())
	var cam := CameraRig.new()
	# Clamp camera to arena bounds (480x270 base resolution)
	cam.limit_left = 0
	cam.limit_right = Arena.VIEWPORT_W
	cam.limit_top = 0
	cam.limit_bottom = Arena.VIEWPORT_H
	_player.add_child(cam)
	var hammer := ImpactHammer.new()
	hammer.data = HAMMER_DATA
	_player.equip_weapon(hammer)
	var enforcer := Enforcer.new()
	enforcer.data = ENFORCER_DATA
	_player.equip_weapon(enforcer)
	_player.global_position = at

func _spawn_bot(at: Vector2) -> void:
	_bot = PAWN_SCENE.instantiate()
	_bot.id = &"opponent"
	_bot.display_name = "Bot"
	add_child(_bot)
	_bot.global_position = at
	for spr in [_bot.get_node_or_null("Visual/Body"), _bot.get_node_or_null("Visual/Head")]:
		if spr != null:
			spr.modulate = Color(1.0, 0.55, 0.55, 1.0)
	var bc := BotController.new()
	_bot.set_controller(bc)
	bc.set_nav_graph(_nav_graph)
	var hammer := ImpactHammer.new()
	hammer.data = HAMMER_DATA
	_bot.equip_weapon(hammer)
	var enforcer := Enforcer.new()
	enforcer.data = ENFORCER_DATA
	_bot.equip_weapon(enforcer)
	var shock := ShockRifle.new()
	shock.data = SHOCK_DATA
	_bot.equip_weapon(shock)
	var flak := FlakCannon.new()
	flak.data = FLAK_DATA
	_bot.equip_weapon(flak)
	var rocket := RocketLauncher.new()
	rocket.data = ROCKET_DATA
	_bot.equip_weapon(rocket)
	var sniper := SniperRifle.new()
	sniper.data = SNIPER_DATA
	_bot.equip_weapon(sniper)

func _setup_director() -> void:
	_director = MatchDirector.new()
	_director.frag_limit = GameState.frag_limit if GameState.frag_limit > 0 else 10
	_director.respawn_delay = 1.5
	add_child(_director)
	_director.auto_register_starts(self)

func _setup_hud() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	_hud.bind(_player)

func _on_any_pawn_killed(victim: Pawn, killer: Node) -> void:
	if killer == _player and victim != _player:
		FloatingText.spawn(self, _player.global_position + Vector2(0, -18), "+1",
			Color(0.4, 0.95, 0.5, 1))

func _on_match_ended(_winner: StringName) -> void:
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		get_tree().change_scene_to_file(RESULTS_PATH))

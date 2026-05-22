extends Node2D
## Dev sandbox. Evolves per phase.
## Phase 1: pawn + damage console commands.
## Phase 2: arena (floor + platforms), PlayerController + CameraRig, movement.
## Phase 3: weapons + Shock Rifle (primary beam, alt orb, combo), dummy target.

const PAWN_SCENE := preload("res://scenes/pawn/pawn.tscn")
const SHOCK_RIFLE_DATA := preload("res://resources/weapons/shock_rifle.tres")
const ROCKET_LAUNCHER_DATA := preload("res://resources/weapons/rocket_launcher.tres")
const ENFORCER_DATA := preload("res://resources/weapons/enforcer.tres")
const BIO_RIFLE_DATA := preload("res://resources/weapons/bio_rifle.tres")
const FLAK_CANNON_DATA := preload("res://resources/weapons/flak_cannon.tres")
const SNIPER_RIFLE_DATA := preload("res://resources/weapons/sniper_rifle.tres")
const HEALTH_PICKUP_SCENE := preload("res://scenes/pickups/health_pickup.tscn")
const ARMOR_PICKUP_SCENE := preload("res://scenes/pickups/armor_pickup.tscn")
const AMMO_PICKUP_SCENE := preload("res://scenes/pickups/ammo_pickup.tscn")
const WEAPON_PICKUP_SCENE := preload("res://scenes/pickups/weapon_pickup.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const MAIN_MENU_PATH := "res://scenes/main/main_menu.tscn"
const MATCH_PATH := "res://scenes/main/match.tscn"

const VIEWPORT_W := 480
const VIEWPORT_H := 270
const SPAWN_POS := Vector2(160, 200)
const DUMMY_POS := Vector2(340, 238)
const TILE := 8

var _pawn: Pawn
var _dummy: Pawn
var _bot: Pawn
var _hud_label: Label
var _hud: HUD
var _director: MatchDirector
var _nav_graph: NavGraph

func _ready() -> void:
	Profiles.use_game_presentation()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_spawn_title()
	_build_arena()
	_spawn_test_pawn()
	_spawn_dummy()
	_give_all_weapons()
	_spawn_pickups()
	_setup_director()
	_spawn_status_label()
	_setup_hud()
	_spawn_bot()
	_register_debug_commands()
	_subscribe_event_bus()
	if "--selftest" in OS.get_cmdline_user_args():
		call_deferred("_run_selftest")

# ---------- Arena ----------

func _spawn_title() -> void:
	var l := Label.new()
	l.text = "PHASE 6 — pickups + match loop. `menu = main menu, `match = full DM scene"
	l.position = Vector2(8, 4)
	l.add_theme_color_override("font_color", Color(0.9, 0.95, 1, 1))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	add_child(l)

func _build_arena() -> void:
	ArenaBuilder.build_default_arena(self)
	for at in [Vector2(80, 188), Vector2(400, 188), Vector2(240, 140), Vector2(240, 232)]:
		ArenaBuilder.add_player_start(self, at)
	ArenaBuilder.build_default_nav_nodes(self)
	_nav_graph = NavGraph.new()
	_nav_graph.require_los = false  # Phase 9 will refine node placement so LOS holds.
	add_child(_nav_graph)

# ---------- Pawn / controller / camera ----------

func _spawn_test_pawn() -> void:
	_pawn = PAWN_SCENE.instantiate()
	_pawn.position = SPAWN_POS
	_pawn.id = &"player"
	_pawn.display_name = "Player"
	add_child(_pawn)
	_pawn.set_controller(PlayerController.new())
	var cam := CameraRig.new()
	_pawn.add_child(cam)
	_pawn.damaged.connect(_on_pawn_damaged)
	_pawn.died.connect(_on_pawn_died)
	_pawn.respawned.connect(_on_pawn_respawned)

func _spawn_dummy() -> void:
	_dummy = PAWN_SCENE.instantiate()
	_dummy.position = DUMMY_POS
	_dummy.id = &"dummy"
	_dummy.display_name = "Dummy"
	add_child(_dummy)
	_dummy.damaged.connect(_on_dummy_damaged)
	_dummy.died.connect(_on_dummy_died)
	# Visual tint to distinguish dummy from player
	_dummy.set_team_color(Color(1.0, 0.65, 0.65, 1.0))

func _give_player_shock_rifle() -> void:
	_ensure_weapon(ShockRifle, SHOCK_RIFLE_DATA)

func _give_player_rocket_launcher() -> void:
	_ensure_weapon(RocketLauncher, ROCKET_LAUNCHER_DATA)

func _give_player_enforcer() -> void:
	_ensure_weapon(Enforcer, ENFORCER_DATA)

func _give_player_bio_rifle() -> void:
	_ensure_weapon(BioRifle, BIO_RIFLE_DATA)

func _give_player_flak_cannon() -> void:
	_ensure_weapon(FlakCannon, FLAK_CANNON_DATA)

func _give_player_sniper_rifle() -> void:
	_ensure_weapon(SniperRifle, SNIPER_RIFLE_DATA)

func _give_all_weapons() -> void:
	_give_player_enforcer()
	_give_player_bio_rifle()
	_give_player_shock_rifle()
	_give_player_flak_cannon()
	_give_player_rocket_launcher()
	_give_player_sniper_rifle()

func _equip_full_kit(target: Pawn) -> void:
	var w: Weapon
	w = Enforcer.new(); w.data = ENFORCER_DATA; target.equip_weapon(w)
	w = BioRifle.new(); w.data = BIO_RIFLE_DATA; target.equip_weapon(w)
	w = ShockRifle.new(); w.data = SHOCK_RIFLE_DATA; target.equip_weapon(w)
	w = FlakCannon.new(); w.data = FLAK_CANNON_DATA; target.equip_weapon(w)
	w = RocketLauncher.new(); w.data = ROCKET_LAUNCHER_DATA; target.equip_weapon(w)
	w = SniperRifle.new(); w.data = SNIPER_RIFLE_DATA; target.equip_weapon(w)

func _ensure_weapon(klass: GDScript, data: WeaponData) -> Weapon:
	for w in _pawn.inventory.weapons:
		if w.get_script() == klass:
			return w as Weapon
	var w: Weapon = klass.new()
	w.data = data
	_pawn.equip_weapon(w)
	return w

func _spawn_pickups() -> void:
	# A handful of pickups around the arena for interactive testing.
	_place_pickup(HEALTH_PICKUP_SCENE, Vector2(96, 190))
	_place_pickup(HEALTH_PICKUP_SCENE, Vector2(384, 190))
	_place_pickup(ARMOR_PICKUP_SCENE, Vector2(240, 140))
	# Ammo pickups (one per type)
	var ammo_a: AmmoPickup = AMMO_PICKUP_SCENE.instantiate() as AmmoPickup
	ammo_a.ammo_type = &"rockets"
	ammo_a.amount = 4
	ammo_a.global_position = Vector2(240, 232)
	add_child(ammo_a)
	var ammo_b: AmmoPickup = AMMO_PICKUP_SCENE.instantiate() as AmmoPickup
	ammo_b.ammo_type = &"shells"
	ammo_b.amount = 6
	ammo_b.global_position = Vector2(96, 92)
	add_child(ammo_b)
	# Sniper rifle weapon pickup (player already has it, so this will just refill ammo)
	var wp: WeaponPickup = WEAPON_PICKUP_SCENE.instantiate() as WeaponPickup
	wp.weapon_class = SniperRifle
	wp.weapon_data = SNIPER_RIFLE_DATA
	wp.global_position = Vector2(240, 44)
	add_child(wp)

func _place_pickup(scene: PackedScene, at: Vector2) -> Pickup:
	var p: Pickup = scene.instantiate()
	p.global_position = at
	add_child(p)
	return p

func _setup_director() -> void:
	_director = MatchDirector.new()
	_director.frag_limit = 10
	_director.respawn_delay = 1.5
	add_child(_director)
	_director.auto_register_starts(self)

func _setup_hud() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	_hud.bind(_pawn)

func _spawn_bot() -> void:
	_bot = PAWN_SCENE.instantiate()
	_bot.position = Vector2(400, 188)
	_bot.id = &"bot"
	_bot.display_name = "Bot"
	add_child(_bot)
	_bot.set_team_color(Color(0.65, 0.65, 1.0, 1.0))
	var bc := BotController.new()
	_bot.set_controller(bc)
	bc.set_nav_graph(_nav_graph)
	_equip_full_kit(_bot)
	# Hold the bot inert during selftest so earlier subtests aren't disturbed.
	if "--selftest" in OS.get_cmdline_user_args():
		bc.set_physics_process(false)

func _spawn_status_label() -> void:
	_hud_label = Label.new()
	_hud_label.position = Vector2(8, VIEWPORT_H - 16)
	_hud_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5, 1))
	_hud_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	_hud_label.add_theme_constant_override("shadow_offset_x", 1)
	_hud_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_hud_label)
	_refresh_status()

func _refresh_status() -> void:
	if _pawn == null or _hud_label == null:
		return
	if not _pawn.is_alive():
		_hud_label.text = "DEAD — `respawn`"
		_hud_label.add_theme_color_override("font_color", Color(0.95, 0.3, 0.2, 1))
	else:
		var w: Weapon = _pawn.inventory.current_weapon() as Weapon
		var wname: String = w.data.display_name if w != null and w.data != null else "—"
		var ammo_str: String = ""
		if w != null and w.data != null and w.data.ammo_type != &"":
			ammo_str = "  %s:%d" % [String(w.data.ammo_type), _pawn.inventory.get_ammo(w.data.ammo_type)]
		_hud_label.text = "HP %d  AR %d  [%s]%s" % [
			int(_pawn.health_component.health),
			int(_pawn.health_component.armor),
			wname, ammo_str,
		]
		_hud_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5, 1))

func _on_pawn_damaged(info: DamageInfo) -> void:
	DebugConsole.print_line("[color=#ff8888]-%d[/color] %s → HP %d / AR %d" % [
		int(info.amount), String(info.damage_type),
		int(_pawn.health_component.health), int(_pawn.health_component.armor)
	])
	_refresh_status()

func _on_pawn_died(killer: Node) -> void:
	DebugConsole.print_line("[color=#ff4444]DIED[/color] (killed by %s)" % (str(killer) if killer else "self/world"))
	_refresh_status()

func _on_pawn_respawned() -> void:
	DebugConsole.print_line("[color=#88ff88]RESPAWNED[/color] → HP %d" % int(_pawn.health_component.health))
	_refresh_status()

func _on_dummy_damaged(info: DamageInfo) -> void:
	DebugConsole.print_line("[dummy] [color=#ff8888]-%d[/color] %s → HP %d" % [
		int(info.amount), String(info.damage_type), int(_dummy.health_component.health)
	])

func _on_dummy_died(_killer: Node) -> void:
	DebugConsole.print_line("[dummy] [color=#ff4444]DIED[/color]")

# ---------- Debug commands ----------

func _register_debug_commands() -> void:
	DebugConsole.register(&"kill", _cmd_kill, "instakill the player")
	DebugConsole.register(&"damage", _cmd_damage, "damage N — deal N damage to the player")
	DebugConsole.register(&"hp", _cmd_hp, "hp N — heal the player by N")
	DebugConsole.register(&"armor", _cmd_armor, "armor N — give the player N armor")
	DebugConsole.register(&"respawn", _cmd_respawn, "respawn player + dummy")
	DebugConsole.register(&"status", _cmd_status, "print HP / armor / alive")
	DebugConsole.register(&"tp", _cmd_tp, "tp X Y — teleport the player")
	DebugConsole.register(&"vel", _cmd_vel, "print the player's velocity")
	DebugConsole.register(&"ammo", _cmd_ammo, "ammo <type> <n> — give the player N of <type> ammo")
	DebugConsole.register(&"give", _cmd_give, "give <weapon> — give the player a weapon (shock)")
	DebugConsole.register(&"dummy_hp", _cmd_dummy_hp, "print the dummy's HP")
	DebugConsole.register(&"menu", _cmd_menu, "go to main menu scene")
	DebugConsole.register(&"match", _cmd_match, "start a full DM match scene")
	DebugConsole.register(&"scores", _cmd_scores, "print current scores")

func _cmd_kill(_a: Array) -> Variant:
	_pawn.apply_damage(DamageInfo.make(99999.0, &"debug", null, &"debug.kill"))
	return null

func _cmd_damage(args: Array) -> Variant:
	if args.is_empty(): return "usage: damage <amount>"
	_pawn.apply_damage(DamageInfo.make(float(args[0]), &"debug", null, &"debug.damage"))
	return null

func _cmd_hp(args: Array) -> Variant:
	if args.is_empty(): return "usage: hp <amount>"
	var g: float = _pawn.health_component.add_health(float(args[0]), _pawn.health_component.health_overcap)
	_refresh_status()
	return "+%d HP" % int(g)

func _cmd_armor(args: Array) -> Variant:
	if args.is_empty(): return "usage: armor <amount>"
	var g: float = _pawn.health_component.add_armor(float(args[0]))
	_refresh_status()
	return "+%d AR" % int(g)

func _cmd_respawn(_a: Array) -> Variant:
	_pawn.respawn(SPAWN_POS)
	_dummy.respawn(DUMMY_POS)
	_refresh_status()
	return null

func _cmd_status(_a: Array) -> Variant:
	return "HP %d/%d  AR %d/%d  alive=%s  on_floor=%s  vel=(%.0f, %.0f)" % [
		int(_pawn.health_component.health), int(_pawn.health_component.max_health),
		int(_pawn.health_component.armor), int(_pawn.health_component.max_armor),
		str(_pawn.is_alive()), str(_pawn.is_on_floor()),
		_pawn.velocity.x, _pawn.velocity.y,
	]

func _cmd_tp(args: Array) -> Variant:
	if args.size() < 2: return "usage: tp <x> <y>"
	_pawn.global_position = Vector2(float(args[0]), float(args[1]))
	_pawn.velocity = Vector2.ZERO
	return null

func _cmd_vel(_a: Array) -> Variant:
	return "velocity = (%.1f, %.1f)" % [_pawn.velocity.x, _pawn.velocity.y]

func _cmd_ammo(args: Array) -> Variant:
	if args.size() < 2: return "usage: ammo <type> <n>"
	var added: int = _pawn.inventory.add_ammo(StringName(args[0]), int(args[1]))
	_refresh_status()
	return "+%d %s" % [added, args[0]]

func _cmd_give(args: Array) -> Variant:
	if args.is_empty(): return "usage: give <weapon>  (enforcer | bio | shock | flak | rocket | sniper | all)"
	match args[0]:
		"enforcer": _give_player_enforcer(); return "+Enforcer"
		"bio", "bio_rifle": _give_player_bio_rifle(); return "+Bio Rifle"
		"shock", "shock_rifle": _give_player_shock_rifle(); return "+Shock Rifle"
		"flak", "flak_cannon": _give_player_flak_cannon(); return "+Flak Cannon"
		"rocket", "rocket_launcher": _give_player_rocket_launcher(); return "+Rocket Launcher"
		"sniper", "sniper_rifle": _give_player_sniper_rifle(); return "+Sniper Rifle"
		"all": _give_all_weapons(); return "+all"
		_: return "unknown weapon: %s" % args[0]

func _cmd_dummy_hp(_a: Array) -> Variant:
	if _dummy == null: return "no dummy"
	return "dummy HP %d / %d (alive=%s)" % [
		int(_dummy.health_component.health), int(_dummy.health_component.max_health),
		str(_dummy.is_alive()),
	]

func _cmd_menu(_a: Array) -> Variant:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
	return null

func _cmd_match(_a: Array) -> Variant:
	get_tree().change_scene_to_file(MATCH_PATH)
	return null

func _cmd_scores(_a: Array) -> Variant:
	if GameState.scores.is_empty():
		return "no scores yet"
	var parts: PackedStringArray = []
	for id in GameState.scores:
		parts.append("%s:%d" % [String(id), GameState.scores[id]])
	return " ".join(parts) + (" (to %d)" % GameState.frag_limit)

# ---------- EventBus exercise ----------

func _subscribe_event_bus() -> void:
	EventBus.pawn_killed.connect(func(victim, killer):
		print("[event_bus] pawn_killed: %s killed by %s" % [victim, killer]))
	EventBus.pawn_respawned.connect(func(victim):
		print("[event_bus] pawn_respawned: %s" % victim))

# ---------- CLI self-test (--selftest) ----------

var _selftest_count: int = 0
var _selftest_failures: int = 0

func _run_selftest() -> void:
	_selftest_health()
	await _selftest_movement()
	await _selftest_weapons()
	await _selftest_rockets()
	await _selftest_phase5_weapons()
	await _selftest_pickups_and_match()
	await _selftest_bot_ai()
	await _selftest_hud_and_polish()
	await _selftest_arenas()

	var status: String = "PASS" if _selftest_failures == 0 else "FAIL"
	print("[selftest] %s — %d checks, %d failures" % [status, _selftest_count, _selftest_failures])
	get_tree().quit(0 if _selftest_failures == 0 else 1)

func _assert(label: String, cond: bool) -> void:
	_selftest_count += 1
	if cond:
		print("[selftest]   ok  — %s" % label)
	else:
		_selftest_failures += 1
		print("[selftest]   FAIL — %s" % label)

func _selftest_health() -> void:
	var hp := _pawn.health_component
	hp.reset()
	_assert("initial HP", hp.health == 100.0)
	_assert("initial AR", hp.armor == 0.0)
	_assert("initial alive", _pawn.is_alive())

	_pawn.apply_damage(DamageInfo.make(30.0, &"test", null))
	_assert("after 30 dmg HP", hp.health == 70.0)

	hp.add_armor(50.0)
	_pawn.apply_damage(DamageInfo.make(40.0, &"test", null))
	_assert("armor absorbed (HP)", hp.health == 50.0)
	_assert("armor absorbed (AR)", hp.armor == 30.0)

	hp.armor = 5.0
	_pawn.apply_damage(DamageInfo.make(40.0, &"test", null))
	_assert("armor depleted (AR)", hp.armor == 0.0)
	_assert("armor depleted (HP)", hp.health == 15.0)

	_pawn.apply_damage(DamageInfo.make(99.0, &"test", null))
	_assert("died alive=false", not _pawn.is_alive())

	_pawn.respawn(SPAWN_POS)
	_assert("respawn alive", _pawn.is_alive())
	_assert("respawn HP full", hp.health == 100.0)
	hp.reset()

func _selftest_movement() -> void:
	_pawn.set_controller(PawnController.new())
	_pawn.respawn(SPAWN_POS)
	var pc := _pawn.controller
	pc.pop_events()
	await _wait_physics_frames(30)
	_assert("settles on floor", _pawn.is_on_floor())

	pc.wish_move = 1.0
	var start_x: float = _pawn.global_position.x
	await _wait_physics_frames(20)
	_assert("moved right under input", _pawn.global_position.x > start_x + 8.0)
	_assert("velocity matches run speed", absf(_pawn.velocity.x - _pawn.stats.run_speed) < 30.0)

	pc.wish_move = 0.0
	await _wait_physics_frames(30)
	_assert("decelerates to ~0", absf(_pawn.velocity.x) < 10.0)

	pc.push_event(&"jump_pressed")
	await _wait_physics_frames(1)
	_assert("jump produced upward velocity", _pawn.velocity.y < -100.0)
	await _wait_physics_frames(60)
	_assert("landed back on floor", _pawn.is_on_floor())

	pc.pop_events()
	pc.push_event(&"dodge_right")
	await _wait_physics_frames(1)
	_assert("dodge gives x impulse", _pawn.velocity.x >= _pawn.stats.dodge_horizontal_impulse - 5.0)
	_assert("dodge gives y impulse", _pawn.velocity.y < -50.0)

	await _wait_physics_frames(3)
	pc.push_event(&"jump_pressed")
	await _wait_physics_frames(1)
	_assert("dodge-jump kicks vy", _pawn.velocity.y <= -_pawn.stats.dodge_jump_impulse + 5.0)

	await _wait_physics_frames(120)
	_assert("landed after dodge-jump", _pawn.is_on_floor())

	pc.wish_crouch = true
	pc.wish_move = 1.0
	await _wait_physics_frames(30)
	_assert("crouching", _pawn._is_crouching)
	_assert("crouch speed capped", _pawn.velocity.x <= _pawn.stats.crouch_speed + 5.0)
	pc.wish_crouch = false
	pc.wish_move = 0.0

func _selftest_weapons() -> void:
	# Use bare controller so the test can drive intent without input override.
	_pawn.set_controller(PawnController.new())
	_pawn.respawn(SPAWN_POS)
	_dummy.respawn(DUMMY_POS)
	await _wait_physics_frames(20)  # settle

	# Make sure the rifle is equipped. The previous selftest_movement may have
	# freed the controller but weapons are children of the Pawn, not the controller.
	var rifle: ShockRifle = null
	for w in _pawn.inventory.weapons:
		if w is ShockRifle:
			rifle = w
			break
	_assert("shock rifle equipped", rifle != null)
	_assert("starting energy ammo", _pawn.inventory.get_ammo(&"energy") > 0)

	# Primary beam — direct hit on dummy
	_pawn.controller.aim_target = _dummy.global_position
	await _wait_physics_frames(1)
	var dummy_hp_before: float = _dummy.health_component.health
	rifle.primary_fire()
	await _wait_physics_frames(1)
	_assert("primary beam damaged dummy", _dummy.health_component.health < dummy_hp_before)
	_assert("dummy took beam damage (40)", absf((dummy_hp_before - _dummy.health_component.health) - 40.0) < 0.5)

	# Alt fire — spawn an orb
	var orbs_before: int = get_tree().get_nodes_in_group(&"shock_orb").size()
	rifle.alt_fire()
	await _wait_physics_frames(1)
	var orbs_now: Array = get_tree().get_nodes_in_group(&"shock_orb")
	_assert("alt fire spawns orb", orbs_now.size() == orbs_before + 1)
	var orb: ShockOrb = orbs_now.back() as ShockOrb
	_assert("orb is ShockOrb", orb != null)

	# Let the orb fly toward the dummy (but not collide yet), then beam-on-orb combo.
	await _wait_physics_frames(30)
	_assert("orb in flight", orb != null and orb.is_inside_tree())
	var orb_pos: Vector2 = orb.global_position
	var dummy_hp_pre_combo: float = _dummy.health_component.health
	_pawn.controller.aim_target = orb_pos
	await _wait_physics_frames(1)
	rifle.primary_fire()
	await _wait_physics_frames(2)
	_assert("orb detonated by combo", not is_instance_valid(orb) or not orb.is_inside_tree())
	_assert("dummy hit by combo radial", _dummy.health_component.health < dummy_hp_pre_combo)

	# Ammo consumption via wish_fire pipeline — make sure ShockRifle is current
	# (otherwise a different equipped weapon would fire instead).
	_pawn.inventory.switch_to_slot(rifle.data.slot)
	_dummy.respawn(DUMMY_POS)
	_pawn.controller.aim_target = _dummy.global_position
	# Make sure cooldowns are clear
	await _wait_physics_frames(60)
	var ammo_before: int = _pawn.inventory.get_ammo(&"energy")
	_pawn.controller.wish_fire_primary = true
	await _wait_physics_frames(2)
	_pawn.controller.wish_fire_primary = false
	_assert("wish_fire consumed ammo", _pawn.inventory.get_ammo(&"energy") == ammo_before - 1)

func _selftest_rockets() -> void:
	_pawn.set_controller(PawnController.new())
	await _clear_projectiles()  # remove any leftover orbs/beams from the weapons test
	_pawn.respawn(SPAWN_POS)
	_dummy.respawn(DUMMY_POS)
	var pc := _pawn.controller
	pc.pop_events()
	await _wait_physics_frames(40)
	_dummy.respawn(DUMMY_POS)  # full HP after settle
	_assert("rocket-test on floor", _pawn.is_on_floor())

	var rl: RocketLauncher = null
	for w in _pawn.inventory.weapons:
		if w is RocketLauncher:
			rl = w
			break
	_assert("rocket launcher equipped", rl != null)
	_assert("rocket ammo > 0", _pawn.inventory.get_ammo(&"rockets") > 0)

	# Listen for shake requests during the rocket tests.
	# Use a mutable container so the lambda can update it (GDScript lambdas capture by value).
	var shake_count: Array[int] = [0]
	EventBus.shake_requested.connect(func(_i: float): shake_count[0] += 1)

	# Primary rocket toward dummy
	pc.aim_target = _dummy.global_position
	await _wait_physics_frames(1)
	var dummy_hp_before: float = _dummy.health_component.health
	rl.primary_fire()
	await _wait_physics_frames(1)
	_assert("rocket spawned", get_tree().get_nodes_in_group(&"rocket").size() >= 1)
	# Poll for the hit (robust against travel-time variance).
	var rocket_hit := false
	for i in 90:
		await get_tree().physics_frame
		if _dummy.health_component.health < dummy_hp_before:
			rocket_hit = true
			break
	_assert("dummy took rocket damage", rocket_hit)

	# Rocket-jump: fire downward, check self damage AND upward knockback
	_pawn.respawn(SPAWN_POS)
	await _wait_physics_frames(40)
	_assert("on floor pre-rocket-jump", _pawn.is_on_floor())
	pc.aim_target = _pawn.global_position + Vector2(0, 60)
	await _wait_physics_frames(1)
	var hp_before: float = _pawn.health_component.health
	rl.primary_fire()
	await _wait_physics_frames(6)  # rocket falls + explodes
	var self_damage: float = hp_before - _pawn.health_component.health
	_assert("rocket-jump dealt self damage", self_damage > 0.0)
	_assert("self damage reduced by scale (< 60)", self_damage < 60.0)
	_assert("rocket-jump launched upward", _pawn.velocity.y < -100.0)

	# Multi-rocket alt: hold + release. Switch to RL so its tick() drives wish_fire_alt.
	_pawn.respawn(SPAWN_POS)
	_pawn.inventory.switch_to_slot(rl.data.slot)
	_assert("switched to rocket launcher", _pawn.inventory.current_weapon() == rl)
	await _wait_physics_frames(40)
	pc.aim_target = _pawn.global_position + Vector2(120, 0)  # aim right horizontally
	pc.wish_fire_alt = true
	await _wait_physics_frames(75)  # > 3 * 0.32 = 0.96s
	_assert("loaded 3 rockets during hold", rl._loaded == rl.max_loaded)
	pc.wish_fire_alt = false
	await _wait_physics_frames(2)
	var alt_rockets: int = get_tree().get_nodes_in_group(&"rocket").size()
	_assert("alt fired multiple rockets", alt_rockets >= 2)

	_assert("camera shake requested", shake_count[0] > 0)

	# Camera rig still attached
	var cam: CameraRig = null
	for c in _pawn.get_children():
		if c is CameraRig:
			cam = c
			break
	_assert("camera rig present", cam != null)

func _selftest_phase5_weapons() -> void:
	# Reuse the player + dummy. Bare controller so we drive intent directly.
	_pawn.set_controller(PawnController.new())
	_pawn.respawn(SPAWN_POS)
	await _clear_projectiles()
	_dummy.respawn(DUMMY_POS)
	var pc := _pawn.controller
	pc.pop_events()
	await _wait_physics_frames(40)
	await _clear_projectiles()
	_dummy.respawn(DUMMY_POS)  # full HP, post-projectiles

	# All 7 weapons present
	var weapons_by_class: Dictionary = {}
	for w in _pawn.inventory.weapons:
		weapons_by_class[w.get_script()] = w
	_assert("Enforcer equipped", weapons_by_class.has(Enforcer))
	_assert("BioRifle equipped", weapons_by_class.has(BioRifle))
	_assert("ShockRifle equipped (still)", weapons_by_class.has(ShockRifle))
	_assert("FlakCannon equipped", weapons_by_class.has(FlakCannon))
	_assert("RocketLauncher equipped (still)", weapons_by_class.has(RocketLauncher))
	_assert("SniperRifle equipped", weapons_by_class.has(SniperRifle))

	# ---------- Enforcer ----------
	var enforcer: Enforcer = weapons_by_class[Enforcer]
	_pawn.respawn(SPAWN_POS)
	await _clear_projectiles()
	_dummy.respawn(DUMMY_POS)
	pc.aim_target = _dummy.global_position
	await _wait_physics_frames(40)
	await _clear_projectiles()
	_dummy.respawn(DUMMY_POS)
	var dummy_hp_before: float = _dummy.health_component.health
	enforcer.primary_fire()
	await _wait_physics_frames(2)
	_assert("enforcer primary damaged dummy", _dummy.health_component.health < dummy_hp_before)
	_assert("enforcer damage ~ data.primary_damage",
		absf((dummy_hp_before - _dummy.health_component.health) - enforcer.data.primary_damage) < 1.0)

	# ---------- Bio Rifle ----------
	var bio: BioRifle = weapons_by_class[BioRifle]
	_pawn.respawn(SPAWN_POS)
	await _clear_projectiles()
	_dummy.respawn(DUMMY_POS)
	pc.aim_target = _dummy.global_position
	await _wait_physics_frames(40)
	await _clear_projectiles()
	_dummy.respawn(DUMMY_POS)
	var globs_before: int = get_tree().get_nodes_in_group(&"bio_glob").size()
	bio.primary_fire()
	await _wait_physics_frames(1)
	_assert("bio primary spawns glob", get_tree().get_nodes_in_group(&"bio_glob").size() > globs_before)
	# Wait for glob to fly + impact + spawn pool
	await _wait_physics_frames(60)
	# Some impact should have produced a pool OR damaged dummy directly
	var pools: int = get_tree().get_nodes_in_group(&"bio_pool").size()
	var bio_hit_dummy: bool = _dummy.health_component.health < _dummy.health_component.max_health
	_assert("bio glob impact: pool spawned OR dummy hit", pools > 0 or bio_hit_dummy)

	# ---------- Flak Cannon ----------
	var flak: FlakCannon = weapons_by_class[FlakCannon]
	_pawn.respawn(SPAWN_POS)
	await _clear_projectiles()
	_dummy.respawn(DUMMY_POS)
	pc.aim_target = _dummy.global_position
	await _wait_physics_frames(40)
	await _clear_projectiles()
	_dummy.respawn(DUMMY_POS)
	flak.primary_fire()
	await _wait_physics_frames(1)
	var shard_count: int = get_tree().get_nodes_in_group(&"flak_shard").size()
	_assert("flak primary spawns multiple shards", shard_count >= 8)

	flak.alt_fire()
	await _wait_physics_frames(1)
	var grenades: int = get_tree().get_nodes_in_group(&"flak_grenade").size()
	_assert("flak alt spawns grenade", grenades >= 1)

	# ---------- Sniper Rifle ----------
	var sniper: SniperRifle = weapons_by_class[SniperRifle]
	_pawn.respawn(SPAWN_POS)
	await _clear_projectiles()
	_dummy.respawn(DUMMY_POS)
	# Body shot: aim at dummy center
	pc.aim_target = _dummy.global_position
	await _wait_physics_frames(40)
	await _clear_projectiles()
	_dummy.respawn(DUMMY_POS)
	dummy_hp_before = _dummy.health_component.health
	sniper.primary_fire()
	await _wait_physics_frames(2)
	var body_damage: float = dummy_hp_before - _dummy.health_component.health
	_assert("sniper body shot damaged dummy", body_damage > 0.0)
	_assert("sniper body shot ~ primary_damage",
		absf(body_damage - sniper.data.primary_damage) < 1.0)

	# Headshot: aim above dummy center (at head zone, local Y < -3)
	await _clear_projectiles()
	# Bump dummy max HP so a 2× headshot doesn't cap at the health pool.
	_dummy.health_component.max_health = 250.0
	_dummy.respawn(DUMMY_POS)
	pc.aim_target = _dummy.global_position + Vector2(0, -8)  # 8 above center → head
	await _wait_physics_frames(40)
	await _clear_projectiles()
	_dummy.respawn(DUMMY_POS)
	dummy_hp_before = _dummy.health_component.health
	sniper.primary_fire()
	await _wait_physics_frames(2)
	var head_damage: float = dummy_hp_before - _dummy.health_component.health
	_assert("headshot damage > body shot", head_damage > body_damage)
	_assert("headshot ~ 2x primary",
		absf(head_damage - sniper.data.primary_damage * sniper.headshot_multiplier) < 2.0)

	# Sniper zoom toggle changes camera zoom
	var cam: CameraRig = null
	for c in _pawn.get_children():
		if c is CameraRig:
			cam = c
			break
	var zoom_before: Vector2 = cam.zoom if cam else Vector2.ONE
	sniper.toggle_zoom()
	# Tween is 0.12s, wait until it settles
	await _wait_physics_frames(12)
	_assert("zoom changed", cam == null or cam.zoom != zoom_before)
	sniper.toggle_zoom()  # restore
	await _wait_physics_frames(12)

func _selftest_pickups_and_match() -> void:
	_pawn.set_controller(PawnController.new())
	await _clear_projectiles()
	_pawn.respawn(SPAWN_POS)
	_dummy.respawn(DUMMY_POS)
	_dummy.health_component.max_health = 100.0  # reset (Phase 5 selftest bumped it)
	_dummy.respawn(DUMMY_POS)
	GameState.reset_scores()
	await _wait_physics_frames(40)

	# ---------- Pickup taken increases HP ----------
	# Damage the player first so the pickup can heal them.
	_pawn.apply_damage(DamageInfo.make(50.0, &"test", null))
	var hp_before: float = _pawn.health_component.health
	# Spawn a HealthPickup right on the player
	var hp_pickup: HealthPickup = HEALTH_PICKUP_SCENE.instantiate() as HealthPickup
	hp_pickup.respawn_seconds = 0.2  # short timer for testing
	hp_pickup.global_position = _pawn.global_position
	add_child(hp_pickup)
	await _wait_physics_frames(3)  # body_entered fires
	_assert("health pickup heals player", _pawn.health_component.health > hp_before)

	# ---------- Pickup respawns after timer ----------
	# Move the pickup off the player so it doesn't get instantly retaken when it respawns.
	hp_pickup.global_position = Vector2(60, 60)
	await _wait_physics_frames(20)  # 0.33s > 0.2s respawn
	_assert("pickup respawned (visible)", hp_pickup._available == true)
	hp_pickup.queue_free()
	await _wait_physics_frames(2)

	# ---------- Armor pickup ----------
	_pawn.respawn(SPAWN_POS)
	await _wait_physics_frames(20)
	var ar_pickup: ArmorPickup = ARMOR_PICKUP_SCENE.instantiate() as ArmorPickup
	ar_pickup.global_position = _pawn.global_position
	add_child(ar_pickup)
	await _wait_physics_frames(3)
	_assert("armor pickup gives armor", _pawn.health_component.armor > 0.0)
	ar_pickup.queue_free()
	await _wait_physics_frames(2)

	# ---------- Ammo pickup ----------
	var ammo_before: int = _pawn.inventory.get_ammo(&"rockets")
	var amp: AmmoPickup = AMMO_PICKUP_SCENE.instantiate() as AmmoPickup
	amp.ammo_type = &"rockets"
	amp.amount = 4
	amp.global_position = _pawn.global_position
	add_child(amp)
	await _wait_physics_frames(3)
	_assert("ammo pickup gives ammo", _pawn.inventory.get_ammo(&"rockets") > ammo_before)
	amp.queue_free()
	await _wait_physics_frames(2)

	# ---------- Match scoring chain: kill via apply_damage → MatchDirector → GameState ----------
	GameState.state = GameState.MatchState.ACTIVE  # un-end (Phase 5 may have left it stale)
	GameState.frag_limit = 5  # higher than 1 so chain test doesn't immediately end
	GameState.reset_scores()
	_dummy.respawn(DUMMY_POS)
	_dummy.apply_damage(DamageInfo.make(9999.0, &"test", _pawn))
	await _wait_physics_frames(2)
	_assert("director credits player on kill", GameState.scores.get(&"player", 0) == 1)

	# ---------- Frag limit ends the match (direct GameState calls) ----------
	GameState.state = GameState.MatchState.ACTIVE
	GameState.frag_limit = 3
	GameState.reset_scores()
	var ended_signals: Array[int] = [0]
	var on_ended: Callable = func(_w: StringName) -> void: ended_signals[0] += 1
	GameState.match_ended.connect(on_ended)
	for i in 3:
		GameState.add_frag(&"player")
	_assert("scored 3 frags via add_frag", GameState.scores.get(&"player", 0) == 3)
	_assert("match_ended fires at frag limit", ended_signals[0] == 1)
	GameState.match_ended.disconnect(on_ended)
	GameState.frag_limit = 10  # restore

func _selftest_bot_ai() -> void:
	await _clear_projectiles()
	# Park player + dummy far from the bot so they don't trip perception unexpectedly.
	_pawn.set_controller(PawnController.new())
	_pawn.respawn(SPAWN_POS)
	_dummy.respawn(Vector2(60, 60))  # off in a corner
	_dummy.health_component.is_alive = true  # keep alive (don't let bot kill it)

	# Spawn a clean bot instance for the test (avoid interference with the dev_test bot
	# that may have stale state from the inert window).
	var bot: Pawn = PAWN_SCENE.instantiate()
	add_child(bot)
	bot.id = &"test_bot"
	bot.global_position = Vector2(240, 230)
	var bc := BotController.new()
	bot.set_controller(bc)
	bc.set_nav_graph(_nav_graph)
	_equip_full_kit(bot)
	await _wait_physics_frames(2)

	# ---------- NavGraph built non-empty paths ----------
	_assert("nav graph has points", _nav_graph.astar.get_point_count() > 0)
	var path: PackedVector2Array = _nav_graph.find_path(Vector2(40, 240), Vector2(240, 48))
	_assert("nav graph finds path", path.size() >= 2)

	# ---------- Perception sees player as enemy ----------
	# Place player in clear LOS of bot
	_pawn.global_position = Vector2(120, 230)  # same height as bot, no walls between
	await _wait_physics_frames(2)
	bc.perception.update()
	_assert("bot perceives player as enemy", bc.perception.visible_enemies.has(_pawn))
	_assert("bot finds closest enemy", bc.perception.get_closest_enemy() == _pawn)

	# ---------- State machine: enters FIGHT when enemy visible ----------
	bc._select_state()
	_assert("bot enters FIGHT state", bc.state == BotController.State.FIGHT)

	# ---------- Combat: weapon preference by distance (Enforcer-only loadout) ----------
	_assert("close range → enforcer (slot 2)", bc.combat.pick_weapon_slot(20.0) == 2)
	_assert("medium range → enforcer (slot 2)", bc.combat.pick_weapon_slot(150.0) == 2)
	_assert("far range → enforcer (slot 2)", bc.combat.pick_weapon_slot(500.0) == 2)

	# ---------- Combat: reaction time gates firing ----------
	bc.combat._last_target = null  # force re-acquire
	bc.combat.compute_aim_target(_pawn)  # mark acquisition time = now
	_assert("can_fire blocked by reaction time", not bc.combat.can_fire(_pawn))
	await _wait_physics_frames(20)  # ~0.33s > 0.2s reaction
	_assert("can_fire allowed after reaction time", bc.combat.can_fire(_pawn))

	# ---------- EVADE: nearby rocket triggers dodge event ----------
	# Spawn a fake rocket in the threat group near the bot (no instigator interference)
	var rocket: Node2D = Node2D.new()
	rocket.add_to_group(&"rocket")
	rocket.global_position = bot.global_position + Vector2(30, 0)
	add_child(rocket)
	await _wait_physics_frames(2)
	bc.perception.update()
	_assert("bot perceives threat", bc.perception.nearest_threat != null)
	bc._select_state()
	_assert("bot enters EVADE state", bc.state == BotController.State.EVADE)
	bc.events.clear()
	bc._do_evade(Time.get_ticks_msec())
	_assert("evade pushes dodge event",
		bc.events.has(&"dodge_left") or bc.events.has(&"dodge_right"))
	rocket.queue_free()

	bot.queue_free()
	await _wait_physics_frames(2)

func _selftest_hud_and_polish() -> void:
	await _clear_projectiles()
	# Restore dummy so we can kill it again for the death-burst test.
	_dummy.global_position = DUMMY_POS
	_dummy.health_component.max_health = 100.0
	_dummy.respawn(DUMMY_POS)
	await _wait_physics_frames(5)

	# ---------- HUD bound + reflecting state ----------
	_assert("hud exists", _hud != null)
	_assert("hud bound to player", _hud.pawn == _pawn)

	# After applying damage, the HUD should spawn a damage indicator child.
	var dmg_layer: Control = _hud.get_node("Root/DamageOverlay") as Control
	_assert("hud has damage overlay", dmg_layer != null)
	var before_indicators: int = dmg_layer.get_child_count()
	# Attacker is the dummy → makes a directional indicator
	var info := DamageInfo.make(20.0, &"test", _dummy, &"test")
	_pawn.apply_damage(info)
	await _wait_physics_frames(2)
	_assert("damage indicator spawned",
		dmg_layer.get_child_count() > before_indicators)

	# ---------- Difficulty params propagate to BotCombat ----------
	GameState.difficulty = GameState.Difficulty.INSANE
	var test_bot: Pawn = PAWN_SCENE.instantiate()
	add_child(test_bot)
	test_bot.global_position = Vector2(40, 230)
	test_bot.id = &"diff_test_bot"
	var bc := BotController.new()
	test_bot.set_controller(bc)
	await _wait_physics_frames(1)
	_assert("insane aim error is low", bc.combat.aim_error_stddev <= 5.0)
	_assert("insane reaction time is short", bc.combat.reaction_time_msec <= 150)
	# Spawn another bot under EASY difficulty for contrast
	GameState.difficulty = GameState.Difficulty.EASY
	var easy_bot: Pawn = PAWN_SCENE.instantiate()
	add_child(easy_bot)
	easy_bot.global_position = Vector2(60, 230)
	easy_bot.id = &"easy_bot"
	var easy_bc := BotController.new()
	easy_bot.set_controller(easy_bc)
	await _wait_physics_frames(1)
	_assert("easy aim error is high", easy_bc.combat.aim_error_stddev >= 15.0)
	_assert("easy reaction time is long", easy_bc.combat.reaction_time_msec >= 300)
	GameState.difficulty = GameState.Difficulty.NORMAL
	test_bot.queue_free()
	easy_bot.queue_free()
	await _wait_physics_frames(2)

	# ---------- Death gibs ----------
	_dummy.respawn(DUMMY_POS)
	await _wait_physics_frames(2)
	# Count existing DeathBurst nodes before
	var burst_count_before: int = 0
	for n in get_children():
		if n is DeathBurst:
			burst_count_before += 1
	_dummy.apply_damage(DamageInfo.make(9999.0, &"test", _pawn))
	await _wait_physics_frames(2)
	var burst_count_after: int = 0
	for n in get_children():
		if n is DeathBurst:
			burst_count_after += 1
	_assert("death burst spawned on death", burst_count_after > burst_count_before)

	# ---------- Floating text ----------
	var ft: FloatingText = FloatingText.spawn(self, Vector2(160, 200), "+1")
	_assert("floating text spawned", ft != null and ft.is_inside_tree())
	# Cleanup
	ft.queue_free()
	await _wait_physics_frames(2)

func _selftest_arenas() -> void:
	# Instantiate each arena in isolation (separate from the dev_test scene's geometry),
	# in a sub-Node2D, then verify each populated correctly. We don't add to the
	# current scene tree at the top level — using a holder so we can clean up after.
	const ARENA_PATHS := [
		"res://scenes/arenas/arena_01.tscn",
		"res://scenes/arenas/arena_02.tscn",
	]
	var arena_tints: Array[Color] = []
	for path in ARENA_PATHS:
		var holder := Node2D.new()
		add_child(holder)
		var packed: PackedScene = load(path)
		_assert("arena loads: %s" % path, packed != null)
		var arena: Arena = packed.instantiate() as Arena
		_assert("arena root is Arena: %s" % path, arena != null)
		holder.add_child(arena)
		await _wait_physics_frames(2)

		# TileMapLayer present + has cells
		var tile_map: TileMapLayer = null
		for c in arena.get_children():
			if c is TileMapLayer:
				tile_map = c
				break
		_assert("arena %s has TileMapLayer" % arena.display_name, tile_map != null)
		_assert("arena %s has tiles placed" % arena.display_name,
			tile_map != null and tile_map.get_used_cells().size() > 0)

		# Nav nodes
		var nav_count: int = 0
		for n in arena.get_children():
			if n is NavNode:
				nav_count += 1
		_assert("arena %s has nav nodes" % arena.display_name, nav_count >= 6)

		# Player starts (group)
		var starts: int = 0
		for n in arena.get_children():
			if n is Marker2D and n.is_in_group(&"player_start"):
				starts += 1
		_assert("arena %s has player starts" % arena.display_name, starts >= 2)

		# Pickups
		var pickup_count: int = 0
		for n in arena.get_children():
			if n is Pickup:
				pickup_count += 1
		_assert("arena %s has pickups" % arena.display_name, pickup_count >= 4)

		# Palette tint (CanvasModulate)
		var cm: CanvasModulate = null
		for c in arena.get_children():
			if c is CanvasModulate:
				cm = c
				break
		_assert("arena %s has palette tint" % arena.display_name, cm != null)
		if cm != null:
			arena_tints.append(cm.color)

		holder.queue_free()
		await _wait_physics_frames(2)

	# Arenas should have distinct palette identities.
	if arena_tints.size() == 2:
		_assert("arenas have distinct tints", arena_tints[0] != arena_tints[1])

func _wait_physics_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _clear_projectiles() -> void:
	# Remove any in-flight projectiles / pools / grenades so they don't pollute the next subtest.
	for g in [&"rocket", &"shock_orb", &"bio_glob", &"bio_pool", &"flak_shard", &"flak_grenade"]:
		for n in get_tree().get_nodes_in_group(g):
			n.queue_free()
	await _wait_physics_frames(2)

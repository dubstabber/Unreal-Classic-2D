class_name BotController
extends PawnController
## State-machine bot. Three states: ROAM (pickups / wander), FIGHT (engage visible
## enemy), EVADE (dodge incoming explosive). All output is via PawnController
## intent fields — same pipeline as the player.

enum State { ROAM, FIGHT, EVADE }

var pawn: Pawn = null
var perception: BotPerception
var combat: BotCombat
var nav_graph: NavGraph

var state: State = State.ROAM
var current_path: PackedVector2Array = PackedVector2Array()
var path_index: int = 0

var _next_perception_msec: int = 0
var _next_roam_pick_msec: int = 0
var _strafe_flip_msec: int = 0
var _strafe_dir: int = 1
var _last_pos: Vector2 = Vector2.ZERO
var _stuck_msec: int = 0

func bind_pawn(p: Pawn) -> void:
	pawn = p
	perception = BotPerception.new()
	perception.bind(p)
	add_child(perception)
	combat = BotCombat.new()
	combat.bind(p)
	add_child(combat)
	# Apply difficulty params (set by main menu / selftest)
	var dp: Dictionary = GameState.difficulty_params()
	if dp.has("aim_error_stddev"):
		combat.aim_error_stddev = dp["aim_error_stddev"]
	if dp.has("reaction_time_msec"):
		combat.reaction_time_msec = dp["reaction_time_msec"]
	_last_pos = p.global_position

func set_nav_graph(g: NavGraph) -> void:
	nav_graph = g

func _physics_process(_delta: float) -> void:
	if pawn == null or not pawn.is_alive():
		_clear_intent()
		return
	var now: int = Time.get_ticks_msec()
	if now >= _next_perception_msec:
		_next_perception_msec = now + 100
		perception.update()
	_select_state()
	match state:
		State.ROAM: _do_roam(now)
		State.FIGHT: _do_fight(now)
		State.EVADE: _do_evade(now)
	_detect_stuck(now)

func _select_state() -> void:
	if perception.nearest_threat != null:
		state = State.EVADE
		return
	if perception.get_closest_enemy() != null:
		state = State.FIGHT
		return
	state = State.ROAM

# ---------- ROAM ----------

func _do_roam(now: int) -> void:
	wish_fire_primary = false
	wish_fire_alt = false
	if current_path.size() < 2 or path_index >= current_path.size() or now >= _next_roam_pick_msec:
		_pick_roam_target()
		_next_roam_pick_msec = now + 4500
	_follow_path()

func _pick_roam_target() -> void:
	var target: Vector2 = pawn.global_position
	# Prefer the nearest available pickup
	var best_d: float = INF
	for p in pawn.get_tree().get_nodes_in_group(&"pickup"):
		if not (p is Pickup):
			continue
		if not (p as Pickup)._available:
			continue
		var d: float = pawn.global_position.distance_squared_to((p as Node2D).global_position)
		if d < best_d:
			best_d = d
			target = (p as Node2D).global_position
	if best_d == INF:
		# No pickups — wander to a random nav node
		var nodes: Array = pawn.get_tree().get_nodes_in_group(&"nav_node")
		if not nodes.is_empty():
			target = (nodes.pick_random() as Node2D).global_position
	_set_path_to(target)

func _set_path_to(target: Vector2) -> void:
	if nav_graph == null:
		current_path = PackedVector2Array([pawn.global_position, target])
	else:
		current_path = nav_graph.find_path(pawn.global_position, target)
	path_index = 0

func _follow_path() -> void:
	if current_path.size() < 2 or path_index >= current_path.size():
		wish_move = 0.0
		wish_jump_held = false
		return
	var target_point: Vector2 = current_path[path_index]
	var delta: Vector2 = target_point - pawn.global_position
	# Reached current waypoint?
	if delta.length() < 12.0:
		path_index += 1
		return
	# Horizontal intent
	wish_move = signf(delta.x) if absf(delta.x) > 4.0 else 0.0
	# Jump if next point is significantly above us; hold for extra height while ascending.
	if delta.y < -16.0:
		if pawn.is_on_floor():
			push_event(&"jump_pressed")
		wish_jump_held = pawn.velocity.y < 0.0
	else:
		wish_jump_held = false

# ---------- FIGHT ----------

func _do_fight(now: int) -> void:
	var enemy: Pawn = perception.get_closest_enemy()
	if enemy == null:
		wish_fire_primary = false
		return
	var dist: float = pawn.global_position.distance_to(enemy.global_position)
	# Aim (with Gaussian jitter)
	var aim: Vector2 = combat.compute_aim_target(enemy)
	if aim != Vector2.ZERO:
		aim_target = aim
	# Weapon selection by distance
	var desired_slot: int = combat.pick_weapon_slot(dist)
	var current: Weapon = pawn.inventory.current_weapon() as Weapon
	if current != null and current.slot != desired_slot:
		# Only switch if we actually own the desired slot
		for w in pawn.inventory.weapons:
			if w is Weapon and (w as Weapon).slot == desired_slot:
				push_event(StringName("slot_%d" % desired_slot))
				break
	# Strafe at medium range; close in if far, retreat if too near
	if dist < 60.0:
		wish_move = -signf(enemy.global_position.x - pawn.global_position.x)
	elif dist > 280.0:
		wish_move = signf(enemy.global_position.x - pawn.global_position.x)
	else:
		if now >= _strafe_flip_msec:
			_strafe_flip_msec = now + 700
			_strafe_dir = -_strafe_dir
		wish_move = _strafe_dir
	wish_fire_primary = combat.can_fire(enemy)
	wish_fire_alt = false

# ---------- EVADE ----------

func _do_evade(_now: int) -> void:
	var threat: Node2D = perception.nearest_threat
	if threat == null:
		return
	wish_fire_primary = false
	var dx: float = threat.global_position.x - pawn.global_position.x
	# Dodge AWAY from threat
	if dx >= 0:
		push_event(&"dodge_left")
	else:
		push_event(&"dodge_right")

# ---------- Helpers ----------

func _clear_intent() -> void:
	wish_move = 0.0
	wish_crouch = false
	wish_jump_held = false
	wish_fire_primary = false
	wish_fire_alt = false

func _detect_stuck(now: int) -> void:
	# If we're not moving in ROAM despite trying to, throw a jump to break free.
	if state != State.ROAM:
		_stuck_msec = 0
		_last_pos = pawn.global_position
		return
	if pawn.global_position.distance_to(_last_pos) < 1.0 and absf(wish_move) > 0.01:
		if _stuck_msec == 0:
			_stuck_msec = now
		elif now - _stuck_msec > 500:
			push_event(&"jump_pressed")
			_stuck_msec = now
	else:
		_stuck_msec = 0
	_last_pos = pawn.global_position

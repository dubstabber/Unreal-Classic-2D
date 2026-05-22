class_name Pawn
extends CharacterBody2D
## Base class for any "person" in the world — player or bot.
## Holds health/armor (HealthComponent), inventory, and a controller that supplies intent.
## Movement physics live here; controllers (PlayerController / BotController) only set intent.

signal damaged(info: DamageInfo)
signal died(killer: Node)
signal respawned

@export var stats: PawnStats = preload("res://resources/pawns/default_pawn_stats.tres")
@export var team: StringName = &""
@export var display_name: String = "Pawn"

var id: StringName = &""
var controller: PawnController = null

# Movement state
var _facing_x: int = 1                # 1 right, -1 left
var _is_crouching: bool = false
var _last_on_floor_msec: int = -100000
var _jump_buffer_msec: int = -100000
var _last_dodge_msec: int = -100000

@onready var health_component: HealthComponent = $HealthComponent
@onready var inventory: Inventory = $Inventory
@onready var _coll: CollisionShape2D = $CollisionShape2D
@onready var _body_spr: Sprite2D = $Visual/Body
@onready var _head_spr: Sprite2D = $Visual/Head
@onready var _arm_spr: Sprite2D = $Visual/Arm

func _ready() -> void:
	add_to_group(&"pawn")
	if id == &"":
		id = StringName("pawn_%d" % get_instance_id())
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	_setup_visual_rig()

func _setup_visual_rig() -> void:
	if _body_spr: _body_spr.texture = SpriteBaker.get_texture(&"pawn_body")
	if _head_spr: _head_spr.texture = SpriteBaker.get_texture(&"pawn_head")
	if _arm_spr:  _arm_spr.texture  = SpriteBaker.get_texture(&"pawn_arm")

func set_controller(c: PawnController) -> void:
	if controller != null and controller.is_inside_tree():
		controller.queue_free()
	controller = c
	if c != null:
		add_child(c)
		if c.has_method(&"bind_pawn"):
			c.call(&"bind_pawn", self)

func equip_weapon(w: Weapon, base_ammo: int = -1) -> void:
	# Adds the weapon to the scene tree (as a child of the Pawn), wires it,
	# and registers it with the inventory. If base_ammo<0, uses WeaponData.base_ammo_on_pickup.
	if w == null:
		return
	add_child(w)
	w.bind_pawn(self)
	inventory.add_weapon(w)
	if w.data != null and w.data.ammo_type != &"":
		var amount: int = base_ammo if base_ammo >= 0 else w.data.base_ammo_on_pickup
		if w.data.max_ammo > 0:
			inventory.set_ammo_cap(w.data.ammo_type, w.data.max_ammo)
		inventory.add_ammo(w.data.ammo_type, amount)

# ---------- Damage / death ----------

func apply_damage(info: DamageInfo) -> void:
	if info == null or not health_component.is_alive:
		return
	health_component.take_damage(info)
	if info.knockback != Vector2.ZERO:
		velocity += info.knockback
	EventBus.damage_dealt.emit(info.get_instigator(), self, info)

func is_alive() -> bool:
	return health_component != null and health_component.is_alive

func _on_damaged(_actual: float, info: DamageInfo) -> void:
	damaged.emit(info)
	EventBus.pawn_damaged.emit(self, info)

func _on_died(killer: Node) -> void:
	died.emit(killer)
	EventBus.pawn_killed.emit(self, killer)
	set_physics_process(false)
	_coll.set_deferred(&"disabled", true)
	visible = false
	# Death burst FX
	if is_inside_tree():
		DeathBurst.spawn(get_tree().current_scene, global_position)

func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	_last_on_floor_msec = -100000
	_jump_buffer_msec = -100000
	_last_dodge_msec = -100000
	health_component.reset()
	_coll.set_deferred(&"disabled", false)
	visible = true
	set_physics_process(true)
	respawned.emit()
	EventBus.pawn_respawned.emit(self)

# ---------- Movement ----------

func _physics_process(delta: float) -> void:
	if not is_alive() or controller == null or stats == null:
		return

	var was_on_floor: bool = is_on_floor()
	_is_crouching = controller.wish_crouch and is_on_floor()

	_apply_horizontal(delta)
	_apply_gravity(delta)
	_process_events()

	# Tick the equipped weapon (firing, cooldowns).
	var w: Weapon = inventory.current_weapon() as Weapon
	if w != null:
		w.tick(delta)

	move_and_slide()

	if is_on_floor():
		_last_on_floor_msec = Time.get_ticks_msec()
		# Buffered jump on landing
		if not was_on_floor and _jump_buffer_msec > 0:
			var since: int = Time.get_ticks_msec() - _jump_buffer_msec
			if since <= int(stats.jump_buffer_seconds * 1000.0):
				velocity.y = -stats.jump_impulse
			_jump_buffer_msec = -100000

	_update_facing_and_visuals()

func _apply_horizontal(delta: float) -> void:
	var on_floor: bool = is_on_floor()
	var move: float = controller.wish_move
	var target_speed: float
	if on_floor:
		target_speed = stats.crouch_speed if _is_crouching else stats.run_speed
	else:
		target_speed = stats.air_speed
	var accel: float
	if on_floor:
		accel = stats.crouch_accel if _is_crouching else stats.run_accel
	else:
		accel = stats.air_accel

	if absf(move) > 0.01:
		# Quake/UT-style accel: only add up to wish_speed in input direction.
		# Preserves momentum from dodges/launches.
		var wish_vel: float = move * target_speed
		var speed_in_wish: float = velocity.x * signf(move)
		if speed_in_wish < absf(wish_vel):
			var add: float = minf(accel * delta, absf(wish_vel) - speed_in_wish)
			velocity.x += signf(move) * add
	else:
		var friction: float = stats.run_friction if on_floor else stats.air_friction
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _apply_gravity(delta: float) -> void:
	var g: float = stats.gravity
	if controller.wish_jump_held and velocity.y < 0.0:
		g *= stats.jump_hold_gravity_scale
	velocity.y += g * delta
	velocity.y = minf(velocity.y, stats.max_fall_speed)

func _process_events() -> void:
	for e in controller.pop_events():
		match e:
			&"jump_pressed":
				if not _try_jump():
					_jump_buffer_msec = Time.get_ticks_msec()
				_try_dodge_jump()
			&"dodge_left":
				_try_dodge(-1)
			&"dodge_right":
				_try_dodge(1)
			_:
				if String(e).begins_with("slot_"):
					var slot: int = int(String(e).substr(5))
					inventory.switch_to_slot(slot)

func _try_jump() -> bool:
	var now: int = Time.get_ticks_msec()
	var since_floor: int = now - _last_on_floor_msec
	var coyote: bool = since_floor <= int(stats.coyote_seconds * 1000.0)
	if not (is_on_floor() or coyote):
		return false
	velocity.y = -stats.jump_impulse
	_last_on_floor_msec = -100000  # consume coyote so a second jump isn't free
	return true

func _try_dodge_jump() -> void:
	if is_on_floor():
		return
	var since_dodge: int = Time.get_ticks_msec() - _last_dodge_msec
	if since_dodge < 0 or since_dodge > stats.dodge_jump_window_msec:
		return
	# Only kick if not already moving up hard
	if velocity.y > -50.0:
		velocity.y = -stats.dodge_jump_impulse
	_last_dodge_msec = -100000  # consume

func _try_dodge(dir: int) -> void:
	if dir == 0:
		return
	if is_on_floor():
		velocity.x = float(dir) * stats.dodge_horizontal_impulse
		velocity.y = -stats.dodge_vertical_impulse
		_last_dodge_msec = Time.get_ticks_msec()
	elif is_on_wall():
		# Wall-dodge: push off in the direction of the wall's normal (away from wall).
		var n: Vector2 = get_wall_normal()
		var away_x: int = int(signf(n.x))
		if away_x == 0:
			away_x = dir
		velocity.x = float(away_x) * stats.wall_dodge_horizontal_impulse
		velocity.y = -stats.wall_dodge_vertical_impulse
		_last_dodge_msec = Time.get_ticks_msec()
	# else: airborne with no wall — no dodge (vanilla UT99 behavior)

func _update_facing_and_visuals() -> void:
	if controller == null:
		return
	var to_aim: Vector2 = controller.aim_target - global_position
	if absf(to_aim.x) > 0.5:
		_facing_x = -1 if to_aim.x < 0.0 else 1
	if _body_spr: _body_spr.flip_h = _facing_x < 0
	if _head_spr: _head_spr.flip_h = _facing_x < 0
	if _arm_spr:
		var shoulder: Vector2 = _arm_spr.global_position
		var to_aim_arm: Vector2 = controller.aim_target - shoulder
		var raw: float = to_aim_arm.angle()
		var step: float = TAU / 16.0
		_arm_spr.rotation = roundf(raw / step) * step
		# Mirror vertically when aiming left so the gun isn't upside-down.
		_arm_spr.scale.y = -1.0 if absf(raw) > PI * 0.5 else 1.0

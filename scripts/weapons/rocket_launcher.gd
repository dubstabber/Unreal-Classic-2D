class_name RocketLauncher
extends Weapon

const ROCKET_SCENE := preload("res://scenes/projectiles/rocket.tscn")

@export var max_loaded: int = 3
@export var charge_per_rocket: float = 0.32
@export var spread_radians: float = 0.18  # half-angle of the load-released spread

var _loaded: int = 0
var _charge_timer: float = 0.0
var _alt_was_held: bool = false

func tick(delta: float) -> void:
	_primary_cooldown = maxf(0.0, _primary_cooldown - delta)
	_alt_cooldown = maxf(0.0, _alt_cooldown - delta)
	if pawn == null or pawn.controller == null or data == null:
		return

	if pawn.controller.wish_fire_primary and _primary_cooldown <= 0.0:
		if _consume_ammo(data.ammo_per_shot_primary):
			primary_fire()
			_primary_cooldown = data.primary_fire_rate
			fired.emit(&"primary")

	var alt_held: bool = pawn.controller.wish_fire_alt
	if _alt_cooldown <= 0.0:
		if alt_held and _loaded < max_loaded:
			_charge_timer += delta
			while _charge_timer >= charge_per_rocket and _loaded < max_loaded:
				if _consume_ammo(data.ammo_per_shot_alt):
					_loaded += 1
					_charge_timer -= charge_per_rocket
				else:
					_charge_timer = 0.0
					break
		elif _alt_was_held and not alt_held and _loaded > 0:
			_release_loaded()
			_alt_cooldown = data.alt_fire_rate
	_alt_was_held = alt_held

func primary_fire() -> void:
	_fire_rocket(aim_direction())

func alt_fire() -> void:
	# Direct alt call (used by selftest / debug commands) — fires one rocket without charge.
	_fire_rocket(aim_direction())

func _release_loaded() -> void:
	var n: int = _loaded
	_loaded = 0
	_charge_timer = 0.0
	var base_dir: Vector2 = aim_direction()
	for i in n:
		var t: float = 0.0 if n == 1 else (float(i) / float(n - 1)) * 2.0 - 1.0  # -1..+1
		var angle: float = spread_radians * t
		_fire_rocket(base_dir.rotated(angle))
	fired.emit(&"alt")

func _fire_rocket(direction: Vector2) -> void:
	if pawn == null:
		return
	var rocket: Rocket = ROCKET_SCENE.instantiate() as Rocket
	if rocket.radial_damage == null:
		var r := RadialDamage.new()
		r.max_damage = 100.0
		r.min_damage = 12.0
		r.radius = 44.0
		r.knockback_strength = 560.0
		r.damage_type = &"explosive"
		r.weapon_id = &"rocket_launcher.primary"
		r.self_damage_scale = 0.5
		rocket.radial_damage = r
	rocket.damage = data.primary_damage if data != null else 50.0
	pawn.get_tree().current_scene.add_child(rocket)
	rocket.launch(barrel_position(), direction, pawn)

class_name ImpactHammer
extends Weapon
## Slot 1. Charge-and-release melee impact (primary). Hammer-jump (alt) launches you
## off a surface via self-only radial damage — same RadialDamage pipeline as rockets.

@export var charge_time: float = 0.8
@export var primary_radius: float = 32.0
@export var primary_min_damage: float = 20.0
@export var primary_max_damage: float = 90.0
@export var primary_min_knockback: float = 250.0
@export var primary_max_knockback: float = 700.0

@export var alt_radius: float = 36.0
@export var alt_self_damage: float = 8.0
@export var alt_knockback: float = 760.0

var _primary_charge: float = 0.0
var _primary_was_held: bool = false

func tick(delta: float) -> void:
	_primary_cooldown = maxf(0.0, _primary_cooldown - delta)
	_alt_cooldown = maxf(0.0, _alt_cooldown - delta)
	if pawn == null or pawn.controller == null or data == null:
		return

	# Primary: charge while held, fire on release.
	var prim_held: bool = pawn.controller.wish_fire_primary
	if _primary_cooldown <= 0.0:
		if prim_held:
			_primary_charge = minf(charge_time, _primary_charge + delta)
		elif _primary_was_held and not prim_held and _primary_charge > 0.0:
			var ratio: float = _primary_charge / charge_time
			_primary_charge = 0.0
			primary_fire_with_charge(ratio)
			_primary_cooldown = data.primary_fire_rate
	_primary_was_held = prim_held

	# Alt: instant hammer-jump.
	if pawn.controller.wish_fire_alt and _alt_cooldown <= 0.0:
		alt_fire()
		_alt_cooldown = data.alt_fire_rate

func primary_fire() -> void:
	primary_fire_with_charge(1.0)

func primary_fire_with_charge(ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	var origin: Vector2 = aim_origin() + aim_direction() * (primary_radius * 0.5)
	var r := RadialDamage.new()
	r.max_damage = lerpf(primary_min_damage, primary_max_damage, ratio)
	r.min_damage = 5.0
	r.radius = primary_radius
	r.knockback_strength = lerpf(primary_min_knockback, primary_max_knockback, ratio)
	r.damage_type = &"melee"
	r.weapon_id = &"impact_hammer.primary"
	r.self_damage_scale = 0.0
	r.apply(pawn.get_world_2d(), origin, pawn)
	_spawn_burst(origin, lerpf(0.7, 1.4, ratio))
	EventBus.shake_requested.emit(2.0 + 4.0 * ratio)
	fired.emit(&"primary")

func alt_fire() -> void:
	# Hammer-jump: self-only damage with strong knockback opposite to aim direction.
	var info := DamageInfo.make(alt_self_damage, &"impact", pawn, &"impact_hammer.alt")
	info.knockback = -aim_direction() * alt_knockback
	info.is_self_damage = true
	pawn.apply_damage(info)
	_spawn_burst(pawn.global_position, 1.1)
	EventBus.shake_requested.emit(4.0)
	fired.emit(&"alt")

func _spawn_burst(at: Vector2, scale_factor: float) -> void:
	var spr := Sprite2D.new()
	spr.texture = SpriteBaker.get_texture(&"hammer_burst")
	spr.top_level = true
	spr.global_position = at
	spr.scale = Vector2(scale_factor, scale_factor)
	pawn.get_tree().current_scene.add_child(spr)
	var tw := spr.create_tween()
	tw.set_parallel(true)
	tw.tween_property(spr, "scale", spr.scale * 2.0, 0.18)
	tw.tween_property(spr, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(spr.queue_free)

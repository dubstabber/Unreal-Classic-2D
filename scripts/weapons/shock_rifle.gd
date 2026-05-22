class_name ShockRifle
extends Weapon

const SHOCK_ORB_SCENE := preload("res://scenes/projectiles/shock_orb.tscn")
const ShockBeamScript := preload("res://scripts/fx/shock_beam.gd")

@export var beam_range: float = 480.0
@export var beam_damage: float = 40.0
@export var beam_knockback: float = 50.0
@export var combo_proximity: float = 12.0   # px from beam line to detonate orb

func primary_fire() -> void:
	if pawn == null:
		return
	var origin: Vector2 = barrel_position()
	var dir: Vector2 = aim_direction()
	var end: Vector2 = origin + dir * beam_range

	var space: PhysicsDirectSpaceState2D = pawn.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(origin, end)
	query.exclude = [pawn.get_rid()]
	query.collision_mask = 1 | 2   # world + pawns
	var hit: Dictionary = space.intersect_ray(query)

	var hit_point: Vector2 = end
	var hit_pawn: Pawn = null
	if not hit.is_empty():
		hit_point = hit.position
		if hit.collider is Pawn:
			hit_pawn = hit.collider as Pawn

	# Shock combo: detonate any orb whose center is close to the beam line.
	# Iterating the (small) group is cheaper than per-orb raycasts.
	var combo_hit_point: Vector2 = _check_combo(origin, dir, (hit_point - origin).length())
	if combo_hit_point != Vector2.INF:
		hit_point = combo_hit_point
		hit_pawn = null  # beam stops at orb

	if hit_pawn != null:
		var info := DamageInfo.make(beam_damage, &"energy", pawn, &"shock_rifle.primary")
		info.knockback = dir * beam_knockback
		hit_pawn.apply_damage(info)

	_spawn_beam(origin, hit_point)

func alt_fire() -> void:
	if pawn == null:
		return
	var orb: ShockOrb = SHOCK_ORB_SCENE.instantiate() as ShockOrb
	# Wire combo radial if not already set on the .tscn
	if orb.combo_radial == null:
		var c := RadialDamage.new()
		c.max_damage = 110.0
		c.min_damage = 20.0
		c.radius = 64.0
		c.knockback_strength = 480.0
		c.damage_type = &"explosive"
		c.weapon_id = &"shock_rifle.combo"
		orb.combo_radial = c
	if orb.radial_damage == null:
		var r := RadialDamage.new()
		r.max_damage = 45.0
		r.min_damage = 5.0
		r.radius = 32.0
		r.knockback_strength = 200.0
		r.damage_type = &"explosive"
		r.weapon_id = &"shock_rifle.alt"
		orb.radial_damage = r
	pawn.get_tree().current_scene.add_child(orb)
	orb.launch(barrel_position(), aim_direction(), pawn)

func _check_combo(origin: Vector2, dir: Vector2, max_len: float) -> Vector2:
	# Returns hit point along the beam or Vector2.INF if no combo.
	var best_t: float = max_len + 1.0
	var best_orb: ShockOrb = null
	for n in pawn.get_tree().get_nodes_in_group(&"shock_orb"):
		var orb := n as ShockOrb
		if orb == null or not orb.is_inside_tree():
			continue
		var to_orb: Vector2 = orb.global_position - origin
		var t: float = to_orb.dot(dir)
		if t < 0.0 or t > max_len:
			continue
		var perp_sq: float = (to_orb - dir * t).length_squared()
		if perp_sq > combo_proximity * combo_proximity:
			continue
		if t < best_t:
			best_t = t
			best_orb = orb
	if best_orb == null:
		return Vector2.INF
	var hit_point: Vector2 = origin + dir * best_t
	best_orb.detonate(pawn)
	return hit_point

func _spawn_beam(from: Vector2, to: Vector2) -> void:
	ShockBeamScript.spawn(pawn.get_tree().current_scene, from, to)

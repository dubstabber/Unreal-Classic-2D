class_name RadialDamage
extends Resource
## Shared utility for any radial damage source — rocket explosion, hammer alt,
## flak alt, shock combo. One code path so behavior stays consistent.

@export var max_damage: float = 100.0
@export var min_damage: float = 0.0
@export var radius: float = 80.0
@export var knockback_strength: float = 400.0
@export var damage_type: StringName = &"explosive"
@export var weapon_id: StringName = &""
@export var self_damage_scale: float = 1.0  # rocket-jump: 0.5 = half self-damage
@export var collision_mask: int = 0xFFFFFFFF

## Apply radial damage at `center` in `world`. Returns number of pawns hit.
func apply(world: World2D, center: Vector2, instigator: Node) -> int:
	if world == null:
		return 0
	var space := world.direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform2D(0.0, center)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = collision_mask

	var hits: Array[Dictionary] = space.intersect_shape(query, 32)
	var n_hit: int = 0
	for hit in hits:
		var collider: Object = hit.collider
		if not (collider is Pawn):
			continue
		var victim: Pawn = collider as Pawn
		var to: Vector2 = victim.global_position - center
		var dist: float = to.length()
		var falloff: float = clampf(1.0 - dist / radius, 0.0, 1.0)
		var damage: float = lerpf(min_damage, max_damage, falloff)
		var is_self: bool = victim == instigator
		if is_self:
			damage *= self_damage_scale
		if damage <= 0.0:
			continue
		var kb_dir: Vector2 = to.normalized() if dist > 0.01 else Vector2.UP
		var info := DamageInfo.new()
		info.amount = damage
		info.damage_type = damage_type
		info.knockback = kb_dir * knockback_strength * falloff
		info.radius = radius
		info.weapon_id = weapon_id
		info.is_self_damage = is_self
		info.set_instigator(instigator)
		victim.apply_damage(info)
		n_hit += 1
	return n_hit

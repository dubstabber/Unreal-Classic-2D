class_name FlakShard
extends Projectile

@export var max_bounces: int = 2
@export var bounce_damping: float = 0.65

var _bounces: int = 0

func _ready() -> void:
	super._ready()
	add_to_group(&"flak_shard")
	affected_by_gravity = true
	gravity_scale = 0.5
	rotate_to_velocity = true
	var spr: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		spr.texture = SpriteBaker.get_texture(&"flak_shard")

func _on_body_entered(body: Node) -> void:
	if body == instigator:
		return
	if body is Pawn:
		var info := DamageInfo.make(damage, damage_type, instigator, weapon_id)
		info.knockback = velocity.normalized() * knockback_strength
		(body as Pawn).apply_damage(info)
		impacted.emit(body, global_position)
		queue_free()
		return
	# World hit — bounce or die
	if _bounces < max_bounces:
		_bounce()
		_bounces += 1
	else:
		queue_free()

func _bounce() -> void:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var prev_pos: Vector2 = global_position - velocity * (1.0 / 60.0)
	var query := PhysicsRayQueryParameters2D.create(prev_pos, global_position + velocity.normalized() * 4.0)
	query.collision_mask = 1
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		# Fallback: nudge back and zero velocity
		velocity *= -bounce_damping
		return
	var n: Vector2 = hit.normal
	velocity = velocity.bounce(n) * bounce_damping
	global_position = hit.position + n * 1.5

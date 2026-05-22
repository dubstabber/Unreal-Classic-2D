class_name FlakGrenade
extends Projectile

const FLAK_SHARD_SCENE := preload("res://scenes/projectiles/flak_shard.tscn")

@export var radial_damage: RadialDamage
@export var shard_count: int = 6
@export var shard_damage: float = 10.0
@export var explosion_radius_visual: float = 36.0
@export var explosion_shake: float = 7.0

func _ready() -> void:
	super._ready()
	add_to_group(&"flak_grenade")
	affected_by_gravity = true
	gravity_scale = 1.0
	rotate_to_velocity = false
	var spr: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		spr.texture = SpriteBaker.get_texture(&"flak_grenade")

func on_impact(_target: Node) -> void:
	_explode()

func _expire() -> void:
	_explode()

func _explode() -> void:
	if not is_inside_tree():
		return
	if radial_damage == null:
		radial_damage = RadialDamage.new()
		radial_damage.max_damage = 70.0
		radial_damage.min_damage = 10.0
		radial_damage.radius = 42.0
		radial_damage.knockback_strength = 420.0
		radial_damage.damage_type = &"explosive"
		radial_damage.weapon_id = &"flak_cannon.alt"
		radial_damage.self_damage_scale = 0.5
	radial_damage.apply(get_world_2d(), global_position, instigator)
	Explosion.spawn(get_tree().current_scene, global_position, explosion_radius_visual, explosion_shake)
	# Throw out shards radially
	for i in shard_count:
		var angle: float = TAU * float(i) / float(shard_count) + randf_range(-0.1, 0.1)
		var dir: Vector2 = Vector2.RIGHT.rotated(angle)
		var shard: FlakShard = FLAK_SHARD_SCENE.instantiate() as FlakShard
		shard.damage = shard_damage
		get_tree().current_scene.add_child(shard)
		shard.launch(global_position, dir, instigator)
	queue_free()

class_name BioGlob
extends Projectile

const BIO_POOL_SCENE := preload("res://scenes/projectiles/bio_pool.tscn")

@export var split_count: int = 1
@export var size_scale: float = 1.0
@export var split_spread: float = 18.0

func _ready() -> void:
	super._ready()
	add_to_group(&"bio_glob")
	affected_by_gravity = true
	gravity_scale = 0.8
	rotate_to_velocity = false
	var spr: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		spr.texture = SpriteBaker.get_texture(&"bio_glob")
		spr.scale = Vector2(size_scale, size_scale)

func on_impact(target: Node) -> void:
	# Direct impact on pawn already applies damage in base. Now spawn pools where we landed.
	_spawn_pools(target is Pawn)

func _expire() -> void:
	_spawn_pools(false)

func _spawn_pools(direct_hit: bool) -> void:
	if not is_inside_tree():
		return
	var n: int = 1 if direct_hit else split_count
	for i in n:
		var pool: BioPool = BIO_POOL_SCENE.instantiate() as BioPool
		var offset: Vector2 = Vector2.ZERO
		if n > 1:
			offset = Vector2(((float(i) / float(n - 1)) * 2.0 - 1.0) * split_spread * size_scale, 0)
		pool.global_position = global_position + offset
		pool.damage = damage
		pool.instigator = instigator
		get_tree().current_scene.add_child(pool)
	queue_free()

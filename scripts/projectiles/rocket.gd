class_name Rocket
extends Projectile

@export var radial_damage: RadialDamage
@export var explosion_radius: float = 44.0
@export var explosion_shake: float = 9.0

func _ready() -> void:
	super._ready()
	add_to_group(&"rocket")
	var spr: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		spr.texture = SpriteBaker.get_texture(&"rocket")

func on_impact(_target: Node) -> void:
	_explode()

func _expire() -> void:
	# Rockets explode at end of life too (UT-style).
	_explode()

func _explode() -> void:
	if not is_inside_tree():
		return
	if radial_damage != null:
		radial_damage.apply(get_world_2d(), global_position, instigator)
	Explosion.spawn(get_tree().current_scene, global_position, explosion_radius, explosion_shake)
	queue_free()

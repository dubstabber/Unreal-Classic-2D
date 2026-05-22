class_name ShockOrb
extends Projectile
## Shock Rifle alt-fire projectile. Carries a `RadialDamage` resource it applies
## on impact OR when detonated by a shock beam (the iconic shock combo).

@export var radial_damage: RadialDamage
@export var combo_radial: RadialDamage   # used when detonated by the beam (larger radius / damage)

func _ready() -> void:
	super._ready()
	add_to_group(&"shock_orb")
	# Visual is built in-scene as a Sprite2D child; texture filled here.
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		spr.texture = SpriteBaker.get_texture(&"shock_orb")

func detonate(source: Node) -> void:
	if not is_inside_tree():
		return
	var radial: RadialDamage = combo_radial if combo_radial != null else radial_damage
	if radial != null:
		radial.apply(get_world_2d(), global_position, source)
	_spawn_burst()
	queue_free()

func on_impact(_target: Node) -> void:
	if radial_damage != null and is_inside_tree():
		radial_damage.apply(get_world_2d(), global_position, instigator)
	_spawn_burst()
	queue_free()

func _spawn_burst() -> void:
	# Phase 3 placeholder: a brief expanding ring polygon. Replaced by particles in Phase 8.
	var ring := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 12:
		var a: float = TAU * float(i) / 12.0
		pts.append(Vector2(cos(a), sin(a)) * 6.0)
	ring.polygon = pts
	ring.color = SpriteBaker.palette.get_color(&"shock_purple", Color(0.7, 0.4, 1, 1))
	ring.global_position = global_position
	ring.top_level = true
	get_tree().current_scene.add_child(ring)
	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(3, 3), 0.18)
	tw.tween_property(ring, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(ring.queue_free)

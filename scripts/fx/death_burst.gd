class_name DeathBurst
extends Node2D
## Death effect: a handful of small Polygon2D shards launched outward with gravity + fade.

const FRAGMENT_COUNT := 7
const LIFETIME := 0.9
const GRAVITY := 600.0

static func spawn(scene_root: Node, at: Vector2, tint: Color = Color(1, 0.4, 0.4, 1)) -> DeathBurst:
	var d := DeathBurst.new()
	scene_root.add_child(d)
	d.global_position = at
	d._spawn_shards(tint)
	return d

func _spawn_shards(tint: Color) -> void:
	for i in FRAGMENT_COUNT:
		var shard := Polygon2D.new()
		var size: float = randf_range(1.5, 3.0)
		shard.polygon = PackedVector2Array([
			Vector2(-size, -size), Vector2(size, -size),
			Vector2(size, size), Vector2(-size, size),
		])
		shard.color = tint
		shard.position = Vector2(randf_range(-2, 2), randf_range(-4, 4))
		shard.set_meta(&"vel", Vector2(randf_range(-90, 90), randf_range(-180, -40)))
		add_child(shard)
	# Brief blood/burst flash
	var flash := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 8:
		var a: float = TAU * float(i) / 8.0
		pts.append(Vector2(cos(a), sin(a)) * 8.0)
	flash.polygon = pts
	flash.color = Color(1, 1, 1, 0.9)
	add_child(flash)
	var tw := flash.create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "scale", Vector2(1.6, 1.6), 0.18)
	tw.tween_property(flash, "modulate:a", 0.0, 0.18)

	var death_timer := get_tree().create_timer(LIFETIME)
	death_timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	for child in get_children():
		if not (child is Polygon2D):
			continue
		var poly: Polygon2D = child
		if not poly.has_meta(&"vel"):
			continue
		var vel: Vector2 = poly.get_meta(&"vel")
		vel.y += GRAVITY * delta
		poly.set_meta(&"vel", vel)
		poly.position += vel * delta
		# Fade out in the last half of life
		var t: float = 1.0 - clampf(float(get_meta(&"_t", 0)) / LIFETIME, 0.0, 1.0)
		poly.modulate.a = clampf(t * 2.0, 0.0, 1.0)
	set_meta(&"_t", float(get_meta(&"_t", 0)) + delta)

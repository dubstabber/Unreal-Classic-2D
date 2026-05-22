class_name Explosion
extends Node2D
## One-shot pixel-art explosion: flash + light + particle burst + screen shake.
## Built in code so any caller can spawn it via Explosion.spawn(scene_root, position, intensity).

@export var radius: float = 40.0
@export var shake_magnitude: float = 7.0
@export var lifetime: float = 0.55

const Palette := preload("res://scripts/art/palette.gd")

static func spawn(scene_root: Node, at: Vector2, radius_px: float = 40.0, shake_mag: float = 7.0) -> Explosion:
	var e := Explosion.new()
	e.radius = radius_px
	e.shake_magnitude = shake_mag
	e.global_position = at
	scene_root.add_child(e)
	return e

func _ready() -> void:
	top_level = true
	EventBus.shake_requested.emit(shake_magnitude)
	_spawn_flash()
	_spawn_light()
	_spawn_particles()
	var t: SceneTreeTimer = get_tree().create_timer(lifetime)
	t.timeout.connect(queue_free)

func _spawn_flash() -> void:
	# Hot white ring that fades. Quantized alpha keeps the pixel-art feel.
	var ring := Polygon2D.new()
	var pts := PackedVector2Array()
	var segments := 16
	for i in segments:
		var a: float = TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius * 0.7)
	ring.polygon = pts
	ring.color = SpriteBaker.palette.get_color(&"laser_white", Color(1, 1, 1, 1))
	add_child(ring)
	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(1.4, 1.4), 0.18)
	tw.tween_property(ring, "modulate:a", 0.0, 0.18)

	# Outer fireball — orange, expands more slowly
	var fire := Polygon2D.new()
	var fire_pts := PackedVector2Array()
	for i in segments:
		var a: float = TAU * float(i) / float(segments)
		fire_pts.append(Vector2(cos(a), sin(a)) * radius)
	fire.polygon = fire_pts
	fire.color = SpriteBaker.palette.get_color(&"flak_orange", Color(1, 0.55, 0.15, 1))
	fire.modulate.a = 0.6
	add_child(fire)
	var tw2 := fire.create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(fire, "scale", Vector2(1.2, 1.2), lifetime * 0.7)
	tw2.tween_property(fire, "modulate:a", 0.0, lifetime * 0.7)

func _spawn_light() -> void:
	var light := PointLight2D.new()
	light.texture = SpriteBaker.get_texture(&"radial_falloff")
	light.energy = 2.5
	light.texture_scale = radius / 8.0
	add_child(light)
	var tw := light.create_tween()
	tw.tween_property(light, "energy", 0.0, lifetime * 0.6)

func _spawn_particles() -> void:
	var p := GPUParticles2D.new()
	p.amount = 24
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 0.95
	p.texture = SpriteBaker.get_texture(&"explosion_particle")
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = radius * 1.5
	mat.initial_velocity_max = radius * 3.0
	mat.gravity = Vector3(0, 220, 0)
	mat.damping_min = 60.0
	mat.damping_max = 140.0
	mat.scale_min = 1.0
	mat.scale_max = 2.5
	var ramp := Gradient.new()
	ramp.add_point(0.0, SpriteBaker.palette.get_color(&"laser_white", Color(1, 1, 1, 1)))
	ramp.add_point(0.25, SpriteBaker.palette.get_color(&"plasma_hot", Color(1, 0.9, 0.4, 1)))
	ramp.add_point(0.65, SpriteBaker.palette.get_color(&"flak_orange", Color(1, 0.55, 0.15, 1)))
	ramp.add_point(1.0, Color(0.15, 0.05, 0.05, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = ramp
	mat.color_ramp = tex
	p.process_material = mat
	add_child(p)

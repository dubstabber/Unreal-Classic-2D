class_name DamageIndicator
extends Control
## Brief arc segment at the screen edge pointing toward damage direction.
## Spawn via DamageIndicator.spawn(parent, viewport_size, world_dir_from_victim).

@export var fade_seconds: float = 1.2

var _texture: Texture2D
var _spr: TextureRect

static func spawn(parent: Control, viewport_size: Vector2, dir_from_victim: Vector2) -> DamageIndicator:
	var di := DamageIndicator.new()
	parent.add_child(di)
	di._configure(viewport_size, dir_from_victim)
	return di

func _configure(viewport_size: Vector2, dir_from_victim: Vector2) -> void:
	_texture = SpriteBaker.get_texture(&"hud_dmg_arc")
	_spr = TextureRect.new()
	_spr.texture = _texture
	_spr.pivot_offset = Vector2(8, 4)
	add_child(_spr)
	# Position center of viewport, place arc near edge in the threat direction.
	var center: Vector2 = viewport_size * 0.5
	var dir: Vector2 = dir_from_victim.normalized() if dir_from_victim.length_squared() > 0.001 else Vector2.UP
	# Distance from center to screen edge along this direction (with margin)
	var screen_radius: float = minf(viewport_size.x, viewport_size.y) * 0.40
	var pos: Vector2 = center + dir * screen_radius
	# Center the arc on this position
	_spr.position = pos - Vector2(8, 4)
	# Rotate the arc to be tangent to the edge (perpendicular to the direction).
	# Arc texture points up by default → align "up" with -dir so arc curls outward.
	_spr.rotation = dir.angle() + PI * 0.5
	var tw := create_tween()
	tw.tween_property(_spr, "modulate:a", 0.0, fade_seconds)
	tw.tween_callback(queue_free)

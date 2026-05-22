class_name ShockBeam
extends Node2D
## Hitscan beam visual — Line2D from origin to hit point, alpha-quantized fade,
## briefly hot-white core. Created via `ShockBeam.spawn(scene_root, from, to)`.

const LIFETIME := 0.12

var _from: Vector2
var _to: Vector2
var _t: float = 0.0
var _line: Line2D
var _core: Line2D

static func spawn(scene_root: Node, from: Vector2, to: Vector2) -> ShockBeam:
	var b := ShockBeam.new()
	b._from = from
	b._to = to
	scene_root.add_child(b)
	return b

func _ready() -> void:
	top_level = true
	_line = _make_line(2.0, SpriteBaker.palette.get_color(&"shock_purple", Color(0.7, 0.4, 1, 1)))
	_core = _make_line(1.0, SpriteBaker.palette.get_color(&"laser_white", Color(1, 1, 1, 1)))
	add_child(_line)
	add_child(_core)

func _make_line(width: float, color: Color) -> Line2D:
	var l := Line2D.new()
	l.add_point(_from)
	l.add_point(_to)
	l.width = width
	l.default_color = color
	return l

func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFETIME:
		queue_free()
		return
	# 4-step quantized alpha fade for the pixel-art look
	var a: float = 1.0 - (_t / LIFETIME)
	a = ceilf(a * 4.0) / 4.0
	_line.modulate.a = a
	_core.modulate.a = a

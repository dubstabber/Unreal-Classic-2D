class_name FloatingText
extends Node2D
## A small text label that rises + fades. Used for frag popups, damage numbers, etc.

const RISE_SPEED := 24.0
const LIFETIME := 1.0

var _label: Label
var _t: float = 0.0

static func spawn(scene_root: Node, at: Vector2, text: String, color: Color = Color(1, 0.95, 0.6, 1)) -> FloatingText:
	var f := FloatingText.new()
	scene_root.add_child(f)
	f.global_position = at
	f._setup(text, color)
	return f

func _setup(text: String, color: Color) -> void:
	_label = Label.new()
	_label.text = text
	_label.position = Vector2(-12, -16)
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)

func _process(delta: float) -> void:
	_t += delta
	position.y -= RISE_SPEED * delta
	if _t > LIFETIME * 0.5:
		var fade_t: float = (_t - LIFETIME * 0.5) / (LIFETIME * 0.5)
		modulate.a = clampf(1.0 - fade_t, 0.0, 1.0)
	if _t >= LIFETIME:
		queue_free()

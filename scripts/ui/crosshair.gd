extends Control
## Mouse-following crosshair, drawn procedurally to match the pixel-art look.
## Style + color come from the active profile's gameplay options.
## Styles: 0 = Cross, 1 = Dot, 2 = Circle.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var g: Dictionary = Profiles.gameplay()
	var style: int = int(g.get("crosshair_style", 0))
	var col: Color = g.get("crosshair_color", Color.WHITE)
	var p: Vector2 = get_local_mouse_position().round()
	match style:
		1:  # Dot
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), col)
		2:  # Circle
			draw_arc(p, 5.0, 0.0, TAU, 24, col, 1.0)
			draw_rect(Rect2(p, Vector2(1, 1)), col)
		_:  # Cross (default)
			draw_rect(Rect2(p + Vector2(-5, 0), Vector2(3, 1)), col)
			draw_rect(Rect2(p + Vector2(3, 0), Vector2(3, 1)), col)
			draw_rect(Rect2(p + Vector2(0, -5), Vector2(1, 3)), col)
			draw_rect(Rect2(p + Vector2(0, 3), Vector2(1, 3)), col)

class_name SpawnIndicator
extends Node2D
## A downward-pointing arrow that bobs above the local player for a few seconds
## after spawn/respawn, so the player can find which character is theirs.
## Drawn procedurally to match the codegen pixel-art look.

const BASE_Y := -22.0  ## pixels above the pawn origin (above the head sprite)
const BOB_AMPLITUDE := 2.0
const BOB_SPEED := 6.0

var color: Color = Color(1, 1, 1, 1)
var _remaining: float = 0.0
var _t: float = 0.0

func _ready() -> void:
	z_index = 50
	visible = false

## Show the arrow for `seconds`, resetting the timer if already visible.
func show_for(seconds: float = 2.5) -> void:
	_remaining = seconds
	_t = 0.0
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_remaining -= delta
	if _remaining <= 0.0:
		visible = false
		return
	position.y = (BASE_Y + sin(_t * BOB_SPEED) * BOB_AMPLITUDE)
	# Fade out over the final half-second.
	modulate.a = clampf(_remaining / 0.5, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	# Filled chevron pointing down, with a 1px dark outline for contrast.
	var outline := Color(0, 0, 0, modulate.a)
	var tip := Vector2(0, 6)
	var left := Vector2(-5, -3)
	var right := Vector2(5, -3)
	draw_colored_polygon(PackedVector2Array([left + Vector2(0, -1), right + Vector2(0, -1), tip + Vector2(0, 1)]), outline)
	draw_colored_polygon(PackedVector2Array([left, right, tip]), color)

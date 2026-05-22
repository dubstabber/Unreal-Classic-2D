class_name CameraRig
extends Camera2D
## Frame-rate-independent smoothed look-ahead camera with screen shake.
## Final position is pixel-snapped so the pixel-art grid never sub-shifts.

## Baseline zoom. The arena is the same size as the screen, so 1× would lock the
## camera on the whole map; >1 zooms in so the camera can follow + center the player.
@export var base_zoom: float = 2.0
@export var look_ahead_weight: float = 0.22
@export var look_ahead_max: float = 40.0
@export var smoothing_k: float = 6.0
@export var shake_decay: float = 22.0

var _smoothed_offset: Vector2 = Vector2.ZERO
var _shake_intensity: float = 0.0

func _ready() -> void:
	make_current()
	zoom = Vector2(base_zoom, base_zoom)
	position_smoothing_enabled = false
	EventBus.shake_requested.connect(_on_shake_requested)
	EventBus.zoom_requested.connect(_on_zoom_requested)

func _process(delta: float) -> void:
	var host := get_parent() as Node2D
	if host == null:
		return
	var mouse_world: Vector2 = get_global_mouse_position()
	var to_mouse: Vector2 = mouse_world - host.global_position
	var desired: Vector2 = (to_mouse * look_ahead_weight).limit_length(look_ahead_max)
	var t: float = 1.0 - exp(-smoothing_k * delta)
	_smoothed_offset = _smoothed_offset.lerp(desired, t)
	var shake: Vector2 = Vector2.ZERO
	if _shake_intensity > 0.01:
		shake = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_intensity
		_shake_intensity = maxf(0.0, _shake_intensity - shake_decay * delta)
	offset = (_smoothed_offset + shake).round()

func add_shake(intensity: float) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)

func _on_shake_requested(intensity: float) -> void:
	# Scale by the player's gameplay preference (0 disables shake entirely).
	add_shake(intensity * float(Profiles.gameplay().get("screen_shake", 1.0)))

func _on_zoom_requested(level: float) -> void:
	# Smoothly tween zoom toward the requested level. Pixel-art look favours snapping —
	# but instantly snapping causes head-fuck on toggle, so we use a short tween.
	# `level` is relative to base_zoom: 1.0 = default framing, >1 = scoped in (sniper).
	var target := Vector2(base_zoom * level, base_zoom * level)
	var tw := create_tween()
	tw.tween_property(self, "zoom", target, 0.12)

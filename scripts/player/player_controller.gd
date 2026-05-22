class_name PlayerController
extends PawnController
## The ONLY place that reads `Input`. All other game systems route through PawnController.

var pawn: Pawn = null  # set by Pawn.set_controller

const _DIR_TAP_LEFT := -1
const _DIR_TAP_RIGHT := 1

var _last_dir_tap: int = 0          # -1 / 0 / +1
var _last_dir_tap_msec: int = 0
var _dodge_cooldown_until_msec: int = 0
var _tap_window_msec: int = 300
var _dodge_cooldown_msec: int = 700

func bind_pawn(p: Pawn) -> void:
	pawn = p
	if pawn != null and pawn.stats != null:
		_tap_window_msec = pawn.stats.dodge_tap_window_msec
		_dodge_cooldown_msec = pawn.stats.dodge_cooldown_msec

func _physics_process(_delta: float) -> void:
	# Sustained intents — sampled each tick.
	wish_move = Input.get_axis(&"move_left", &"move_right")
	wish_crouch = Input.is_action_pressed(&"crouch")
	wish_jump_held = Input.is_action_pressed(&"jump")
	wish_fire_primary = Input.is_action_pressed(&"primary_fire")
	wish_fire_alt = Input.is_action_pressed(&"secondary_fire")
	if pawn != null:
		aim_target = pawn.get_global_mouse_position()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey or event is InputEventMouseButton):
		return
	if event.is_action_pressed(&"jump"):
		push_event(&"jump_pressed")
	if event.is_action_pressed(&"move_left"):
		_on_dir_tap(_DIR_TAP_LEFT)
	if event.is_action_pressed(&"move_right"):
		_on_dir_tap(_DIR_TAP_RIGHT)
	for slot in range(10):
		if event.is_action_pressed(StringName("slot_%d" % slot)):
			push_event(StringName("slot_%d" % slot))

func _on_dir_tap(dir: int) -> void:
	var now: int = Time.get_ticks_msec()
	if now < _dodge_cooldown_until_msec:
		_last_dir_tap = dir
		_last_dir_tap_msec = now
		return
	if dir == _last_dir_tap and (now - _last_dir_tap_msec) <= _tap_window_msec:
		var ev: StringName = &"dodge_left" if dir < 0 else &"dodge_right"
		push_event(ev)
		_dodge_cooldown_until_msec = now + _dodge_cooldown_msec
		_last_dir_tap = 0
	else:
		_last_dir_tap = dir
		_last_dir_tap_msec = now

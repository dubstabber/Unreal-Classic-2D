class_name BotCombat
extends Node
## Aim with Gaussian error, weapon preference by distance, reaction time gate.

var bot: Pawn = null

@export var aim_error_stddev: float = 8.0  # px, std deviation of aim jitter
@export var aim_jitter_interval_msec: int = 220
@export var reaction_time_msec: int = 200

# Distance-keyed weapon preference. Closest match wins.
# Each entry is [max_distance_inclusive, slot]. Order matters — first match wins.
# Loadout is currently Enforcer-only (slot 2) for all pawns.
@export var weapon_preference: Array[Vector2] = [
	Vector2(1000.0, 2.0),  # always: Enforcer
]

var _last_target: Pawn = null
var _target_acquired_msec: int = 0
var _current_aim_offset: Vector2 = Vector2.ZERO
var _next_aim_jitter_msec: int = 0

func bind(p: Pawn) -> void:
	bot = p

func compute_aim_target(target: Pawn) -> Vector2:
	if target == null or bot == null:
		return Vector2.ZERO
	var now: int = Time.get_ticks_msec()
	if target != _last_target:
		_last_target = target
		_target_acquired_msec = now
	if now > _next_aim_jitter_msec:
		_next_aim_jitter_msec = now + aim_jitter_interval_msec
		_current_aim_offset = Vector2(_gauss() * aim_error_stddev, _gauss() * aim_error_stddev)
	return target.global_position + _current_aim_offset

func can_fire(target: Pawn) -> bool:
	if target == null or bot == null:
		return false
	return Time.get_ticks_msec() - _target_acquired_msec >= reaction_time_msec

func pick_weapon_slot(distance: float) -> int:
	for entry in weapon_preference:
		if distance <= entry.x:
			return int(entry.y)
	return 0

func _gauss() -> float:
	# Box-Muller. Cheap enough; never called in tight loops here.
	var u: float = maxf(randf(), 0.0001)
	var v: float = randf()
	return sqrt(-2.0 * log(u)) * cos(TAU * v)

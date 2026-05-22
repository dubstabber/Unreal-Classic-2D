class_name Enforcer
extends Weapon
## Slot 2. Hitscan pistol. Primary = aimed single shot, Alt = rapid auto-fire with spread.
## Akimbo (second pickup) is wired in Phase 6 — for now just single-handed.

@export var range: float = 480.0
@export var primary_spread: float = 0.015
@export var alt_spread: float = 0.16
@export var alt_damage_ratio: float = 0.7
@export var knockback: float = 35.0

func primary_fire() -> void:
	_hitscan(primary_spread, data.primary_damage, &"enforcer.primary")
	EventBus.shake_requested.emit(1.2)

func alt_fire() -> void:
	_hitscan(alt_spread, data.primary_damage * alt_damage_ratio, &"enforcer.alt")
	EventBus.shake_requested.emit(0.6)

func _hitscan(spread: float, damage: float, wid: StringName) -> void:
	if pawn == null:
		return
	var origin: Vector2 = barrel_position()
	var dir: Vector2 = aim_direction().rotated(randf_range(-spread, spread))
	var end: Vector2 = origin + dir * range

	var space: PhysicsDirectSpaceState2D = pawn.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(origin, end)
	query.exclude = [pawn.get_rid()]
	query.collision_mask = 1 | 2
	var hit: Dictionary = space.intersect_ray(query)
	if not hit.is_empty():
		end = hit.position
		if hit.collider is Pawn:
			var info := DamageInfo.make(damage, &"projectile", pawn, wid)
			info.knockback = dir * knockback
			(hit.collider as Pawn).apply_damage(info)
	_spawn_tracer(origin, end)

func _spawn_tracer(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.top_level = true
	line.add_point(from)
	line.add_point(to)
	line.width = 1.0
	line.default_color = SpriteBaker.palette.get_color(&"plasma_hot", Color(1, 0.9, 0.5, 1))
	pawn.get_tree().current_scene.add_child(line)
	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.06)
	tw.tween_callback(line.queue_free)

class_name SniperRifle
extends Weapon
## Slot 0. High-damage hitscan with headshot multiplier (primary). Alt toggles zoom.

@export var range: float = 600.0
@export var headshot_multiplier: float = 2.0
@export var head_zone_y_offset: float = -3.0  # below this in pawn-local Y = head
@export var zoom_level: float = 1.6
@export var knockback: float = 90.0

var _zoomed: bool = false
var _alt_was_held: bool = false

func tick(delta: float) -> void:
	_primary_cooldown = maxf(0.0, _primary_cooldown - delta)
	_alt_cooldown = maxf(0.0, _alt_cooldown - delta)
	if pawn == null or pawn.controller == null or data == null:
		return

	if pawn.controller.wish_fire_primary and _primary_cooldown <= 0.0:
		if _consume_ammo(data.ammo_per_shot_primary):
			primary_fire()
			_primary_cooldown = data.primary_fire_rate
			fired.emit(&"primary")

	# Alt is a TOGGLE on rising edge — switches zoom level.
	var alt_held: bool = pawn.controller.wish_fire_alt
	if alt_held and not _alt_was_held and _alt_cooldown <= 0.0:
		toggle_zoom()
		_alt_cooldown = data.alt_fire_rate
	_alt_was_held = alt_held

func toggle_zoom() -> void:
	_zoomed = not _zoomed
	EventBus.zoom_requested.emit(zoom_level if _zoomed else 1.0)
	fired.emit(&"alt")

func primary_fire() -> void:
	if pawn == null:
		return
	var origin: Vector2 = barrel_position()
	var dir: Vector2 = aim_direction()
	var space: PhysicsDirectSpaceState2D = pawn.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(origin, origin + dir * range)
	query.exclude = [pawn.get_rid()]
	query.collision_mask = 1 | 2
	var hit: Dictionary = space.intersect_ray(query)
	var end: Vector2 = origin + dir * range
	var was_headshot: bool = false
	if not hit.is_empty():
		end = hit.position
		if hit.collider is Pawn:
			var victim: Pawn = hit.collider as Pawn
			var local_y: float = hit.position.y - victim.global_position.y
			was_headshot = local_y < head_zone_y_offset
			var damage: float = data.primary_damage * (headshot_multiplier if was_headshot else 1.0)
			var info := DamageInfo.make(damage, &"projectile", pawn, &"sniper_rifle.primary")
			info.knockback = dir * knockback
			victim.apply_damage(info)
			if was_headshot:
				EventBus.headshot.emit(pawn, victim)
	_spawn_tracer(origin, end, was_headshot)
	EventBus.shake_requested.emit(2.5)

func _spawn_tracer(from: Vector2, to: Vector2, headshot_hit: bool) -> void:
	var line := Line2D.new()
	line.top_level = true
	line.add_point(from)
	line.add_point(to)
	line.width = 1.0
	var c: Color
	if headshot_hit:
		c = SpriteBaker.palette.get_color(&"hp_low", Color(1, 0.3, 0.2, 1))
	else:
		c = SpriteBaker.palette.get_color(&"laser_blue", Color(0.4, 0.85, 1, 1))
	line.default_color = c
	pawn.get_tree().current_scene.add_child(line)
	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.18)
	tw.tween_callback(line.queue_free)

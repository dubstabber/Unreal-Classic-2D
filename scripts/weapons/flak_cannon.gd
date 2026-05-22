class_name FlakCannon
extends Weapon
## Slot 8. Primary fires a cone of bouncing shards; alt arcs a grenade that bursts into shards.

const FLAK_SHARD_SCENE := preload("res://scenes/projectiles/flak_shard.tscn")
const FLAK_GRENADE_SCENE := preload("res://scenes/projectiles/flak_grenade.tscn")

@export var primary_shard_count: int = 9
@export var primary_spread_radians: float = 0.45  # half-angle of the cone
@export var primary_shard_damage: float = 13.0
@export var primary_speed_jitter: float = 0.18

func primary_fire() -> void:
	var base_dir: Vector2 = aim_direction()
	var origin: Vector2 = barrel_position()
	for i in primary_shard_count:
		var angle: float = randf_range(-primary_spread_radians, primary_spread_radians)
		var dir: Vector2 = base_dir.rotated(angle)
		var shard: FlakShard = FLAK_SHARD_SCENE.instantiate() as FlakShard
		shard.damage = primary_shard_damage
		shard.speed *= 1.0 + randf_range(-primary_speed_jitter, primary_speed_jitter)
		pawn.get_tree().current_scene.add_child(shard)
		shard.launch(origin, dir, pawn)
	EventBus.shake_requested.emit(4.5)

func alt_fire() -> void:
	var g: FlakGrenade = FLAK_GRENADE_SCENE.instantiate() as FlakGrenade
	pawn.get_tree().current_scene.add_child(g)
	g.launch(barrel_position(), aim_direction(), pawn)
	EventBus.shake_requested.emit(3.0)

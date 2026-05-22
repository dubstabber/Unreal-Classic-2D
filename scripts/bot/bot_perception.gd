class_name BotPerception
extends Node
## LOS checks against other pawns + nearby threat scan.

var bot: Pawn = null
var visible_enemies: Array[Pawn] = []
var nearest_threat: Node2D = null

@export var threat_radius: float = 96.0

func bind(p: Pawn) -> void:
	bot = p

func update() -> void:
	visible_enemies.clear()
	if bot == null or not bot.is_alive():
		nearest_threat = null
		return
	var space: PhysicsDirectSpaceState2D = bot.get_world_2d().direct_space_state
	for n in bot.get_tree().get_nodes_in_group(&"pawn"):
		var p: Pawn = n as Pawn
		if p == null or p == bot or not p.is_alive():
			continue
		# Same team = ally
		if p.team != &"" and p.team == bot.team:
			continue
		var q := PhysicsRayQueryParameters2D.create(bot.global_position, p.global_position)
		q.exclude = [bot.get_rid(), p.get_rid()]
		q.collision_mask = 1  # world only
		var hit: Dictionary = space.intersect_ray(q)
		if hit.is_empty():
			visible_enemies.append(p)
	nearest_threat = _find_threat()

func get_closest_enemy() -> Pawn:
	if visible_enemies.is_empty():
		return null
	var closest: Pawn = visible_enemies[0]
	var best_d: float = bot.global_position.distance_squared_to(closest.global_position)
	for e in visible_enemies:
		var d: float = bot.global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			closest = e
	return closest

func _find_threat() -> Node2D:
	var closest: Node2D = null
	var best_d: float = threat_radius * threat_radius
	for g in [&"rocket", &"flak_grenade"]:
		for n in bot.get_tree().get_nodes_in_group(g):
			var node2d: Node2D = n as Node2D
			if node2d == null:
				continue
			# Ignore our own outgoing projectile
			if "instigator" in node2d and node2d.instigator == bot:
				continue
			var d: float = bot.global_position.distance_squared_to(node2d.global_position)
			if d < best_d:
				best_d = d
				closest = node2d
	return closest

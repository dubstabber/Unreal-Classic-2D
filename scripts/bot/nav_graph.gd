class_name NavGraph
extends Node
## AStar2D-backed pathfinding over auto-discovered NavNodes.
## Built on _ready by scanning the scene for &"nav_node"-group Marker2Ds and
## connecting any pair within `max_edge_distance` that has line-of-sight and
## whose vertical delta is reachable by a jump.

@export var max_edge_distance: float = 220.0
@export var max_climb_per_jump: float = 90.0  # how high a bot can jump (vertical px)
@export var auto_build_on_ready: bool = true
@export var require_los: bool = true

var astar: AStar2D = AStar2D.new()

func _ready() -> void:
	if auto_build_on_ready:
		# Defer to give NavNodes time to enter the tree and register.
		call_deferred(&"build_from_scene")

func build_from_scene() -> void:
	astar.clear()
	var nav_nodes: Array[NavNode] = []
	for n in get_tree().get_nodes_in_group(&"nav_node"):
		if n is NavNode:
			nav_nodes.append(n as NavNode)
	for i in nav_nodes.size():
		astar.add_point(i, nav_nodes[i].global_position)
		nav_nodes[i].set_meta(&"nav_id", i)

	var world: World2D = get_world_2d_safe()
	for i in nav_nodes.size():
		for j in range(i + 1, nav_nodes.size()):
			if _can_connect(nav_nodes[i], nav_nodes[j], world):
				astar.connect_points(i, j, true)

func get_world_2d_safe() -> World2D:
	# `Node` doesn't have a 2D world, but the current scene root usually does.
	var scene := get_tree().current_scene
	if scene == null:
		return null
	if scene.has_method(&"get_world_2d"):
		return scene.get_world_2d()
	return null

func _can_connect(a: NavNode, b: NavNode, world: World2D) -> bool:
	var dist: float = a.global_position.distance_to(b.global_position)
	if dist > max_edge_distance:
		return false
	# Don't connect if b is more than a jump above a (or vice versa). Bidirectional
	# edges still get pruned if EITHER direction exceeds the climb limit.
	var dy: float = absf(b.global_position.y - a.global_position.y)
	if dy > max_climb_per_jump:
		return false
	if require_los and world != null:
		var space: PhysicsDirectSpaceState2D = world.direct_space_state
		var q := PhysicsRayQueryParameters2D.create(a.global_position, b.global_position)
		q.collision_mask = 1  # world geometry only
		var hit: Dictionary = space.intersect_ray(q)
		if not hit.is_empty():
			return false
	return true

func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if astar.get_point_count() == 0:
		return PackedVector2Array()
	var start_id: int = astar.get_closest_point(from)
	var end_id: int = astar.get_closest_point(to)
	if start_id < 0 or end_id < 0:
		return PackedVector2Array()
	return astar.get_point_path(start_id, end_id)

func nearest_node_position(pos: Vector2) -> Vector2:
	if astar.get_point_count() == 0:
		return Vector2.ZERO
	return astar.get_point_position(astar.get_closest_point(pos))

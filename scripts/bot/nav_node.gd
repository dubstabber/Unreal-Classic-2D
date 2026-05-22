class_name NavNode
extends Marker2D
## A pathfinding waypoint. NavGraph discovers all NavNodes in the scene and connects
## them automatically based on distance + LOS + vertical reachability.

func _ready() -> void:
	add_to_group(&"nav_node")

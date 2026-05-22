class_name ArenaBuilder
## Programmatic arena geometry. Phase 9 will replace this with TileMapLayer-built arenas.

const TILE := 8
const VIEWPORT_W := 480
const VIEWPORT_H := 270

static func build_default_arena(host: Node2D) -> void:
	_platform(host, Rect2(Vector2(0, 248), Vector2(VIEWPORT_W, 16)))
	_platform(host, Rect2(Vector2(0, 16), Vector2(8, 248)))
	_platform(host, Rect2(Vector2(VIEWPORT_W - 8, 16), Vector2(8, 248)))
	_platform(host, Rect2(Vector2(56, 200), Vector2(80, 8)))
	_platform(host, Rect2(Vector2(344, 200), Vector2(80, 8)))
	_platform(host, Rect2(Vector2(176, 152), Vector2(128, 8)))
	_platform(host, Rect2(Vector2(72, 104), Vector2(48, 8)))
	_platform(host, Rect2(Vector2(360, 104), Vector2(48, 8)))
	_platform(host, Rect2(Vector2(200, 56), Vector2(80, 8)))

static func _platform(host: Node2D, rect: Rect2) -> void:
	var sb := StaticBody2D.new()
	sb.position = rect.position
	host.add_child(sb)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	col.shape = shape
	col.position = rect.size * 0.5
	sb.add_child(col)
	var w_tiles: int = int(ceilf(rect.size.x / float(TILE)))
	var h_tiles: int = int(ceilf(rect.size.y / float(TILE)))
	for tx in w_tiles:
		for ty in h_tiles:
			var s := Sprite2D.new()
			s.texture = SpriteBaker.get_texture(&"tile_solid")
			s.centered = false
			s.position = Vector2(tx * TILE, ty * TILE)
			sb.add_child(s)

static func add_player_start(host: Node2D, at: Vector2) -> Marker2D:
	var m := Marker2D.new()
	m.position = at
	m.add_to_group(&"player_start")
	host.add_child(m)
	return m

static func add_nav_node(host: Node2D, at: Vector2) -> NavNode:
	var n: NavNode = NavNode.new()
	n.position = at
	host.add_child(n)
	return n

static func build_default_nav_nodes(host: Node2D) -> Array[NavNode]:
	# Strategic waypoints across the default arena: floor edges, mid-floor,
	# each platform top, top platform.
	var positions: Array[Vector2] = [
		Vector2(40, 240),   # floor left
		Vector2(240, 240),  # floor mid
		Vector2(440, 240),  # floor right
		Vector2(96, 192),   # platform A
		Vector2(384, 192),  # platform B
		Vector2(240, 144),  # platform C (mid)
		Vector2(96, 96),    # platform D
		Vector2(384, 96),   # platform E
		Vector2(240, 48),   # top platform
	]
	var nodes: Array[NavNode] = []
	for p in positions:
		nodes.append(add_nav_node(host, p))
	return nodes

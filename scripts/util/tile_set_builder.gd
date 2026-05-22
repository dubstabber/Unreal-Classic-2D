class_name TileSetBuilder
## Builds a Godot 4.6 TileSet at runtime from a baked SpriteBaker texture.
## One tile, 8×8, world collision layer 1, square collision polygon.

const TILE_SIZE := 8

static func build_default_tileset(texture_name: StringName = &"tile_solid") -> TileSet:
	# Order matters: add the physics layer to the TileSet, build the source, attach the
	# source to the TileSet (so its TileData knows about the layer), THEN add the
	# collision polygon. Otherwise add_collision_polygon(0) tries to index into an
	# empty physics-layer array on the TileData.
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	ts.add_physics_layer(-1)
	ts.set_physics_layer_collision_layer(0, 1)   # world
	ts.set_physics_layer_collision_mask(0, 0)

	var src := TileSetAtlasSource.new()
	src.texture = SpriteBaker.get_texture(texture_name)
	src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	src.create_tile(Vector2i(0, 0))
	ts.add_source(src, 0)

	var tile_data: TileData = src.get_tile_data(Vector2i(0, 0), 0)
	tile_data.add_collision_polygon(0)
	tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4),
	]))
	return ts

static func fill_rect(layer: TileMapLayer, cell_x: int, cell_y: int, cell_w: int, cell_h: int) -> void:
	for x in range(cell_x, cell_x + cell_w):
		for y in range(cell_y, cell_y + cell_h):
			layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

static func fill_world_rect(layer: TileMapLayer, rect: Rect2i) -> void:
	# rect is in world pixels; converted to cell coords.
	var cx: int = rect.position.x / TILE_SIZE
	var cy: int = rect.position.y / TILE_SIZE
	var cw: int = int(ceilf(float(rect.size.x) / float(TILE_SIZE)))
	var ch: int = int(ceilf(float(rect.size.y) / float(TILE_SIZE)))
	fill_rect(layer, cx, cy, cw, ch)

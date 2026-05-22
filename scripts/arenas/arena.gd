class_name Arena
extends Node2D
## Base class for production arenas. Subclasses override _layout_geometry(),
## _place_nav_nodes(), _place_pickups(), and configure palette tints.

const VIEWPORT_W := 480
const VIEWPORT_H := 270
const TILE := 8

# Arena identity (subclasses set these in _ready before calling super._ready or via override)
@export var display_name: String = "Arena"
@export var arena_tint: Color = Color(1, 1, 1, 1)
@export var bg_top: Color = Color(0.08, 0.10, 0.16, 1)
@export var bg_bottom: Color = Color(0.03, 0.04, 0.07, 1)

var tile_map: TileMapLayer

func _ready() -> void:
	_setup_background()
	_setup_tile_map()
	_layout_geometry()
	_place_nav_nodes()
	_place_player_starts()
	_place_pickups()
	_apply_palette_tint()

# ---- Pipeline (subclasses override) ----

func _layout_geometry() -> void:
	# Default: thin border. Subclasses replace.
	pass

func _place_nav_nodes() -> void:
	pass

func _place_player_starts() -> void:
	pass

func _place_pickups() -> void:
	pass

# ---- Shared setup helpers ----

func _setup_background() -> void:
	var bg := Sprite2D.new()
	var img := _bake_banded_gradient(VIEWPORT_W, VIEWPORT_H, bg_top, bg_bottom, 8)
	bg.texture = ImageTexture.create_from_image(img)
	bg.centered = false
	bg.z_index = -100
	add_child(bg)

func _setup_tile_map() -> void:
	tile_map = TileMapLayer.new()
	tile_map.tile_set = TileSetBuilder.build_default_tileset(&"tile_solid")
	tile_map.collision_enabled = true
	add_child(tile_map)

func _apply_palette_tint() -> void:
	if arena_tint == Color(1, 1, 1, 1):
		return
	var cm := CanvasModulate.new()
	cm.color = arena_tint
	add_child(cm)

# Subclass helpers

func add_floor(world_rect: Rect2i) -> void:
	TileSetBuilder.fill_world_rect(tile_map, world_rect)

func add_player_start(at: Vector2) -> Marker2D:
	return ArenaBuilder.add_player_start(self, at)

func add_nav_node(at: Vector2) -> NavNode:
	return ArenaBuilder.add_nav_node(self, at)

func add_health_pack(at: Vector2, mega: bool = false) -> Pickup:
	var p: HealthPickup
	if mega:
		p = preload("res://scenes/pickups/health_mega.tscn").instantiate() as HealthPickup
	else:
		p = preload("res://scenes/pickups/health_pickup.tscn").instantiate() as HealthPickup
	p.global_position = at
	add_child(p)
	return p

func add_armor(at: Vector2) -> Pickup:
	var p: ArmorPickup = preload("res://scenes/pickups/armor_pickup.tscn").instantiate() as ArmorPickup
	p.global_position = at
	add_child(p)
	return p

func add_ammo(at: Vector2, ammo_type: StringName, amount: int) -> Pickup:
	var p: AmmoPickup = preload("res://scenes/pickups/ammo_pickup.tscn").instantiate() as AmmoPickup
	p.ammo_type = ammo_type
	p.amount = amount
	p.global_position = at
	add_child(p)
	return p

func add_weapon_pickup(at: Vector2, klass: GDScript, data: WeaponData) -> Pickup:
	var p: WeaponPickup = preload("res://scenes/pickups/weapon_pickup.tscn").instantiate() as WeaponPickup
	p.weapon_class = klass
	p.weapon_data = data
	p.global_position = at
	add_child(p)
	return p

# ---- Procedural background image ----

func _bake_banded_gradient(w: int, h: int, top: Color, bottom: Color, bands: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var band: int = int(float(y) / float(h) * float(bands))
		var t: float = float(band) / float(maxi(bands - 1, 1))
		var c: Color = top.lerp(bottom, t)
		for x in w:
			img.set_pixel(x, y, c)
	return img

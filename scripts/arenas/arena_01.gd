extends Arena
## Arena 01 — Foundry. Symmetric DM arena with central elevated platform.
## Orange/industrial palette tint.

const SHOCK_DATA := preload("res://resources/weapons/shock_rifle.tres")
const ROCKET_DATA := preload("res://resources/weapons/rocket_launcher.tres")
const FLAK_DATA := preload("res://resources/weapons/flak_cannon.tres")
const SNIPER_DATA := preload("res://resources/weapons/sniper_rifle.tres")
const BIO_DATA := preload("res://resources/weapons/bio_rifle.tres")

func _init() -> void:
	display_name = "Foundry"
	# Warm industrial tint (Canvas modulate multiplies all in-world colors)
	arena_tint = Color(1.05, 0.85, 0.75, 1)
	bg_top = Color(0.18, 0.10, 0.06, 1)
	bg_bottom = Color(0.04, 0.02, 0.01, 1)

func _layout_geometry() -> void:
	# Floor (2 tiles tall, full width)
	add_floor(Rect2i(Vector2i(0, 248), Vector2i(VIEWPORT_W, 16)))
	# Side walls
	add_floor(Rect2i(Vector2i(0, 16), Vector2i(8, 232)))
	add_floor(Rect2i(Vector2i(VIEWPORT_W - 8, 16), Vector2i(8, 232)))
	# Low-left & low-right platforms
	add_floor(Rect2i(Vector2i(56, 200), Vector2i(64, 8)))
	add_floor(Rect2i(Vector2i(360, 200), Vector2i(64, 8)))
	# Mid platform (wide central catwalk)
	add_floor(Rect2i(Vector2i(144, 152), Vector2i(192, 8)))
	# Upper small platforms (left/right)
	add_floor(Rect2i(Vector2i(80, 104), Vector2i(48, 8)))
	add_floor(Rect2i(Vector2i(352, 104), Vector2i(48, 8)))
	# Top platform (sniper perch)
	add_floor(Rect2i(Vector2i(216, 56), Vector2i(48, 8)))

func _place_nav_nodes() -> void:
	# Floor row
	add_nav_node(Vector2(40, 240))
	add_nav_node(Vector2(140, 240))
	add_nav_node(Vector2(240, 240))
	add_nav_node(Vector2(340, 240))
	add_nav_node(Vector2(440, 240))
	# Low platforms
	add_nav_node(Vector2(88, 192))
	add_nav_node(Vector2(392, 192))
	# Mid platform — three nodes for path variety
	add_nav_node(Vector2(168, 144))
	add_nav_node(Vector2(240, 144))
	add_nav_node(Vector2(312, 144))
	# Upper platforms
	add_nav_node(Vector2(104, 96))
	add_nav_node(Vector2(376, 96))
	# Top platform
	add_nav_node(Vector2(240, 48))

func _place_player_starts() -> void:
	# Mirrored starts across the arena
	add_player_start(Vector2(40, 230))
	add_player_start(Vector2(440, 230))
	add_player_start(Vector2(88, 188))
	add_player_start(Vector2(392, 188))
	add_player_start(Vector2(240, 140))

func _place_pickups() -> void:
	# Health packs (low platforms)
	add_health_pack(Vector2(88, 190))
	add_health_pack(Vector2(392, 190))
	# Mega health at center floor
	add_health_pack(Vector2(240, 240), true)
	# Heavy armor on mid platform
	add_armor(Vector2(240, 142))
	# Weapon pickups
	add_weapon_pickup(Vector2(140, 240), FlakCannon, FLAK_DATA)
	add_weapon_pickup(Vector2(340, 240), RocketLauncher, ROCKET_DATA)
	add_weapon_pickup(Vector2(168, 142), ShockRifle, SHOCK_DATA)
	add_weapon_pickup(Vector2(312, 142), BioRifle, BIO_DATA)
	add_weapon_pickup(Vector2(240, 46), SniperRifle, SNIPER_DATA)
	# Ammo
	add_ammo(Vector2(104, 94), &"shells", 6)
	add_ammo(Vector2(376, 94), &"rockets", 4)
	add_ammo(Vector2(40, 240), &"energy", 25)
	add_ammo(Vector2(440, 240), &"sniper", 8)
	add_ammo(Vector2(240, 142), &"biosludge", 20)

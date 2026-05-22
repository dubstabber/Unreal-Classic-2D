extends Arena
## Arena 02 — Vortex. Asymmetric vertical arena with catwalks.
## Cool blue/cyan space-station palette tint.

const SHOCK_DATA := preload("res://resources/weapons/shock_rifle.tres")
const ROCKET_DATA := preload("res://resources/weapons/rocket_launcher.tres")
const FLAK_DATA := preload("res://resources/weapons/flak_cannon.tres")
const SNIPER_DATA := preload("res://resources/weapons/sniper_rifle.tres")
const BIO_DATA := preload("res://resources/weapons/bio_rifle.tres")
const HAMMER_DATA := preload("res://resources/weapons/impact_hammer.tres")

func _init() -> void:
	display_name = "Vortex"
	arena_tint = Color(0.78, 0.92, 1.10, 1)
	bg_top = Color(0.06, 0.10, 0.18, 1)
	bg_bottom = Color(0.02, 0.04, 0.08, 1)

func _layout_geometry() -> void:
	# Floor (full width)
	add_floor(Rect2i(Vector2i(0, 248), Vector2i(VIEWPORT_W, 16)))
	# Side walls
	add_floor(Rect2i(Vector2i(0, 16), Vector2i(8, 232)))
	add_floor(Rect2i(Vector2i(VIEWPORT_W - 8, 16), Vector2i(8, 232)))
	# Asymmetric staircase on the left going up
	add_floor(Rect2i(Vector2i(8, 216), Vector2i(56, 8)))    # step 1
	add_floor(Rect2i(Vector2i(80, 184), Vector2i(56, 8)))   # step 2
	add_floor(Rect2i(Vector2i(8, 152), Vector2i(96, 8)))    # left mid catwalk
	add_floor(Rect2i(Vector2i(8, 88), Vector2i(48, 8)))     # upper-left ledge
	# Right side — different pattern
	add_floor(Rect2i(Vector2i(384, 216), Vector2i(88, 8)))  # right wide low
	add_floor(Rect2i(Vector2i(296, 168), Vector2i(48, 8)))  # right low-mid
	add_floor(Rect2i(Vector2i(384, 120), Vector2i(88, 8)))  # right mid
	add_floor(Rect2i(Vector2i(416, 64), Vector2i(56, 8)))   # upper right
	# Center column
	add_floor(Rect2i(Vector2i(176, 200), Vector2i(128, 8))) # central mid
	add_floor(Rect2i(Vector2i(216, 120), Vector2i(48, 8)))  # central catwalk
	add_floor(Rect2i(Vector2i(216, 56), Vector2i(48, 8)))   # top center

func _place_nav_nodes() -> void:
	# Floor row
	add_nav_node(Vector2(40, 240))
	add_nav_node(Vector2(160, 240))
	add_nav_node(Vector2(240, 240))
	add_nav_node(Vector2(340, 240))
	add_nav_node(Vector2(440, 240))
	# Left side staircase
	add_nav_node(Vector2(36, 208))
	add_nav_node(Vector2(108, 176))
	add_nav_node(Vector2(56, 144))
	add_nav_node(Vector2(32, 80))
	# Right side
	add_nav_node(Vector2(428, 208))
	add_nav_node(Vector2(320, 160))
	add_nav_node(Vector2(428, 112))
	add_nav_node(Vector2(444, 56))
	# Center column
	add_nav_node(Vector2(200, 192))
	add_nav_node(Vector2(240, 192))
	add_nav_node(Vector2(280, 192))
	add_nav_node(Vector2(240, 112))
	add_nav_node(Vector2(240, 48))

func _place_player_starts() -> void:
	add_player_start(Vector2(40, 230))
	add_player_start(Vector2(440, 230))
	add_player_start(Vector2(36, 200))
	add_player_start(Vector2(428, 200))
	add_player_start(Vector2(240, 184))
	add_player_start(Vector2(240, 104))

func _place_pickups() -> void:
	# Health packs scattered on catwalks
	add_health_pack(Vector2(108, 174))
	add_health_pack(Vector2(320, 158))
	# Mega health at top center
	add_health_pack(Vector2(240, 46), true)
	# Armor on left mid catwalk
	add_armor(Vector2(56, 142))
	# Weapons spread
	add_weapon_pickup(Vector2(36, 80), SniperRifle, SNIPER_DATA)
	add_weapon_pickup(Vector2(444, 54), RocketLauncher, ROCKET_DATA)
	add_weapon_pickup(Vector2(240, 192), FlakCannon, FLAK_DATA)
	add_weapon_pickup(Vector2(240, 110), ShockRifle, SHOCK_DATA)
	add_weapon_pickup(Vector2(428, 110), BioRifle, BIO_DATA)
	add_weapon_pickup(Vector2(40, 240), ImpactHammer, HAMMER_DATA)
	# Ammo distribution
	add_ammo(Vector2(80, 240), &"energy", 25)
	add_ammo(Vector2(400, 240), &"shells", 6)
	add_ammo(Vector2(108, 174), &"sniper", 8)
	add_ammo(Vector2(320, 158), &"rockets", 4)
	add_ammo(Vector2(56, 142), &"biosludge", 20)

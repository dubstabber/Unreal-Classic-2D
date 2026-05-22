extends Node
## Autoload. Builds named ImageTextures procedurally on boot.
## Recipes are local methods for now; later phases will move to Resource-based recipes.

const Palette := preload("res://scripts/art/palette.gd")
const PixelCanvas := preload("res://scripts/art/pixel_canvas.gd")

const DEFAULT_PALETTE_PATH := "res://resources/art/palette.tres"

var palette: Palette
var _textures: Dictionary[StringName, ImageTexture] = {}

func _ready() -> void:
	palette = load(DEFAULT_PALETTE_PATH) as Palette
	if palette == null:
		push_warning("SpriteBaker: palette resource missing at %s — using empty palette" % DEFAULT_PALETTE_PATH)
		palette = Palette.new()
	_bake_all()

func get_texture(name: StringName) -> ImageTexture:
	return _textures.get(name, null)

func has_texture(name: StringName) -> bool:
	return _textures.has(name)

func _bake_all() -> void:
	_textures[&"pawn_torso"] = _bake_pawn_torso()
	_textures[&"pawn_leg"] = _bake_pawn_leg()
	_textures[&"pawn_head_side"] = _bake_pawn_head_side()
	_textures[&"pawn_arm_front"] = _bake_pawn_arm_front()
	_textures[&"pawn_arm_back"] = _bake_pawn_arm_back()
	_textures[&"gun_enforcer"] = _bake_gun_enforcer()
	_textures[&"tile_solid"] = _bake_tile_solid()
	_textures[&"shock_orb"] = _bake_shock_orb()
	_textures[&"muzzle_flash"] = _bake_muzzle_flash()
	_textures[&"rocket"] = _bake_rocket()
	_textures[&"explosion_particle"] = _bake_explosion_particle()
	_textures[&"radial_falloff"] = _bake_radial_falloff()
	_textures[&"bio_glob"] = _bake_bio_glob()
	_textures[&"bio_pool"] = _bake_bio_pool()
	_textures[&"flak_shard"] = _bake_flak_shard()
	_textures[&"flak_grenade"] = _bake_flak_grenade()
	_textures[&"pickup_health"] = _bake_pickup_health()
	_textures[&"pickup_health_mega"] = _bake_pickup_health_mega()
	_textures[&"pickup_armor"] = _bake_pickup_armor()
	_textures[&"pickup_ammo"] = _bake_pickup_ammo()
	_textures[&"pickup_weapon_glow"] = _bake_pickup_weapon_glow()
	_textures[&"icon_enforcer"] = _bake_icon_enforcer()
	_textures[&"icon_bio"] = _bake_icon_bio()
	_textures[&"icon_shock"] = _bake_icon_shock()
	_textures[&"icon_flak"] = _bake_icon_flak()
	_textures[&"icon_rocket"] = _bake_icon_rocket()
	_textures[&"icon_sniper"] = _bake_icon_sniper()
	_textures[&"hud_dmg_arc"] = _bake_hud_dmg_arc()

func _c(name: StringName, fallback: Color = Color.MAGENTA) -> Color:
	return palette.get_color(name, fallback)

# ---------- Recipes ----------

func _bake_pawn_torso() -> ImageTexture:
	# 8x9 armored torso (no legs). Drawn facing right.
	# Anchor (pivot) at (4, 9) — the hip joint at the bottom edge.
	var c := PixelCanvas.new(8, 9)
	var armor := _c(&"armor_mid", Color(0.30, 0.55, 0.85))
	var armor_dark := _c(&"armor_dark", Color(0.18, 0.34, 0.55))
	var armor_light := _c(&"armor_light", Color(0.55, 0.78, 1.0))
	var outline := _c(&"outline", Color(0.05, 0.07, 0.12))
	c.fill_rect(1, 0, 6, 9, armor)
	c.fill_rect(1, 0, 6, 2, armor_light)  # chest/shoulder highlight
	c.fill_rect(5, 2, 1, 5, armor_dark)   # front edge shading (right side)
	c.fill_rect(1, 7, 6, 2, armor_dark)   # belt
	c.outline_rect(1, 0, 6, 9, outline)
	return c.texture()

func _bake_pawn_leg() -> ImageTexture:
	# 3x7 leg piece, reused for front and back. Anchor (pivot) at (1, 0) — hip, top-center.
	var c := PixelCanvas.new(3, 7)
	var armor_dark := _c(&"armor_dark", Color(0.18, 0.34, 0.55))
	var metal_dark := _c(&"metal_dark", Color(0.30, 0.30, 0.36))
	var outline := _c(&"outline", Color(0.05, 0.07, 0.12))
	c.fill_rect(0, 0, 3, 6, armor_dark)  # thigh/shin
	c.fill_rect(0, 6, 3, 1, metal_dark)  # boot
	c.set_px(0, 0, outline)
	c.set_px(2, 0, outline)
	return c.texture()

func _bake_pawn_head_side() -> ImageTexture:
	# 8x8 side-profile head facing right (nose bump on +X, hair on top/back).
	# Anchor (pivot) at (3, 7) — the neck, near the bottom.
	var c := PixelCanvas.new(8, 8)
	var skin := _c(&"skin", Color(0.95, 0.78, 0.62))
	var skin_dark := _c(&"skin_dark", Color(0.70, 0.52, 0.38))
	var hair := _c(&"hair", Color(0.22, 0.16, 0.10))
	var outline := _c(&"outline", Color(0.05, 0.07, 0.12))
	c.fill_rect(1, 1, 5, 6, skin)        # face block (x 1..5)
	c.fill_rect(1, 0, 5, 2, hair)        # hair on top
	c.fill_rect(0, 1, 1, 4, hair)        # hair down the back (left = behind)
	c.set_px(6, 3, skin)                 # nose bump (front)
	c.set_px(6, 4, skin)
	c.set_px(4, 3, outline)              # eye
	c.fill_rect(1, 6, 5, 1, skin_dark)   # jaw shadow
	c.outline_rect(1, 1, 5, 6, outline)
	return c.texture()

func _bake_pawn_arm_front() -> ImageTexture:
	# 7x3 gun arm (forearm + hand), drawn pointing +X.
	# Anchor (pivot) at (1, 1) — the shoulder. Hand at the +X end (x ~5).
	var c := PixelCanvas.new(7, 3)
	var armor := _c(&"armor_mid", Color(0.30, 0.55, 0.85))
	var armor_dark := _c(&"armor_dark", Color(0.18, 0.34, 0.55))
	var skin := _c(&"skin", Color(0.95, 0.78, 0.62))
	c.fill_rect(0, 0, 5, 3, armor)       # upper/forearm
	c.fill_rect(0, 2, 5, 1, armor_dark)  # underside shadow
	c.fill_rect(5, 0, 2, 3, skin)        # hand/grip
	return c.texture()

func _bake_pawn_arm_back() -> ImageTexture:
	# 6x3 support arm (rendered behind torso). Darker so it reads as "behind".
	# Anchor (pivot) at (1, 1) — the shoulder.
	var c := PixelCanvas.new(6, 3)
	var armor_dark := _c(&"armor_dark", Color(0.18, 0.34, 0.55))
	var skin_dark := _c(&"skin_dark", Color(0.70, 0.52, 0.38))
	c.fill_rect(0, 0, 6, 3, armor_dark)
	c.fill_rect(4, 0, 2, 2, skin_dark)   # back hand hint
	return c.texture()

func _bake_gun_enforcer() -> ImageTexture:
	# 8x4 enforcer pistol pointing +X. Anchor (pivot) at (0, 2) — the grip in the hand.
	# Muzzle tip at x ~7 (matches WeaponData.muzzle_offset_local.x).
	var c := PixelCanvas.new(8, 4)
	var metal := _c(&"metal", Color(0.55, 0.55, 0.62))
	var metal_dark := _c(&"metal_dark", Color(0.30, 0.30, 0.36))
	var outline := _c(&"outline", Color(0.05, 0.07, 0.12))
	c.fill_rect(0, 1, 8, 2, metal)       # barrel/slide body
	c.fill_rect(2, 0, 4, 1, metal)       # slide top
	c.fill_rect(0, 2, 3, 2, metal_dark)  # grip
	c.set_px(0, 0, metal_dark)           # hammer nub
	c.set_px(7, 1, _c(&"plasma_hot", Color(1, 0.9, 0.4)))  # muzzle tip glow
	c.set_px(7, 2, outline)
	return c.texture()

func _bake_shock_orb() -> ImageTexture:
	# 10x10 plasma orb — purple core, white-hot center, soft edge via dither
	var c := PixelCanvas.new(10, 10)
	var purple := _c(&"shock_purple", Color(0.7, 0.4, 1, 1))
	var purple_dark := Color(purple.r * 0.4, purple.g * 0.3, purple.b * 0.7, 1)
	var white := _c(&"laser_white", Color(1, 1, 1, 1))
	# inner solid square
	c.fill_rect(3, 3, 4, 4, purple)
	# diamond extension
	c.fill_rect(4, 1, 2, 2, purple)
	c.fill_rect(4, 7, 2, 2, purple)
	c.fill_rect(1, 4, 2, 2, purple)
	c.fill_rect(7, 4, 2, 2, purple)
	# outline darker
	c.set_px(4, 0, purple_dark); c.set_px(5, 0, purple_dark)
	c.set_px(4, 9, purple_dark); c.set_px(5, 9, purple_dark)
	c.set_px(0, 4, purple_dark); c.set_px(0, 5, purple_dark)
	c.set_px(9, 4, purple_dark); c.set_px(9, 5, purple_dark)
	# white-hot core
	c.set_px(4, 4, white); c.set_px(5, 4, white)
	c.set_px(4, 5, white); c.set_px(5, 5, white)
	return c.texture()

func _bake_muzzle_flash() -> ImageTexture:
	# 7x5 horizontal star — bright center, two side spokes
	var c := PixelCanvas.new(7, 5)
	var hot := _c(&"plasma_hot", Color(1, 0.9, 0.4, 1))
	var white := _c(&"laser_white", Color(1, 1, 1, 1))
	c.fill_rect(0, 2, 7, 1, hot)
	c.fill_rect(3, 1, 1, 3, hot)
	c.fill_rect(2, 2, 3, 1, white)
	c.set_px(3, 2, white)
	return c.texture()

func _bake_rocket() -> ImageTexture:
	# 9x5 horizontal rocket — pointed nose, body, fins, exhaust spark
	var c := PixelCanvas.new(9, 5)
	var red := _c(&"rocket", Color(0.85, 0.3, 0.2, 1))
	var red_dark := Color(red.r * 0.5, red.g * 0.3, red.b * 0.3, 1)
	var metal := _c(&"metal_light", Color(0.75, 0.78, 0.82, 1))
	var hot := _c(&"plasma_hot", Color(1, 0.9, 0.4, 1))
	var outline := _c(&"outline", Color(0.05, 0.07, 0.12, 1))
	# Body
	c.fill_rect(2, 1, 5, 3, red)
	c.fill_rect(2, 1, 5, 1, red_dark)  # top shadow
	# Nose
	c.set_px(7, 2, metal)
	c.set_px(8, 2, metal)
	# Fins
	c.set_px(1, 0, red_dark)
	c.set_px(1, 4, red_dark)
	c.set_px(2, 0, red_dark)
	c.set_px(2, 4, red_dark)
	# Exhaust spark
	c.set_px(0, 2, hot)
	c.set_px(1, 2, hot)
	# Outline (sparse for readability)
	c.set_px(2, 1, outline)
	c.set_px(6, 1, outline)
	return c.texture()

func _bake_explosion_particle() -> ImageTexture:
	# 2x2 white particle, used as the particle texture for GPU bursts (color is modulated by lifetime)
	var c := PixelCanvas.new(2, 2)
	c.fill_rect(0, 0, 2, 2, Color(1, 1, 1, 1))
	return c.texture()

func _bake_radial_falloff() -> ImageTexture:
	# 16x16 radial gradient for explosion light. Hard-stepped to stay pixel-art.
	var c := PixelCanvas.new(16, 16)
	var center := Vector2(7.5, 7.5)
	for y in 16:
		for x in 16:
			var d: float = Vector2(x, y).distance_to(center) / 8.0
			d = clampf(d, 0.0, 1.0)
			# 4-step quantization
			var a: float = ceilf((1.0 - d) * 4.0) / 4.0
			if a > 0.0:
				c.set_px(x, y, Color(1, 1, 1, a))
	return c.texture()

func _bake_bio_glob() -> ImageTexture:
	# 7x7 sticky green blob with bright core
	var c := PixelCanvas.new(7, 7)
	var green := _c(&"bio_green", Color(0.4, 0.9, 0.3, 1))
	var green_dark := Color(green.r * 0.4, green.g * 0.5, green.b * 0.2, 1)
	var green_bright := Color(0.75, 1, 0.55, 1)
	c.fill_rect(1, 1, 5, 5, green_dark)
	c.fill_rect(2, 1, 3, 5, green)
	c.fill_rect(1, 2, 5, 3, green)
	c.set_px(3, 3, green_bright)
	c.set_px(2, 3, green_bright)
	# drips
	c.set_px(3, 6, green_dark)
	c.set_px(1, 5, green_dark)
	return c.texture()

func _bake_bio_pool() -> ImageTexture:
	# 14x4 wide green pool/splatter (sits on floor)
	var c := PixelCanvas.new(14, 4)
	var green := _c(&"bio_green", Color(0.4, 0.9, 0.3, 1))
	var green_dark := Color(green.r * 0.4, green.g * 0.5, green.b * 0.2, 1)
	var green_bright := Color(0.75, 1, 0.55, 1)
	# Lumpy elongated pool
	c.fill_rect(2, 1, 10, 2, green)
	c.fill_rect(1, 2, 12, 1, green_dark)
	c.fill_rect(4, 0, 3, 1, green)
	c.fill_rect(8, 0, 2, 1, green)
	c.set_px(6, 1, green_bright)
	c.set_px(10, 1, green_bright)
	return c.texture()

func _bake_flak_shard() -> ImageTexture:
	# 4x3 orange shard sliver
	var c := PixelCanvas.new(4, 3)
	var orange := _c(&"flak_orange", Color(1, 0.55, 0.15, 1))
	var orange_dark := Color(orange.r * 0.5, orange.g * 0.3, orange.b * 0.2, 1)
	var hot := _c(&"plasma_hot", Color(1, 0.9, 0.4, 1))
	c.fill_rect(0, 1, 4, 1, orange)
	c.set_px(0, 0, orange_dark)
	c.set_px(3, 2, orange_dark)
	c.set_px(1, 1, hot)
	return c.texture()

func _bake_flak_grenade() -> ImageTexture:
	# 6x6 grenade — gray casing, orange fuse spark
	var c := PixelCanvas.new(6, 6)
	var metal := _c(&"metal", Color(0.55, 0.55, 0.62, 1))
	var metal_dark := _c(&"metal_dark", Color(0.30, 0.30, 0.36, 1))
	var orange := _c(&"flak_orange", Color(1, 0.55, 0.15, 1))
	var hot := _c(&"plasma_hot", Color(1, 0.9, 0.4, 1))
	c.fill_rect(1, 1, 4, 4, metal)
	c.fill_rect(1, 4, 4, 1, metal_dark)
	c.set_px(0, 2, metal_dark)
	c.set_px(5, 2, metal_dark)
	c.set_px(0, 3, metal_dark)
	c.set_px(5, 3, metal_dark)
	c.set_px(2, 0, orange)
	c.set_px(3, 0, hot)
	return c.texture()

func _bake_pickup_health() -> ImageTexture:
	# 9x9 white box with green cross
	var c := PixelCanvas.new(9, 9)
	var bg := Color(0.95, 0.95, 0.95, 1)
	var green := _c(&"hp_full", Color(0.3, 0.85, 0.4, 1))
	var outline := _c(&"outline", Color(0.05, 0.07, 0.12, 1))
	c.fill_rect(1, 1, 7, 7, bg)
	c.outline_rect(0, 0, 9, 9, outline)
	c.fill_rect(3, 1, 3, 7, green)
	c.fill_rect(1, 3, 7, 3, green)
	return c.texture()

func _bake_pickup_health_mega() -> ImageTexture:
	# 11x11 mega-health: blue box with white cross + outline highlight
	var c := PixelCanvas.new(11, 11)
	var blue := _c(&"laser_blue", Color(0.4, 0.85, 1, 1))
	var blue_dark := Color(blue.r * 0.4, blue.g * 0.4, blue.b * 0.7, 1)
	var white := Color(1, 1, 1, 1)
	var outline := _c(&"outline", Color(0.05, 0.07, 0.12, 1))
	c.fill_rect(1, 1, 9, 9, blue)
	c.fill_rect(1, 1, 9, 2, white)
	c.fill_rect(1, 8, 9, 2, blue_dark)
	c.outline_rect(0, 0, 11, 11, outline)
	c.fill_rect(4, 1, 3, 9, white)
	c.fill_rect(1, 4, 9, 3, white)
	return c.texture()

func _bake_pickup_armor() -> ImageTexture:
	# 9x11 yellow vest silhouette
	var c := PixelCanvas.new(9, 11)
	var yellow := _c(&"ammo_color", Color(0.95, 0.8, 0.3, 1))
	var yellow_dark := Color(yellow.r * 0.55, yellow.g * 0.45, yellow.b * 0.2, 1)
	var outline := _c(&"outline", Color(0.05, 0.07, 0.12, 1))
	c.fill_rect(2, 1, 5, 9, yellow)
	# Shoulder bumps
	c.fill_rect(0, 2, 2, 4, yellow)
	c.fill_rect(7, 2, 2, 4, yellow)
	# Belt + lighting
	c.fill_rect(2, 7, 5, 2, yellow_dark)
	c.fill_rect(3, 2, 3, 1, Color(1, 1, 0.7, 1))
	# Outline
	c.outline_rect(2, 1, 5, 9, outline)
	c.outline_rect(0, 2, 2, 4, outline)
	c.outline_rect(7, 2, 2, 4, outline)
	return c.texture()

func _bake_pickup_ammo() -> ImageTexture:
	# 10x7 ammo box — gray with orange band + outline
	var c := PixelCanvas.new(10, 7)
	var metal := _c(&"metal", Color(0.55, 0.55, 0.62, 1))
	var metal_dark := _c(&"metal_dark", Color(0.30, 0.30, 0.36, 1))
	var orange := _c(&"flak_orange", Color(1, 0.55, 0.15, 1))
	var outline := _c(&"outline", Color(0.05, 0.07, 0.12, 1))
	c.fill_rect(1, 1, 8, 5, metal)
	c.fill_rect(1, 1, 8, 1, Color(0.75, 0.75, 0.82, 1))
	c.fill_rect(1, 4, 8, 1, metal_dark)
	c.fill_rect(1, 2, 8, 2, orange)
	c.outline_rect(0, 0, 10, 7, outline)
	return c.texture()

func _bake_pickup_weapon_glow() -> ImageTexture:
	# 12x4 base pedestal glow under weapon pickups
	var c := PixelCanvas.new(12, 4)
	var blue := _c(&"laser_blue", Color(0.4, 0.85, 1, 1))
	c.fill_rect(2, 1, 8, 2, blue)
	c.fill_rect(0, 2, 12, 1, Color(blue.r, blue.g, blue.b, 0.5))
	return c.texture()

func _bake_icon_enforcer() -> ImageTexture:
	var c := PixelCanvas.new(12, 12)
	var metal := _c(&"metal", Color(0.55, 0.55, 0.62, 1))
	c.fill_rect(2, 5, 8, 3, metal)
	c.fill_rect(4, 8, 2, 3, _c(&"metal_dark"))  # grip
	c.outline_rect(2, 5, 8, 3, _c(&"outline"))
	c.set_px(10, 6, _c(&"plasma_hot"))  # barrel tip
	return c.texture()

func _bake_icon_bio() -> ImageTexture:
	var c := PixelCanvas.new(12, 12)
	var g := _c(&"bio_green", Color(0.4, 0.9, 0.3, 1))
	c.fill_rect(3, 3, 6, 6, g)
	c.fill_rect(4, 2, 4, 1, g)
	c.fill_rect(4, 9, 4, 1, g)
	c.fill_rect(2, 4, 1, 4, g)
	c.fill_rect(9, 4, 1, 4, g)
	c.set_px(5, 5, _c(&"laser_white"))
	return c.texture()

func _bake_icon_shock() -> ImageTexture:
	var c := PixelCanvas.new(12, 12)
	var purple := _c(&"shock_purple", Color(0.7, 0.4, 1, 1))
	c.fill_rect(2, 5, 8, 2, purple)
	c.fill_rect(5, 2, 2, 8, purple)
	c.set_px(5, 5, _c(&"laser_white"))
	c.set_px(6, 5, _c(&"laser_white"))
	return c.texture()

func _bake_icon_flak() -> ImageTexture:
	var c := PixelCanvas.new(12, 12)
	var o := _c(&"flak_orange", Color(1, 0.55, 0.15, 1))
	c.fill_rect(5, 5, 2, 2, o)
	c.set_px(2, 6, o); c.set_px(9, 6, o)
	c.set_px(6, 2, o); c.set_px(6, 9, o)
	c.set_px(3, 3, o); c.set_px(8, 8, o)
	c.set_px(8, 3, o); c.set_px(3, 8, o)
	return c.texture()

func _bake_icon_rocket() -> ImageTexture:
	var c := PixelCanvas.new(12, 12)
	var r := _c(&"rocket", Color(0.85, 0.3, 0.2, 1))
	c.fill_rect(2, 5, 7, 2, r)
	c.set_px(9, 5, _c(&"metal"))
	c.set_px(9, 6, _c(&"metal"))
	c.set_px(10, 6, _c(&"metal"))
	c.set_px(1, 5, _c(&"plasma_hot"))
	c.set_px(1, 6, _c(&"plasma_hot"))
	c.set_px(2, 4, r); c.set_px(2, 7, r)
	return c.texture()

func _bake_icon_sniper() -> ImageTexture:
	var c := PixelCanvas.new(12, 12)
	var metal := _c(&"metal", Color(0.55, 0.55, 0.62, 1))
	c.fill_rect(1, 6, 10, 1, metal)
	c.fill_rect(2, 5, 2, 3, _c(&"metal_dark"))
	c.set_px(11, 6, _c(&"laser_blue"))
	c.outline_rect(2, 5, 2, 3, _c(&"outline"))
	return c.texture()

func _bake_hud_dmg_arc() -> ImageTexture:
	# 16x8 horizontal arc band, brighter at center, fades to edges.
	var c := PixelCanvas.new(16, 8)
	var red := _c(&"hp_low", Color(0.95, 0.3, 0.2, 1))
	# Solid band middle
	c.fill_rect(0, 3, 16, 2, red)
	# Taper alpha via dithered fades on outer rows
	for x in 16:
		var t: float = absf(float(x) - 7.5) / 7.5
		var a: float = 1.0 - t
		var color := Color(red.r, red.g, red.b, a)
		c.set_px(x, 2, color)
		c.set_px(x, 5, color)
	return c.texture()

func _bake_tile_solid() -> ImageTexture:
	# 8x8 solid wall tile with subtle dither and a 1px top highlight.
	var c := PixelCanvas.new(8, 8)
	var wall := _c(&"wall_mid", Color(0.28, 0.30, 0.36))
	var wall_dark := _c(&"wall_dark", Color(0.16, 0.18, 0.22))
	var wall_light := _c(&"wall_light", Color(0.42, 0.45, 0.52))
	c.fill_rect(0, 0, 8, 8, wall)
	c.fill_rect(0, 0, 8, 1, wall_light)  # top edge sunlit
	c.fill_rect(0, 7, 8, 1, wall_dark)   # bottom edge shadow
	# subtle noise dither
	c.dither_fill(0, 1, 8, 6, wall_dark, 0.18)
	return c.texture()

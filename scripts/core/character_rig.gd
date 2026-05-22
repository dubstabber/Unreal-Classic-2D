class_name CharacterRig
extends Skeleton2D
## Articulated side-view humanoid built in code from baked pixel-art pieces.
## Rigid Sprite2D cut-outs are parented to Bone2D pivots — no polygon skinning, no IK.
## Each frame the front (gun) arm points exactly at the crosshair, the head turns
## partially toward it, and the torso leans slightly. The whole rig is mirrored via
## scale.x for left/right facing; aim angles are computed in rig-local space so the
## mirror is handled automatically (avoids global_rotation issues under negative scale).

# Per-weapon gun sprite. Only the Enforcer exists for now; everything falls back to it.
const GUN_TEX_BY_ID: Dictionary[StringName, StringName] = {
	&"enforcer": &"gun_enforcer",
}
const GUN_TEX_FALLBACK: StringName = &"gun_enforcer"

# Aim-response tuning (fractions of the aim angle, clamped so poses never break).
const HEAD_FOLLOW: float = 0.35
const HEAD_CLAMP: float = 0.6
const TORSO_FOLLOW: float = 0.15
const TORSO_CLAMP: float = 0.32
const BACK_ARM_REST: float = 0.45   # support arm hangs slightly down/forward

var _torso: Bone2D
var _head: Bone2D
var _arm_front: Bone2D
var _arm_back: Bone2D
var _gun_spr: Sprite2D
var _muzzle: Marker2D
var _armor_sprites: Array[Sprite2D] = []

func _ready() -> void:
	_build()

func _build() -> void:
	var hip := _make_bone(self, &"Hip", Vector2(0, 3))

	# Legs hang from the hip and stay planted (not affected by torso lean).
	var leg_back := _make_bone(hip, &"LegBack", Vector2(-1, 0))
	_make_sprite(leg_back, &"pawn_leg", Vector2(-1, 0), -2, true)
	var leg_front := _make_bone(hip, &"LegFront", Vector2(1, 0))
	_make_sprite(leg_front, &"pawn_leg", Vector2(-1, 0), 0, true)

	# Torso leans from the waist; head + arms ride on it.
	_torso = _make_bone(hip, &"Torso", Vector2(0, 0))
	_make_sprite(_torso, &"pawn_torso", Vector2(-4, -9), 0, true)

	# Back arm renders behind the torso with a fixed resting pose.
	_arm_back = _make_bone(_torso, &"ArmBack", Vector2(-1, -8))
	_arm_back.rotation = BACK_ARM_REST
	_make_sprite(_arm_back, &"pawn_arm_back", Vector2(-1, -1), -1, true)

	_head = _make_bone(_torso, &"Head", Vector2(0, -9))
	_make_sprite(_head, &"pawn_head_side", Vector2(-3, -7), 1, false)

	# Front (gun) arm points at the crosshair; the gun + muzzle ride on it.
	_arm_front = _make_bone(_torso, &"ArmFront", Vector2(1, -8))
	_make_sprite(_arm_front, &"pawn_arm_front", Vector2(-1, -1), 2, true)

	_gun_spr = Sprite2D.new()
	_gun_spr.name = "Gun"
	_gun_spr.centered = false
	_gun_spr.offset = Vector2(0, -2)      # grip pivot at (0, 2)
	_gun_spr.position = Vector2(5, 0)     # at the hand, end of the forearm
	_gun_spr.z_index = 3
	_gun_spr.texture = SpriteBaker.get_texture(GUN_TEX_FALLBACK)
	_arm_front.add_child(_gun_spr)

	_muzzle = Marker2D.new()
	_muzzle.name = "Muzzle"
	_muzzle.position = Vector2(7, 0)      # barrel tip; tuned per-weapon in set_gun_for_weapon
	_gun_spr.add_child(_muzzle)

# ---------- Per-frame drive ----------

func update_aim(aim_target: Vector2, facing: int) -> void:
	scale.x = float(facing)
	var to_aim_w: Vector2 = aim_target - _arm_front.global_position
	if to_aim_w.length_squared() < 0.01:
		return
	# Map the world aim direction into rig-local space. Because the rig's basis
	# includes the scale.x = ±1 mirror, the resulting local angle points the
	# right-facing sprites at the world aim under either facing.
	var local_dir: Vector2 = global_transform.affine_inverse().basis_xform(to_aim_w)
	var aim_local: float = local_dir.angle()
	_arm_front.rotation = aim_local
	_head.rotation = clampf(aim_local * HEAD_FOLLOW, -HEAD_CLAMP, HEAD_CLAMP)
	_torso.rotation = clampf(aim_local * TORSO_FOLLOW, -TORSO_CLAMP, TORSO_CLAMP)

# ---------- Accessors ----------

func aim_pivot_global() -> Vector2:
	return _arm_front.global_position

func muzzle_global() -> Vector2:
	return _muzzle.global_position

func set_team_color(c: Color) -> void:
	# Tints armor parts only — head/skin and gun stay neutral so faces read clearly.
	for s in _armor_sprites:
		s.modulate = c

func set_gun_for_weapon(data: WeaponData) -> void:
	var key: StringName = data.id if data != null else &""
	var tex_name: StringName = GUN_TEX_BY_ID.get(key, GUN_TEX_FALLBACK)
	_gun_spr.texture = SpriteBaker.get_texture(tex_name)
	if data != null:
		_muzzle.position = Vector2(data.muzzle_offset_local.x, 0)

# ---------- Build helpers ----------

func _make_bone(parent: Node, n: String, pos: Vector2) -> Bone2D:
	var b := Bone2D.new()
	b.name = n
	b.position = pos
	# We drive rotations every frame and use no IK/skinning; set rest + disable
	# autocalc only to keep the bone quiet (no runtime effect for rigid pieces).
	b.set_autocalculate_length_and_angle(false)
	b.set_length(4.0)
	b.set_rest(Transform2D(0.0, pos))
	parent.add_child(b)
	return b

func _make_sprite(parent: Bone2D, tex: StringName, off: Vector2, z: int, is_armor: bool) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.offset = off
	s.z_index = z
	s.texture = SpriteBaker.get_texture(tex)
	parent.add_child(s)
	if is_armor:
		_armor_sprites.append(s)
	return s

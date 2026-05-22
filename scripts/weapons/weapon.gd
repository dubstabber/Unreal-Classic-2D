class_name Weapon
extends Node
## Base weapon. A Weapon is a logic-only Node attached to a Pawn.
## Visuals live on the Pawn's WeaponMount / arm sprite — the weapon doesn't render.

signal fired(slot_kind: StringName)  # "primary" | "alt"

@export var data: WeaponData

var pawn: Pawn = null
var slot: int = 0

var _primary_cooldown: float = 0.0
var _alt_cooldown: float = 0.0

func _ready() -> void:
	if data != null:
		slot = data.slot

func bind_pawn(p: Pawn) -> void:
	pawn = p

func tick(delta: float) -> void:
	_primary_cooldown = maxf(0.0, _primary_cooldown - delta)
	_alt_cooldown = maxf(0.0, _alt_cooldown - delta)
	if pawn == null or pawn.controller == null or data == null:
		return
	if pawn.controller.wish_fire_primary and _primary_cooldown <= 0.0:
		if _consume_ammo(data.ammo_per_shot_primary):
			primary_fire()
			_primary_cooldown = data.primary_fire_rate
			fired.emit(&"primary")
	if pawn.controller.wish_fire_alt and _alt_cooldown <= 0.0:
		if _consume_ammo(data.ammo_per_shot_alt):
			alt_fire()
			_alt_cooldown = data.alt_fire_rate
			fired.emit(&"alt")

func _consume_ammo(amount: int) -> bool:
	if data == null or data.ammo_type == &"":
		return true
	return pawn.inventory.consume_ammo(data.ammo_type, amount)

# Subclasses override these.
func primary_fire() -> void: pass
func alt_fire() -> void: pass

# ---------- Aiming helpers ----------

func aim_origin() -> Vector2:
	# Front-arm shoulder pivot, provided by the pawn's rig.
	return pawn.aim_pivot_global() if pawn != null else Vector2.ZERO

func aim_direction() -> Vector2:
	# Crosshair-relative (not derived from arm rotation) so aim stays exact and
	# bot aim-error is preserved.
	if pawn == null or pawn.controller == null:
		return Vector2.RIGHT
	var to: Vector2 = pawn.controller.aim_target - aim_origin()
	if to.length_squared() < 0.01:
		return Vector2.RIGHT * float(pawn._facing_x)
	return to.normalized()

func barrel_position() -> Vector2:
	# Real muzzle marker (rides the rig: arm rotation, lean, and flip) when available.
	if pawn != null and pawn.has_method(&"muzzle_global"):
		return pawn.muzzle_global()
	var off: float = data.muzzle_offset_local.x if data != null else 7.0
	return aim_origin() + aim_direction() * off

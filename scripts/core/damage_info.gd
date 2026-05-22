class_name DamageInfo
extends Resource

@export var amount: float = 0.0
@export var damage_type: StringName = &"projectile"  # impact | projectile | explosive | energy | melee
@export var knockback: Vector2 = Vector2.ZERO
@export var radius: float = 0.0  # 0 = direct hit; >0 = splash
@export var weapon_id: StringName = &""
@export var is_self_damage: bool = false

# Runtime-only (not serialized): WeakRef to the spawning pawn.
var instigator: WeakRef = null

# Optional tick id for future networking / replay determinism.
var tick: int = 0

func get_instigator() -> Node:
	return instigator.get_ref() if instigator != null else null

func set_instigator(node: Node) -> void:
	instigator = weakref(node) if node != null else null

static func make(amount: float, damage_type: StringName, instigator: Node, weapon_id: StringName = &"") -> DamageInfo:
	var info := DamageInfo.new()
	info.amount = amount
	info.damage_type = damage_type
	info.weapon_id = weapon_id
	info.set_instigator(instigator)
	return info

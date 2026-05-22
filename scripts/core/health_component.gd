class_name HealthComponent
extends Node
## Composed into Pawn. Encapsulates health/armor with UT99-style armor absorption math.

signal damaged(actual_amount: float, info: DamageInfo)
signal died(killer: Node)
signal healed(amount: float, kind: StringName)  # kind: "health" | "armor"

@export var max_health: float = 100.0
@export var health_overcap: float = 199.0   # UT99: vials/mega can stack above max up to this
@export var max_armor: float = 150.0
@export var armor_absorption: float = 0.5   # UT99 default 50%; shield-belt overrides per-pawn

var health: float = 100.0
var armor: float = 0.0
var is_alive: bool = true

func _ready() -> void:
	health = max_health

func take_damage(info: DamageInfo) -> float:
	if not is_alive or info == null:
		return 0.0
	var incoming: float = maxf(0.0, info.amount)
	if incoming <= 0.0:
		return 0.0

	# Armor absorbs a fraction of incoming up to its current value.
	if armor > 0.0:
		var absorbed: float = minf(armor, incoming * armor_absorption)
		armor -= absorbed
		incoming -= absorbed

	var pre: float = health
	health = maxf(0.0, health - incoming)
	var actual: float = pre - health
	damaged.emit(actual, info)

	if health <= 0.0 and is_alive:
		is_alive = false
		died.emit(info.get_instigator())
	return actual

func add_health(amount: float, cap: float = -1.0) -> float:
	if not is_alive or amount <= 0.0:
		return 0.0
	if cap < 0.0:
		cap = max_health
	var pre: float = health
	health = minf(cap, health + amount)
	var gained: float = health - pre
	if gained > 0.0:
		healed.emit(gained, &"health")
	return gained

func add_armor(amount: float, cap: float = -1.0) -> float:
	if not is_alive or amount <= 0.0:
		return 0.0
	if cap < 0.0:
		cap = max_armor
	var pre: float = armor
	armor = minf(cap, armor + amount)
	var gained: float = armor - pre
	if gained > 0.0:
		healed.emit(gained, &"armor")
	return gained

func reset() -> void:
	is_alive = true
	health = max_health
	armor = 0.0

class_name Inventory
extends Node
## Composed into Pawn. Owns equipped weapons, ammo pools, and current weapon index.
## Weapon type is left untyped here — Phase 3 will add the Weapon base class.

signal weapon_added(weapon: Node)
signal weapon_changed(weapon: Node, prev: Node)
signal ammo_changed(ammo_type: StringName, current: int, max_amount: int)

const AMMO_MAX_DEFAULT := 999

var weapons: Array[Node] = []
var ammo: Dictionary[StringName, int] = {}
var ammo_max: Dictionary[StringName, int] = {}
var current_index: int = -1

func current_weapon() -> Node:
	if current_index < 0 or current_index >= weapons.size():
		return null
	return weapons[current_index]

func add_weapon(w: Node) -> bool:
	if w == null or weapons.has(w):
		return false
	weapons.append(w)
	weapon_added.emit(w)
	if current_index == -1:
		_switch_to(weapons.size() - 1)
	return true

func switch_to_index(idx: int) -> bool:
	if idx < 0 or idx >= weapons.size() or idx == current_index:
		return false
	_switch_to(idx)
	return true

func switch_to_slot(slot: int) -> bool:
	for i in weapons.size():
		var w: Node = weapons[i]
		if "slot" in w and int(w.slot) == slot:
			return switch_to_index(i)
	return false

func cycle(delta: int) -> bool:
	if weapons.is_empty():
		return false
	var next_idx: int = posmod(current_index + delta, weapons.size())
	return switch_to_index(next_idx)

func _switch_to(idx: int) -> void:
	var prev: Node = current_weapon()
	current_index = idx
	weapon_changed.emit(weapons[idx], prev)

func set_ammo_cap(ammo_type: StringName, cap: int) -> void:
	ammo_max[ammo_type] = cap

func get_ammo(ammo_type: StringName) -> int:
	return ammo.get(ammo_type, 0)

func get_ammo_cap(ammo_type: StringName) -> int:
	return ammo_max.get(ammo_type, AMMO_MAX_DEFAULT)

func add_ammo(ammo_type: StringName, amount: int) -> int:
	if amount <= 0:
		return 0
	var cur: int = get_ammo(ammo_type)
	var cap: int = get_ammo_cap(ammo_type)
	var pre: int = cur
	ammo[ammo_type] = mini(cap, cur + amount)
	var gained: int = ammo[ammo_type] - pre
	if gained > 0:
		ammo_changed.emit(ammo_type, ammo[ammo_type], cap)
	return gained

func consume_ammo(ammo_type: StringName, amount: int) -> bool:
	if amount <= 0:
		return true
	var cur: int = get_ammo(ammo_type)
	if cur < amount:
		return false
	ammo[ammo_type] = cur - amount
	ammo_changed.emit(ammo_type, ammo[ammo_type], get_ammo_cap(ammo_type))
	return true

func clear() -> void:
	weapons.clear()
	ammo.clear()
	current_index = -1

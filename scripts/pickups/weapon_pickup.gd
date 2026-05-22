class_name WeaponPickup
extends Pickup
## Gives the player a weapon (if they don't have it) plus base ammo. If they already
## have it, gives an ammo refill instead.

@export var weapon_data: WeaponData
@export var weapon_class: GDScript
@export var ammo_refill_on_dup: int = -1  # -1 = use data.base_ammo_on_pickup

func _try_take(pawn: Pawn) -> bool:
	if weapon_data == null or weapon_class == null:
		return false
	var has_it: bool = false
	for w in pawn.inventory.weapons:
		if w.get_script() == weapon_class:
			has_it = true
			break
	if has_it:
		if weapon_data.ammo_type == &"":
			return false
		var amount: int = ammo_refill_on_dup if ammo_refill_on_dup >= 0 else weapon_data.base_ammo_on_pickup
		var added: int = pawn.inventory.add_ammo(weapon_data.ammo_type, amount)
		EventBus.weapon_picked_up.emit(weapon_data.id, pawn)
		return added > 0
	var w: Weapon = weapon_class.new()
	w.data = weapon_data
	pawn.equip_weapon(w)
	EventBus.weapon_picked_up.emit(weapon_data.id, pawn)
	return true

class_name AmmoPickup
extends Pickup
## Adds N of a given ammo type, up to the player's per-type cap.

@export var ammo_type: StringName = &"bullets"
@export var amount: int = 20

func _try_take(pawn: Pawn) -> bool:
	var gained: int = pawn.inventory.add_ammo(ammo_type, amount)
	return gained > 0

class_name ArmorPickup
extends Pickup
## Adds armor up to a cap. Shield-belt variants can override absorption.

@export var amount: float = 50.0
@export var cap: float = 100.0
@export var override_absorption: float = -1.0  # -1 = leave pawn's existing absorption alone

func _try_take(pawn: Pawn) -> bool:
	var hc: HealthComponent = pawn.health_component
	if hc.armor >= cap:
		return false
	hc.add_armor(amount, cap)
	if override_absorption >= 0.0:
		hc.armor_absorption = override_absorption
	return true

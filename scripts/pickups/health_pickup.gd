class_name HealthPickup
extends Pickup
## Restores HP. `amount` heals up to `cap_when_below_or_equal_max` if at/below max,
## otherwise up to `overcap` (used for mega-style overheal stacking).

@export var amount: float = 25.0
@export var cap_normal: float = 100.0   # standard pack caps here
@export var allow_overcap: bool = false  # mega health: stack up to HealthComponent.health_overcap

func _try_take(pawn: Pawn) -> bool:
	var hc: HealthComponent = pawn.health_component
	var cap: float = hc.health_overcap if allow_overcap else cap_normal
	if hc.health >= cap:
		return false
	hc.add_health(amount, cap)
	return true

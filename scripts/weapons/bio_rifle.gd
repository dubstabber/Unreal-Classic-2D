class_name BioRifle
extends Weapon
## Slot 3. Lobbed bio globs that settle into damaging pools. Alt = charge, release for
## a single big glob that splits into multiple pools on impact.

const BIO_GLOB_SCENE := preload("res://scenes/projectiles/bio_glob.tscn")

@export var alt_charge_max: float = 1.4
@export var alt_min_damage: float = 30.0
@export var alt_max_damage: float = 75.0
@export var alt_max_split: int = 5

var _alt_charge: float = 0.0
var _alt_was_held: bool = false

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

	var alt_held: bool = pawn.controller.wish_fire_alt
	if _alt_cooldown <= 0.0:
		if alt_held:
			_alt_charge = minf(alt_charge_max, _alt_charge + delta)
		elif _alt_was_held and not alt_held and _alt_charge > 0.0:
			var ratio: float = _alt_charge / alt_charge_max
			var cost: int = maxi(1, int(round(ratio * float(alt_max_split))))
			if pawn.inventory.consume_ammo(data.ammo_type, cost):
				_release_charged(ratio)
			_alt_charge = 0.0
			_alt_cooldown = data.alt_fire_rate
	_alt_was_held = alt_held

func primary_fire() -> void:
	_spawn_glob(data.primary_damage, 1.0, 1)

func _release_charged(ratio: float) -> void:
	var dmg: float = lerpf(alt_min_damage, alt_max_damage, ratio)
	var splits: int = maxi(1, int(round(ratio * float(alt_max_split))))
	_spawn_glob(dmg, 1.0 + ratio, splits)
	fired.emit(&"alt")

func _spawn_glob(dmg: float, scale: float, splits: int) -> BioGlob:
	var glob: BioGlob = BIO_GLOB_SCENE.instantiate() as BioGlob
	glob.damage = dmg
	glob.size_scale = scale
	glob.split_count = splits
	pawn.get_tree().current_scene.add_child(glob)
	glob.launch(barrel_position(), aim_direction(), pawn)
	return glob

class_name WeaponData
extends Resource
## Designer-tunable parameters for a weapon. Each concrete weapon ships a .tres
## referencing this script.

@export var id: StringName = &""
@export var display_name: String = ""
@export var slot: int = 0
@export var ammo_type: StringName = &""

@export var primary_fire_rate: float = 0.4   # seconds between shots
@export var alt_fire_rate: float = 0.6
@export var primary_damage: float = 25.0
@export var alt_damage: float = 0.0

@export var ammo_per_shot_primary: int = 1
@export var ammo_per_shot_alt: int = 1
@export var base_ammo_on_pickup: int = 50
@export var max_ammo: int = 200

@export var projectile_scene: PackedScene = null   # null = hitscan
@export var alt_projectile_scene: PackedScene = null

@export var muzzle_offset_local: Vector2 = Vector2(7, 0)  # from arm pivot along aim
@export var screen_shake: float = 0.0
@export var description: String = ""

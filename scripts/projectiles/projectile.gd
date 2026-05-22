class_name Projectile
extends Area2D
## Base projectile. Subclasses customise visuals + on_impact behaviour.

signal impacted(target: Node, position: Vector2)

@export var speed: float = 320.0
@export var lifetime: float = 4.0
@export var damage: float = 0.0
@export var damage_type: StringName = &"projectile"
@export var weapon_id: StringName = &""
@export var knockback_strength: float = 100.0
@export var rotate_to_velocity: bool = true
@export var affected_by_gravity: bool = false
@export var gravity_scale: float = 1.0

var velocity: Vector2 = Vector2.ZERO
var instigator: Node = null
var _alive_time: float = 0.0

const GRAVITY := 900.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func launch(from: Vector2, dir: Vector2, source: Node) -> void:
	global_position = from
	if dir.length_squared() < 0.01:
		dir = Vector2.RIGHT
	velocity = dir.normalized() * speed
	instigator = source
	if rotate_to_velocity:
		rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	if affected_by_gravity:
		velocity.y += GRAVITY * gravity_scale * delta
	global_position += velocity * delta
	if rotate_to_velocity:
		rotation = velocity.angle()
	_alive_time += delta
	if _alive_time >= lifetime:
		_expire()

func _on_body_entered(body: Node) -> void:
	if body == instigator:
		return
	if body is Pawn:
		var info := DamageInfo.make(damage, damage_type, instigator, weapon_id)
		info.knockback = velocity.normalized() * knockback_strength
		(body as Pawn).apply_damage(info)
	impacted.emit(body, global_position)
	on_impact(body)

# Subclasses override on_impact to define explosion / bounce / split behaviour.
func on_impact(_target: Node) -> void:
	queue_free()

func _expire() -> void:
	queue_free()

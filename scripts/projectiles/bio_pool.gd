class_name BioPool
extends Area2D
## Lingering green pool from the Bio Rifle. Damages and dissolves on first pawn touch.

@export var damage: float = 22.0
@export var lifetime: float = 4.0
@export var knockback: float = 30.0

var instigator: Node = null
var _alive_time: float = 0.0

func _ready() -> void:
	add_to_group(&"bio_pool")
	collision_layer = 4
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	var spr: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		spr.texture = SpriteBaker.get_texture(&"bio_pool")

func _physics_process(delta: float) -> void:
	_alive_time += delta
	if _alive_time >= lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == instigator or not (body is Pawn) or not is_inside_tree():
		return
	var info := DamageInfo.make(damage, &"bio", instigator, &"bio_rifle")
	info.knockback = Vector2(0, -knockback)
	(body as Pawn).apply_damage(info)
	queue_free()

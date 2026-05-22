class_name Pickup
extends Area2D
## Base for all pickups. Detects pawns entering, calls _try_take(pawn) override,
## hides + respawns on a timer if successful.

signal picked_up(pawn: Pawn)
signal respawned

@export var respawn_seconds: float = 30.0
@export var pickup_id: StringName = &""
@export var sprite_name: StringName = &""  # SpriteBaker texture name; assigned in _ready

var _available: bool = true
var _respawn_timer: float = 0.0

func _ready() -> void:
	add_to_group(&"pickup")
	body_entered.connect(_on_body_entered)
	_assign_sprite_texture()
	_refresh_visual()

func _assign_sprite_texture() -> void:
	if sprite_name == &"":
		return
	var spr: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		spr.texture = SpriteBaker.get_texture(sprite_name)

func _physics_process(delta: float) -> void:
	if _available:
		return
	_respawn_timer -= delta
	if _respawn_timer <= 0.0:
		_make_available()

func _on_body_entered(body: Node) -> void:
	if not _available or not (body is Pawn):
		return
	if not (body as Pawn).is_alive():
		return
	if _try_take(body as Pawn):
		picked_up.emit(body)
		EventBus.pickup_taken.emit(self, body)
		_make_unavailable()

# Subclasses override to return true if the pickup was actually consumed.
func _try_take(_pawn: Pawn) -> bool:
	return true

func _make_unavailable() -> void:
	_available = false
	_respawn_timer = respawn_seconds
	set_deferred(&"monitoring", false)
	_refresh_visual()

func _make_available() -> void:
	_available = true
	set_deferred(&"monitoring", true)
	_refresh_visual()
	respawned.emit()

func _refresh_visual() -> void:
	# Hide every Sprite2D / Polygon2D under us when unavailable; show otherwise.
	for child in get_children():
		if child is Sprite2D or child is Polygon2D:
			child.visible = _available

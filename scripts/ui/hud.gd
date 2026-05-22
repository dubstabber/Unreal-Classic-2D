class_name HUD
extends CanvasLayer
## Player-bound HUD. Reads from a watched Pawn + GameState + EventBus.
## Call `bind(pawn)` to attach.

const WEAPON_ICON_BY_SLOT := {
	1: &"icon_hammer",
	2: &"icon_enforcer",
	3: &"icon_bio",
	4: &"icon_shock",
	8: &"icon_flak",
	9: &"icon_rocket",
	0: &"icon_sniper",
}

@onready var _hp_label: Label = $Root/Bottom/HP/HPLabel
@onready var _hp_bar: ColorRect = $Root/Bottom/HP/HPBar/Fill
@onready var _armor_label: Label = $Root/Bottom/Armor/ArmorLabel
@onready var _armor_bar: ColorRect = $Root/Bottom/Armor/ArmorBar/Fill
@onready var _weapon_icon: TextureRect = $Root/Bottom/Weapon/Icon
@onready var _weapon_name: Label = $Root/Bottom/Weapon/Name
@onready var _ammo_label: Label = $Root/Bottom/Weapon/Ammo
@onready var _frags_label: Label = $Root/Top/Frags
@onready var _time_label: Label = $Root/Top/Time
@onready var _kill_feed: KillFeed = $Root/Top/KillFeed
@onready var _damage_layer: Control = $Root/DamageOverlay

var pawn: Pawn = null

func bind(p: Pawn) -> void:
	pawn = p
	if pawn == null:
		return
	pawn.damaged.connect(_on_damaged)

func _process(_delta: float) -> void:
	if pawn == null or not is_instance_valid(pawn):
		return
	_refresh()

func _refresh() -> void:
	var hc: HealthComponent = pawn.health_component
	if hc != null:
		_hp_label.text = "%d" % int(hc.health)
		_hp_bar.size.x = clampf(hc.health / hc.max_health, 0.0, 1.0) * 60.0
		_hp_bar.color = _hp_color(hc.health, hc.max_health)
		_armor_label.text = "%d" % int(hc.armor)
		_armor_bar.size.x = clampf(hc.armor / hc.max_armor, 0.0, 1.0) * 60.0
	var w: Weapon = pawn.inventory.current_weapon() as Weapon
	if w != null and w.data != null:
		var icon_name: StringName = WEAPON_ICON_BY_SLOT.get(w.data.slot, &"")
		if icon_name != &"":
			_weapon_icon.texture = SpriteBaker.get_texture(icon_name)
		_weapon_name.text = w.data.display_name
		if w.data.ammo_type != &"":
			_ammo_label.text = "%d" % pawn.inventory.get_ammo(w.data.ammo_type)
		else:
			_ammo_label.text = "—"
	# Frags + time
	var p_frags: int = GameState.scores.get(pawn.id, 0)
	# Best opponent score for context
	var opp: int = 0
	for id in GameState.scores:
		if id != pawn.id and GameState.scores[id] > opp:
			opp = GameState.scores[id]
	_frags_label.text = "Frags  %d / %d  (to %d)" % [p_frags, opp, GameState.frag_limit]
	if GameState.time_limit_seconds > 0.0:
		_time_label.text = "Time %02d:%02d" % [int(GameState.time_limit_seconds) / 60, int(GameState.time_limit_seconds) % 60]
	else:
		_time_label.text = ""

func _hp_color(h: float, m: float) -> Color:
	var t: float = clampf(h / m, 0.0, 1.0)
	var low: Color = SpriteBaker.palette.get_color(&"hp_low", Color(0.95, 0.3, 0.2, 1))
	var full: Color = SpriteBaker.palette.get_color(&"hp_full", Color(0.4, 0.95, 0.5, 1))
	return low.lerp(full, t)

func _on_damaged(info: DamageInfo) -> void:
	if info == null or pawn == null:
		return
	var attacker: Node = info.get_instigator()
	var dir: Vector2 = Vector2.UP
	if attacker is Node2D and attacker != pawn:
		dir = ((attacker as Node2D).global_position - pawn.global_position).normalized()
	DamageIndicator.spawn(_damage_layer, get_viewport().get_visible_rect().size, dir)

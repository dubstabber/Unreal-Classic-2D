class_name KillFeed
extends VBoxContainer
## Stack of recent kill notifications. Last 4 visible; each entry fades after 5s.

const MAX_ENTRIES := 4
const ENTRY_LIFETIME := 5.0

func _ready() -> void:
	EventBus.pawn_killed.connect(_on_pawn_killed)

func _on_pawn_killed(victim: Pawn, killer: Node) -> void:
	if victim == null:
		return
	var text: String
	if killer == null or killer == victim:
		text = "[%s suicided]" % _name_of(victim)
	else:
		text = "%s ▶ %s" % [_name_of(killer), _name_of(victim)]
	add_entry(text)

func add_entry(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(1, 0.95, 0.7, 1))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	while get_child_count() > MAX_ENTRIES:
		get_child(0).queue_free()
	var tw := create_tween()
	tw.tween_interval(ENTRY_LIFETIME * 0.7)
	tw.tween_property(label, "modulate:a", 0.0, ENTRY_LIFETIME * 0.3)
	tw.tween_callback(func() -> void:
		if is_instance_valid(label):
			label.queue_free())

func _name_of(node: Node) -> String:
	if node == null:
		return "?"
	if node is Pawn:
		var p: Pawn = node
		return p.display_name if p.display_name != "" else String(p.id)
	return str(node)

extends Control
## Placeholder — multiplayer is not implemented yet. The tab itself is disabled
## at the TabContainer level; this content shows if it is ever enabled.

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var label := Label.new()
	label.text = "Multiplayer — coming soon"
	label.modulate = Color(0.6, 0.65, 0.72, 1)
	center.add_child(label)

class_name Palette
extends Resource

@export var swatches: Dictionary[StringName, Color] = {}

func get_color(name: StringName, fallback: Color = Color.MAGENTA) -> Color:
	return swatches.get(name, fallback)

func has_color(name: StringName) -> bool:
	return swatches.has(name)

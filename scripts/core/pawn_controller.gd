class_name PawnController
extends Node
## Abstract input source. PlayerController reads InputMap; BotController is the AI.
## Pawn reads `wish_*` and drains `events` each physics tick.
## Pawn NEVER reads Input directly.

# Sustained intents (level-triggered; controller updates each tick)
var wish_move: float = 0.0           # -1 .. 1
var wish_crouch: bool = false
var wish_jump_held: bool = false     # held for variable jump height
var wish_fire_primary: bool = false
var wish_fire_alt: bool = false
var aim_target: Vector2 = Vector2.ZERO  # world-space

# Edge events (one-shot; Pawn drains via pop_events())
var events: Array[StringName] = []

func push_event(name: StringName) -> void:
	events.append(name)

func pop_events() -> Array[StringName]:
	var out: Array[StringName] = events
	events = []
	return out

func has_event(name: StringName) -> bool:
	return events.has(name)

extends Node

signal damage_dealt(attacker, victim, info)
signal pawn_damaged(victim, info)
signal pawn_killed(victim, killer)
signal pawn_respawned(victim)
signal pickup_taken(pickup, pawn)
signal weapon_picked_up(weapon_id: StringName, pawn)
signal match_state_changed(state: StringName)
signal shake_requested(intensity: float)
signal zoom_requested(zoom_level: float)  # 1.0 = default, >1 = zoomed in (Godot Camera2D semantics)
signal headshot(attacker: Node, victim: Node)

extends Node

enum MatchState { IDLE, COUNTDOWN, ACTIVE, ENDED }
enum Difficulty { EASY, NORMAL, HARD, INSANE }

var state: MatchState = MatchState.IDLE
var difficulty: Difficulty = Difficulty.NORMAL
var frag_limit: int = 10
var time_limit_seconds: float = 0.0
var scores: Dictionary[StringName, int] = {}
var arena: Node = null
var selected_arena_path: String = "res://scenes/arenas/arena_01.tscn"

signal match_started
signal match_ended(winner: StringName)

func difficulty_params() -> Dictionary:
	match difficulty:
		Difficulty.EASY:
			return {"aim_error_stddev": 22.0, "reaction_time_msec": 420}
		Difficulty.NORMAL:
			return {"aim_error_stddev": 10.0, "reaction_time_msec": 220}
		Difficulty.HARD:
			return {"aim_error_stddev": 5.0, "reaction_time_msec": 140}
		Difficulty.INSANE:
			return {"aim_error_stddev": 2.0, "reaction_time_msec": 70}
	return {}

func difficulty_name() -> String:
	match difficulty:
		Difficulty.EASY: return "Easy"
		Difficulty.NORMAL: return "Normal"
		Difficulty.HARD: return "Hard"
		Difficulty.INSANE: return "Insane"
	return "?"

func reset_scores() -> void:
	scores.clear()

func add_frag(killer_id: StringName) -> void:
	if killer_id == &"":
		return
	scores[killer_id] = scores.get(killer_id, 0) + 1
	if frag_limit > 0 and scores[killer_id] >= frag_limit:
		end_match(killer_id)

func end_match(winner: StringName) -> void:
	if state == MatchState.ENDED:
		return
	state = MatchState.ENDED
	EventBus.match_state_changed.emit(&"ended")
	match_ended.emit(winner)

func begin_match() -> void:
	state = MatchState.ACTIVE
	reset_scores()
	EventBus.match_state_changed.emit(&"active")
	match_started.emit()

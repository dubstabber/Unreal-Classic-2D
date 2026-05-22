class_name MatchDirector
extends Node
## Per-arena orchestrator. Listens for pawn deaths, scores kills in GameState,
## schedules respawns at random PlayerStart markers, ends the match on frag/time limit.

signal match_started
signal match_ended(winner_id: StringName)

@export var frag_limit: int = 10
@export var time_limit_seconds: float = 0.0
@export var respawn_delay: float = 1.5

var _player_starts: Array[Marker2D] = []
var _start_msec: int = 0
var _ended: bool = false

func _ready() -> void:
	EventBus.pawn_killed.connect(_on_pawn_killed)
	GameState.match_ended.connect(_on_match_ended)

func register_player_start(marker: Marker2D) -> void:
	if marker == null or _player_starts.has(marker):
		return
	_player_starts.append(marker)

func auto_register_starts(root: Node) -> void:
	for n in root.get_tree().get_nodes_in_group(&"player_start"):
		if n is Marker2D:
			register_player_start(n as Marker2D)

func start_match() -> void:
	_ended = false
	GameState.frag_limit = frag_limit
	GameState.time_limit_seconds = time_limit_seconds
	GameState.begin_match()
	_start_msec = Time.get_ticks_msec()
	match_started.emit()

func _process(_delta: float) -> void:
	if _ended or time_limit_seconds <= 0.0:
		return
	var elapsed: float = (Time.get_ticks_msec() - _start_msec) / 1000.0
	if elapsed >= time_limit_seconds:
		_end_on_time()

func _end_on_time() -> void:
	var winner: StringName = &""
	var best: int = -1
	for id in GameState.scores:
		var s: int = GameState.scores[id]
		if s > best:
			best = s
			winner = id
	GameState.end_match(winner)

func _on_pawn_killed(victim: Pawn, killer: Node) -> void:
	if _ended:
		return
	var killer_id: StringName = &""
	if killer is Pawn and killer != victim:
		killer_id = (killer as Pawn).id
		GameState.add_frag(killer_id)
	# Schedule respawn unless the match is over.
	if not _ended and victim != null and is_instance_valid(victim):
		_schedule_respawn(victim)

func _schedule_respawn(pawn: Pawn) -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(respawn_delay)
	timer.timeout.connect(func() -> void:
		if pawn == null or not is_instance_valid(pawn):
			return
		if _ended:
			return
		pawn.respawn(pick_spawn_point()))

func pick_spawn_point() -> Vector2:
	if _player_starts.is_empty():
		return Vector2.ZERO
	return _player_starts.pick_random().global_position

func _on_match_ended(winner_id: StringName) -> void:
	_ended = true
	match_ended.emit(winner_id)

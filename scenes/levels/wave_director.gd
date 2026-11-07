class_name WaveDirector
extends Node
## Spends a growing difficulty budget on waves from the level's pool (DESIGN.md §9). Asks the Level
## to spawn each enemy (signal up), then reports when the sector is done.

signal spawn_requested(scene: PackedScene, at: Vector2, elite: bool)
## Time is up and the screen is clear.
signal sector_cleared

## Threat Level (§9.1) scales the budget and the elite chance; the tables are in GameState.
## Keeps formations away from the screen edges.
@export var edge_margin: float = 60.0
## After time is up, call the sector clear anyway if stragglers take longer than this.
@export var clear_timeout: float = 8.0

var level_data: LevelData
## Where live enemies are, so the director can count them. Set by the Level.
var enemies: Node

var _elapsed: float = 0.0
var _budget: float = 0.0
var _gap_left: float = 0.0
var _next_wave: WaveData
var _finished_spawning: bool = false
var _wait_after_end: float = 0.0
var _done: bool = false
# Staggered side/scatter entries waiting to spawn: [time_left, scene, position, elite].
var _queue: Array[Array] = []


func _physics_process(delta: float) -> void:
	if level_data == null or _done:
		return
	_elapsed += delta
	_update_queue(delta)
	if not _finished_spawning:
		_update_spawning(delta)
		return
	_wait_after_end += delta
	if (enemies.get_child_count() == 0 and _queue.is_empty()) or _wait_after_end >= clear_timeout:
		_done = true
		sector_cleared.emit()


## 0-1: how far through the sector's spawning time we are (for the HUD progress track).
func progress() -> float:
	if level_data == null or level_data.duration <= 0.0:
		return 0.0
	return clampf(_elapsed / level_data.duration, 0.0, 1.0)


func _update_spawning(delta: float) -> void:
	if _elapsed >= level_data.duration:
		_finished_spawning = true
		return
	var rate: float = level_data.budget_rate + level_data.budget_growth * _elapsed
	_budget += rate * GameState.threat_budget_multiplier() * delta
	_gap_left -= delta
	if _next_wave == null:
		_next_wave = _pick_wave()
	if _next_wave == null or _gap_left > 0.0:
		return
	if _budget < _next_wave.cost or enemies.get_child_count() >= level_data.max_enemies_alive:
		return
	_budget -= _next_wave.cost
	_send(_next_wave)
	_next_wave = null
	_gap_left = level_data.min_wave_gap


func _pick_wave() -> WaveData:
	var total: float = 0.0
	for wave: WaveData in level_data.wave_pool:
		if wave.min_time <= _elapsed:
			total += wave.weight
	if total <= 0.0:
		return null
	var roll: float = randf() * total
	for wave: WaveData in level_data.wave_pool:
		if wave.min_time > _elapsed:
			continue
		roll -= wave.weight
		if roll <= 0.0:
			return wave
	return null


func _send(wave: WaveData) -> void:
	var size: Vector2 = get_viewport().get_visible_rect().size
	var entry: WaveData.Entry = wave.entry
	if entry == WaveData.Entry.SIDE_RANDOM:
		entry = WaveData.Entry.LEFT if randf() < 0.5 else WaveData.Entry.RIGHT

	if entry == WaveData.Entry.TOP:
		var lane: float = wave.lane if wave.lane >= 0.0 else randf()
		var x: float = lerpf(edge_margin, size.x - edge_margin, lane)
		for i: int in wave.count:
			var at: Vector2 = _top_slot(wave, i, x, size.x)
			spawn_requested.emit(wave.enemy_scene, at, _roll_elite())
	else:
		# Side entries come in one after another along the same lane.
		var lane: float = wave.lane if wave.lane >= 0.0 else randf()
		var y: float = lerpf(100.0, size.y * 0.4, lane)
		var x: float = -50.0 if entry == WaveData.Entry.LEFT else size.x + 50.0
		var delay_step: float = wave.spacing / 60.0
		for i: int in wave.count:
			_queue.append([i * delay_step, wave.enemy_scene, Vector2(x, y), _roll_elite()])


func _roll_elite() -> bool:
	return randf() < GameState.threat_elite_chance()


## Where member `i` of a top-entry formation starts (just above the screen).
func _top_slot(wave: WaveData, i: int, x: float, width: float) -> Vector2:
	var top: float = -40.0
	var at: Vector2
	match wave.formation:
		WaveData.Formation.COLUMN:
			at = Vector2(x, top - i * wave.spacing)
		WaveData.Formation.ROW:
			at = Vector2(x + (i - (wave.count - 1) * 0.5) * wave.spacing, top)
		WaveData.Formation.V:
			# Leader at the point, then alternating left/right wings trailing behind.
			var rank: int = (i + 1) / 2
			var side: float = -1.0 if i % 2 == 1 else 1.0
			at = Vector2(x + side * rank * wave.spacing, top - rank * wave.spacing * 0.7)
		WaveData.Formation.SCATTER:
			at = Vector2(randf_range(edge_margin, width - edge_margin), top - i * wave.spacing * randf_range(0.6, 1.4))
		_:
			at = Vector2(x, top)
	at.x = clampf(at.x, edge_margin * 0.5, width - edge_margin * 0.5)
	return at


func _update_queue(delta: float) -> void:
	var i: int = 0
	while i < _queue.size():
		_queue[i][0] -= delta
		if _queue[i][0] <= 0.0:
			spawn_requested.emit(_queue[i][1], _queue[i][2], _queue[i][3])
			_queue.remove_at(i)
		else:
			i += 1

extends Node2D
## Game rules for one run: score, time limit, end of the game. Wires the
## terrain, the miner and the HUD together; they never reach each other.

@export var time_limit: float = 60.0
@export var mine: MineData
@export var mine_seed: int = 0   # 0 = random. Set a printed seed to replay a mine.

var score := 0
var _is_over := false
var _is_loading := false
var _miner_start: Vector2
var _pending_layout: MineLayout   # written by the generation thread

@onready var _terrain: Terrain = %Terrain
@onready var _miner: Miner = %Miner
@onready var _hud: HUD = %HUD
@onready var _camera: Camera2D = %Camera2D
@onready var _timer: Timer = %TimeLimit
@onready var _loading_screen: LoadingScreen = %LoadingScreen


func _ready() -> void:
	assert(mine != null, "MineLevel: assign a MineData to 'mine' in the inspector")
	_terrain.block_broken.connect(_on_block_broken)
	_miner.energy_changed.connect(_on_energy_changed)
	_hud.retry_requested.connect(_restart)
	_timer.timeout.connect(_end)
	_hud.setup(_miner.energy)
	_miner_start = _miner.position

	await _load_mine(mine_seed if mine_seed != 0 else randi())
	_timer.start(time_limit)


func _process(_delta: float) -> void:
	_hud.set_time(_timer.time_left)


# Debug builds only: press R (regenerate_mine) to try a new seed.
func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("regenerate_mine") \
			and not _is_loading and not _is_over:
		_load_mine(randi())


## Generates the mine on a worker thread, then draws it over several frames
## while the loading screen shows the progress.
func _load_mine(run_seed: int) -> void:
	_is_loading = true
	print("Mine seed: ", run_seed)   # to reproduce a bug
	_loading_screen.start()
	_miner.process_mode = Node.PROCESS_MODE_DISABLED   # don't fall into the void
	_timer.paused = true

	var task := WorkerThreadPool.add_task(func(): _pending_layout = MineGenerator.generate(mine, run_seed))
	while not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(task)

	await _terrain.build_async(_pending_layout, _loading_screen.set_progress)
	_pending_layout = null
	_set_camera_limits(_terrain.get_world_rect())

	_miner.position = _miner_start
	_miner.velocity = Vector2.ZERO
	_miner.process_mode = Node.PROCESS_MODE_INHERIT
	_timer.paused = false
	_loading_screen.finish()
	_is_loading = false


func _set_camera_limits(area: Rect2) -> void:
	# No top limit: the camera can show the sky above the mine.
	_camera.limit_left = int(area.position.x)
	_camera.limit_right = int(area.end.x)
	_camera.limit_bottom = int(area.end.y)


func _on_block_broken(_cell: Vector2i, block: BlockData, ore: OreData) -> void:
	score += ore.value if ore else block.value
	_hud.set_score(score)


func _on_energy_changed(energy: int) -> void:
	_hud.set_energy(energy)
	if energy <= 0:
		_end()


func _end() -> void:
	if _is_over:
		return
	_is_over = true
	get_tree().paused = true
	_miner.die()
	_hud.show_game_over(score)


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

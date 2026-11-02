extends Node2D
## Game rules for one run: score, time limit, end of the game. Wires the
## terrain, the miner and the HUD together; they never reach each other.

@export var time_limit: float = 60.0
@export var mine: MineData
@export var seed: int = 0

var score := 0
var _is_over := false

@onready var _terrain: Terrain = %Terrain
@onready var _miner: Miner = %Miner
@onready var _hud: HUD = %HUD
@onready var _camera: Camera2D = %Camera2D
@onready var _timer: Timer = %TimeLimit


func _ready() -> void:
	var run_seed := seed if seed != 0 else randi()
	print("Mine seed: ", run_seed)  # to reproduce a bug
	var layout := MineGenerator.generate(mine, run_seed)
	_terrain.build(layout)
	_terrain.block_broken.connect(_on_block_broken)
	_miner.energy_changed.connect(_on_energy_changed)
	_hud.retry_requested.connect(_restart)
	_timer.timeout.connect(_end)
	_timer.start(time_limit)

	_hud.setup(_miner.energy)
	_set_camera_limits(_terrain.get_world_rect())


func _process(_delta: float) -> void:
	_hud.set_time(_timer.time_left)


func _set_camera_limits(area: Rect2) -> void:
	# No top limit: the camera can show the sky above the mine.
	_camera.limit_left = int(area.position.x)
	_camera.limit_right = int(area.end.x)
	_camera.limit_bottom = int(area.end.y)


func _on_block_broken(_cell: Vector2i, block: BlockData) -> void:
	score += block.value
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

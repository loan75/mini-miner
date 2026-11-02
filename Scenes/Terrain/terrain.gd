class_name Terrain
extends Node2D
## Owns the diggable layers: which block sits in each cell, the damage dealt
## to it, the cracks overlay and what happens when a block breaks.

signal block_broken(cell: Vector2i, block: BlockData)

const DIG_PARTICLES := preload("uid://dqcdtnt3m2aaa")
const CRACK_STAGES := 4
const TERRAIN_SET := 0

var _damage: Dictionary[Vector2i, float] = {}
var _to_clear: Array[Vector2i] = []

@onready var _ground: TileMapLayer = $Mine
@onready var _ore: TileMapLayer = $Ore
@onready var _cracks: TileMapLayer = $Cracks


## The block in this cell, or null if there is nothing to dig.
func get_block(cell: Vector2i) -> BlockData:
	if _ground.get_cell_source_id(cell) == -1 or cell in _to_clear:
		return null
	var data := _ore.get_cell_tile_data(cell)
	if data == null:
		data = _ground.get_cell_tile_data(cell)
	return data.get_custom_data("block") if data else null


func world_to_cell(world_position: Vector2) -> Vector2i:
	return _ground.local_to_map(_ground.to_local(world_position))


func cell_to_world(cell: Vector2i) -> Vector2:
	return _ground.to_global(_ground.map_to_local(cell))


## The area covered by the diggable ground, in world coordinates.
func get_world_rect() -> Rect2:
	var rect := _ground.get_used_rect()
	var tile := Vector2(_ground.tile_set.tile_size)
	var top_left := _ground.to_global(Vector2(rect.position) * tile)
	return Rect2(top_left, Vector2(rect.size) * tile)


## Deals damage to a cell. Returns true if the block broke.
func hit(cell: Vector2i, power: float) -> bool:
	var block := get_block(cell)
	if block == null:
		return false
	_damage[cell] = _damage.get(cell, 0.0) + power
	if _damage[cell] < block.hardness:
		_update_cracks(cell, _damage[cell] / block.hardness)
		return false

	_damage.erase(cell)
	_cracks.erase_cell(cell)
	_ore.erase_cell(cell)
	if _to_clear.is_empty():
		_flush_cleared_cells.call_deferred()
	_to_clear.append(cell)
	_spawn_particles(cell, block)
	block_broken.emit(cell, block)
	return true

func build(layout: MineLayout) -> void:
	_ground.clear()
	_ore.clear()
	_cracks.clear()
	_damage.clear()

	var cells_by_terrain: Dictionary[int, Array] = {}
	for cell in layout.blocks:
		var block := layout.blocks[cell]
		cells_by_terrain.get_or_add(block.terrain, []).append(cell)
		if block.overlay_tile != Vector2i(-1, -1):
			_ore.set_cell(cell, 0, block.overlay_tile)
	for terrain in cells_by_terrain:   # one auto-tiling call per terrain type
		_ground.set_cells_terrain_connect(cells_by_terrain[terrain], TERRAIN_SET, terrain)

# Removes every cell broken this frame with a single auto-tiling update,
# so a drill or an explosion does not recompute the terrain once per cell.
func _flush_cleared_cells() -> void:
	_ground.set_cells_terrain_connect(_to_clear, TERRAIN_SET, -1)
	_to_clear.clear()


func _update_cracks(cell: Vector2i, ratio: float) -> void:
	var stage := mini(int(ratio * CRACK_STAGES), CRACK_STAGES - 1)
	_cracks.set_cell(cell, 0, Vector2i(stage, 0))


func _spawn_particles(cell: Vector2i, block: BlockData) -> void:
	var fx := DIG_PARTICLES.instantiate()
	fx.position = to_local(cell_to_world(cell))
	if block.particle_gradient:
		fx.color_ramp = block.particle_gradient
	add_child(fx)

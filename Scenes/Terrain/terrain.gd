class_name Terrain
extends Node2D
## Owns the diggable layers: which block and ore sit in each cell, the damage
## dealt to it, the cracks overlay and what happens when a block breaks.

signal block_broken(cell: Vector2i, block: BlockData, ore: OreData)

const DIG_PARTICLES := preload("uid://dqcdtnt3m2aaa")
const CRACK_STAGES := 4
const TERRAIN_SET := 0
const SOURCE_ID := 0
const ROWS_PER_FRAME := 16   # build_async: rows drawn between two frames

# Order matters: bit i of a mask is set when the neighbour on SIDES[i] is
# the same terrain. PEERING_SIDES gives the matching TileSet peering bit.
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const PEERING_SIDES: Array[int] = [
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
]

var _layout: MineLayout
var _damage: Dictionary[Vector2i, float] = {}
var _to_clear: Array[Vector2i] = []
var _tiles_by_mask: Dictionary[int, Dictionary] = {}   # terrain -> {mask -> atlas coords}
var _fallback: Dictionary[int, Array] = {}             # terrain -> cells with no matching tile

@onready var _ground: TileMapLayer = $Mine
@onready var _ore: TileMapLayer = $Ore
@onready var _cracks: TileMapLayer = $Cracks


func _ready() -> void:
	_read_terrain_tiles()


# --- Queries ------------------------------------------------------------------

## The ground block in this cell, or null if the cell is empty.
func get_block(cell: Vector2i) -> BlockData:
	if _ground.get_cell_source_id(cell) == -1 or cell in _to_clear:
		return null
	var data := _ground.get_cell_tile_data(cell)
	return data.get_custom_data("block") as BlockData if data else null


## The ore embedded in this cell, or null.
func get_ore(cell: Vector2i) -> OreData:
	if cell in _to_clear:
		return null
	var data := _ore.get_cell_tile_data(cell)
	return data.get_custom_data("ore") as OreData if data else null


## Total hardness of the cell: its block plus its ore, if any.
func get_hardness(cell: Vector2i) -> float:
	var block := get_block(cell)
	if block == null:
		return 0.0
	var ore := get_ore(cell)
	return block.hardness + (ore.extra_hardness if ore else 0.0)


## True if the cell holds a block that can be dug (not an edge of the mine).
func is_diggable(cell: Vector2i) -> bool:
	if _layout and _layout.is_border(cell):
		return false
	return get_block(cell) != null


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


# --- Digging ------------------------------------------------------------------

## Deals damage to a cell. Returns true if the block broke.
func hit(cell: Vector2i, power: float) -> bool:
	if not is_diggable(cell):
		return false
	var block := get_block(cell)
	var ore := get_ore(cell)
	var hardness := get_hardness(cell)
	_damage[cell] = _damage.get(cell, 0.0) + power
	if _damage[cell] < hardness:
		_update_cracks(cell, _damage[cell] / hardness)
		return false

	_damage.erase(cell)
	_cracks.erase_cell(cell)
	_ore.erase_cell(cell)
	if _to_clear.is_empty():
		_flush_cleared_cells.call_deferred()
	_to_clear.append(cell)
	var gradient := ore.particle_gradient if ore and ore.particle_gradient else block.particle_gradient
	_spawn_particles(cell, gradient)
	block_broken.emit(cell, block, ore)
	return true


# Removes every cell broken this frame with a single auto-tiling update,
# so a drill or an explosion does not recompute the terrain once per cell.
func _flush_cleared_cells() -> void:
	_ground.set_cells_terrain_connect(_to_clear, TERRAIN_SET, -1)
	_to_clear.clear()


func _update_cracks(cell: Vector2i, ratio: float) -> void:
	var stage := mini(int(ratio * CRACK_STAGES), CRACK_STAGES - 1)
	_cracks.set_cell(cell, SOURCE_ID, Vector2i(stage, 0))


func _spawn_particles(cell: Vector2i, gradient: Gradient) -> void:
	var fx := DIG_PARTICLES.instantiate()
	fx.position = to_local(cell_to_world(cell))
	if gradient:
		fx.color_ramp = gradient
	add_child(fx)


# --- Building from a layout ---------------------------------------------------

## Draws a whole layout in one go. Fine for small mines; use build_async for
## big ones so the game keeps running and can show a progress bar.
func build(layout: MineLayout) -> void:
	_begin_build(layout)
	for y in layout.size.y:
		_build_row(y)
	_end_build()


## Draws the layout a few rows per frame. on_progress receives 0.0 to 1.0.
func build_async(layout: MineLayout, on_progress: Callable = Callable()) -> void:
	_begin_build(layout)
	for y in layout.size.y:
		_build_row(y)
		if y % ROWS_PER_FRAME == ROWS_PER_FRAME - 1:
			if on_progress.is_valid():
				on_progress.call(float(y + 1) / layout.size.y)
			await get_tree().process_frame
	_end_build()
	if on_progress.is_valid():
		on_progress.call(1.0)


func _begin_build(layout: MineLayout) -> void:
	_layout = layout
	_ground.clear()
	_ore.clear()
	_cracks.clear()
	_damage.clear()
	_to_clear.clear()
	_fallback.clear()


# Auto-tiling with set_cells_terrain_connect() is slow on thousands of cells.
# The tileset uses "Match Sides", so a tile only depends on its 4 neighbours:
# compute that mask from the layout and place the matching tile directly.
func _build_row(y: int) -> void:
	for x in _layout.size.x:
		var cell := Vector2i(x, y)
		var block := _layout.blocks.get(cell) as BlockData
		if block == null:
			continue
		var tiles: Dictionary = _tiles_by_mask.get(block.terrain, {})
		var mask := _neighbour_mask(cell, block.terrain)
		if tiles.has(mask):
			_ground.set_cell(cell, SOURCE_ID, tiles[mask])
		else:
			_fallback.get_or_add(block.terrain, []).append(cell)

		var ore := _layout.ores.get(cell) as OreData
		if ore:
			_ore.set_cell(cell, SOURCE_ID, ore.tile)


# Cells whose neighbour combination has no tile in the tileset go through
# Godot's own (slower) auto-tiling, once per terrain.
func _end_build() -> void:
	for terrain in _fallback:
		_ground.set_cells_terrain_connect(_fallback[terrain], TERRAIN_SET, terrain)
	_fallback.clear()


func _neighbour_mask(cell: Vector2i, terrain: int) -> int:
	var mask := 0
	for side in SIDES.size():
		var neighbour := _layout.blocks.get(cell + SIDES[side]) as BlockData
		if neighbour and neighbour.terrain == terrain:
			mask |= 1 << side
	return mask


# Reads which atlas tile matches each neighbour mask, from the peering bits
# set in the TileSet editor, so no coordinates are written by hand.
func _read_terrain_tiles() -> void:
	var source := _ground.tile_set.get_source(SOURCE_ID) as TileSetAtlasSource
	for i in source.get_tiles_count():
		var coords := source.get_tile_id(i)
		var data := source.get_tile_data(coords, 0)
		if data.terrain_set != TERRAIN_SET or data.terrain == -1:
			continue
		var mask := 0
		for side in PEERING_SIDES.size():
			if data.get_terrain_peering_bit(PEERING_SIDES[side]) == data.terrain:
				mask |= 1 << side
		var tiles: Dictionary = _tiles_by_mask.get_or_add(data.terrain, {})
		if not tiles.has(mask) or data.probability > source.get_tile_data(tiles[mask], 0).probability:
			tiles[mask] = coords   # with variants, keep the most frequent one

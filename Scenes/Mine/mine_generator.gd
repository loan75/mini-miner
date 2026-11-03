class_name MineGenerator
extends RefCounted
## Turns a MineData and a seed into a MineLayout. Never touches nodes, so it
## can run on a worker thread. The same seed always gives the same mine.
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const AROUND: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0),
	Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]


static func generate(data: MineData, run_seed: int) -> MineLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	var noise: FastNoiseLite = data.noise.duplicate()   # never modify the .tres
	noise.seed = run_seed

	var layout := MineLayout.new()
	layout.size = data.size
	for y in layout.size.y:
		# What can spawn only depends on the depth: compute it once per row.
		var block_spawns := data.blocks.filter(func(s: BlockSpawn): return s.allows_depth(y))
		var block_weights := PackedFloat32Array(block_spawns.map(func(s: BlockSpawn): return s.weight))
		var ore_spawns := data.ores.filter(func(s: OreSpawn): return s.allows_depth(y))

		for x in layout.size.x:
			var cell := Vector2i(x, y)
			var is_border := layout.is_border(cell)
			if not is_border and noise.get_noise_2d(x, y) < data.cave_threshold:
				continue   # empty pocket
			var block := _pick_block(block_spawns, block_weights, rng)
			if block == null:
				continue
			layout.blocks[cell] = block
	_place_ores(layout, data, rng)
	return layout

static func _place_ores(layout: MineLayout, data: MineData, rng: RandomNumberGenerator) -> void:
	for spawn: OreSpawn in data.ores:   # rarest first
		for cell in layout.blocks:
			if rng.randf() >= spawn.chance:   # cheap test first
				continue
			if _can_hold_ore(layout, spawn, cell) and not _touches_ore(layout, cell, []):
				var size := rng.randi_range(spawn.vein_size_min, spawn.vein_size_max)
				_grow_vein(layout, spawn, cell, size, rng)


## Grows from random cells of the vein, so it always stays in one piece.
static func _grow_vein(layout: MineLayout, spawn: OreSpawn, start: Vector2i,
		size: int, rng: RandomNumberGenerator) -> void:
	var vein: Array[Vector2i] = [start]
	layout.ores[start] = spawn.ore
	for attempt in size * 8:   # caves or neighbours can block it: cap the tries
		if vein.size() >= size:
			return
		var cell := vein[rng.randi() % vein.size()] + DIRECTIONS[rng.randi() % DIRECTIONS.size()]
		if _can_hold_ore(layout, spawn, cell) and not _touches_ore(layout, cell, vein):
			layout.ores[cell] = spawn.ore
			vein.append(cell)

static func _can_hold_ore(layout: MineLayout, spawn: OreSpawn, cell: Vector2i) -> bool:
	var host := layout.blocks.get(cell) as BlockData
	return host != null and not layout.ores.has(cell) and not layout.is_border(cell) \
		and spawn.allows_depth(cell.y) and spawn.allows_host(host)

## True if an ore that is not part of this vein touches the cell, diagonals included.
static func _touches_ore(layout: MineLayout, cell: Vector2i, vein: Array[Vector2i]) -> bool:
	for offset in AROUND:
		var neighbour := cell + offset
		if layout.ores.has(neighbour) and neighbour not in vein:
			return true
	return false

static func _pick_block(spawns: Array, weights: PackedFloat32Array, rng: RandomNumberGenerator) -> BlockData:
	if spawns.is_empty():
		return null
	var index := rng.rand_weighted(weights)   # -1 if every weight is 0
	return spawns[index].block if index >= 0 else null


## The list order is the priority: put the rarest ores first.
static func _pick_ore(spawns: Array, host: BlockData, rng: RandomNumberGenerator) -> OreData:
	for spawn: OreSpawn in spawns:
		if spawn.allows_host(host) and rng.randf() < spawn.chance:
			return spawn.ore
	return null

class_name MineGenerator
extends RefCounted
## Turns a MineData and a seed into a MineLayout. Never touches nodes, so it
## can run on a worker thread. The same seed always gives the same mine.


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
			if not is_border:   # an ore that cannot be dug would only frustrate
				var ore := _pick_ore(ore_spawns, block, rng)
				if ore:
					layout.ores[cell] = ore
	return layout


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

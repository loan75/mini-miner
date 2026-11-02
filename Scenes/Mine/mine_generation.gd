class_name MineGenerator
extends RefCounted


static func generate(data: MineData, seed: int) -> MineLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var noise: FastNoiseLite = data.noise.duplicate()   # never modify the .tres
	noise.seed = seed

	var layout := MineLayout.new()
	layout.size = Vector2i(data.size.x, data.size.y)
	for y in layout.size.y:
		for x in layout.size.x:
			if noise.get_noise_2d(x, y) < data.cave_threshold:
				continue   # empty pocket
			var block := _pick_block(data.blocks, y, rng)
			if block:
				layout.blocks[Vector2i(x, y)] = block
	return layout


static func _pick_block(spawns: Array[BlockSpawn], depth: int, rng: RandomNumberGenerator) -> BlockData:
	var allowed := spawns.filter(func(s): return depth >= s.min_depth and depth <= s.max_depth)
	if allowed.is_empty():
		return null
	var weights := PackedFloat32Array(allowed.map(func(s): return s.weight))
	return allowed[rng.rand_weighted(weights)].block

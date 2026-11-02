class_name MineData
extends Resource
## Parameters of a mine. The generation itself lives in MineGenerator.

@export var name: StringName
@export var size: Vector2i = Vector2i(40, 100)   # in cells
@export var noise: FastNoiseLite
@export_range(-1.0, 1.0) var cave_threshold: float = -0.3   # lower = fewer caves

@export_group("Spawns")
@export var blocks: Array[BlockSpawn] = []
@export var ores: Array[OreSpawn] = []
@export var items: Array[ItemData] = []        # treasures (not placed yet)
@export var enemies: Array[EnemyData] = []     # not placed yet

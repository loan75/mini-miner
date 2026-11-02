class_name MineData
extends Resource

@export var name: StringName
@export var blocks: Array[BlockSpawn] 		# Blocks that spawn in the mine
@export var items: Array[ItemData]	# reasures that spawn in the mine
@export var ennemies: Array[EnemyData]	# enemies that spawn in the mine
@export var size: Vector2i
@export var noise: FastNoiseLite
@export_range(-1.0, 1.0) var cave_threshold: float = -0.3

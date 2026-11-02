class_name BlockSpawn
extends Resource

@export var block: BlockData
@export_range(0.0, 100.0, 0.1, "or_greater") var weight: float = 1.0
@export var min_depth: int = 0       # in cells, 0 = top of the mine
@export var max_depth: int = 9999

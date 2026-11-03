class_name BlockSpawn
extends Resource
## How often a block appears in a mine, and at which depths.

@export var block: BlockData
@export_range(0.0, 100.0, 0.1, "or_greater") var weight: float = 1.0
@export var min_depth: int = 0       # in cells, 0 = top of the mine
@export var max_depth: int = 9999


func allows_depth(depth: int) -> bool:
	return depth >= min_depth and depth <= max_depth

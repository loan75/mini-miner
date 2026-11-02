class_name OreSpawn
extends Resource
## How often an ore appears in a mine, at which depths and in which blocks.

@export var ore: OreData
@export_range(0.0, 1.0, 0.001) var chance: float = 0.05   # per eligible cell
@export var min_depth: int = 0       # in cells, 0 = top of the mine
@export var max_depth: int = 9999
@export var host_blocks: Array[BlockData] = []   # empty = any block


func allows_depth(depth: int) -> bool:
	return depth >= min_depth and depth <= max_depth


func allows_host(host: BlockData) -> bool:
	return host_blocks.is_empty() or host in host_blocks

class_name MineLayout
extends RefCounted
## The result of a generation: what goes in each cell when the mine starts.
## Plain data, no nodes. It is not updated while the player digs.

var size: Vector2i
var blocks: Dictionary[Vector2i, BlockData] = {}
var ores: Dictionary[Vector2i, OreData] = {}
var items: Dictionary[Vector2i, ItemData] = {}
var enemy_spawns: Dictionary[Vector2i, EnemyData] = {}


## The left, right and bottom edges are always solid and cannot be dug,
## so the player can never leave the mine. The top stays open.
func is_border(cell: Vector2i) -> bool:
	return cell.x <= 0 or cell.x >= size.x - 1 or cell.y >= size.y - 1

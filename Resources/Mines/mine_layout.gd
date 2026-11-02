class_name MineLayout
extends RefCounted

var size: Vector2i
var blocks: Dictionary[Vector2i, BlockData] = {}
var items: Dictionary[Vector2i, ItemData] = {}
var enemy_spawns: Dictionary[Vector2i, EnemyData] = {}

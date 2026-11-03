class_name BlockData
extends Resource
## A type of ground (dirt, rock...). Ores are separate: see OreData.

@export var name: StringName
@export var hardness: float = 1.0      # hits to break with a power-1 pickaxe
@export var value: int = 0             # points when broken
@export var hit_sound: AudioStream
@export var particle_gradient: Gradient
@export var terrain: int = 0           # terrain in the Mine tileset's terrain set

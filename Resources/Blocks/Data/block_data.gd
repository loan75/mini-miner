class_name BlockData
extends Resource

@export var name: StringName
@export var hardness: float = 1.0      # hits to break with a power-1 pickaxe
@export var value: int = 0             # points when broken
@export var hit_sound: AudioStream
@export var particle_gradient: Gradient
@export var terrain: int = 0                          # terrain in the terrain set (dirt, rock...)
@export var overlay_tile: Vector2i = Vector2i(-1, -1)  # tile on the Ore layer, or none

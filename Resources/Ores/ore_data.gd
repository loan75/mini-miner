class_name OreData
extends Resource
## Something embedded in a block (gold, ruby...). Drawn on the Ore layer
## over any ground block, so the same ore can appear in dirt or in rock.

@export var id: StringName
@export var name: String
@export var tile: Vector2i                  # atlas coordinates on the Ore layer
@export var extra_hardness: float = 0.0     # added to the host block's hardness
@export var value: int = 0                  # points when broken
@export var hit_sound: AudioStream
@export var particle_gradient: Gradient

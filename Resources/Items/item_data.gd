class_name ItemData
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

@export var id: StringName
@export var name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON
@export var sell_value: int = 0
@export var bag_size: int = 1          # space taken in the bag
@export var max_stack: int = 1
@export var pickup_sound: AudioStream

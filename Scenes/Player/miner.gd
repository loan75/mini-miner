class_name Miner
extends CharacterBody2D
## The player. Two independent state machines: Move (on the ground, in the
## air, dead) and Action (digging or not), so the miner can dig mid-jump.

signal energy_changed(energy: int)

enum Move { GROUND, AIR, DEAD }
enum Action { NONE, DIG }

const SPEED := 100.0
const JUMP_VELOCITY := -200.0
const PROBE := 2.0   # pixels beyond the edge of the body
const NO_TARGET := Vector2i(-1, -1)

@export var terrain: Terrain
@export var dig_time: float = 1.0
@export var pickaxe_power: float = 1.0
@export var energy_cost: int = 5
@export var energy: int = 100

var move := Move.GROUND
var action := Action.NONE
var facing := Vector2i.RIGHT

var _dig_progress := 0.0
var _dig_target := NO_TARGET

@onready var _sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var _body: CollisionShape2D = %CollisionShape2D
@onready var _pickaxe_sound: AudioStreamPlayer = %PickaxeEffect


func _physics_process(delta: float) -> void:
	if move == Move.DEAD:
		return
	_update_facing()
	_update_action(delta)
	if move == Move.DEAD:   # the last hit can end the game
		return
	_update_move(delta)
	_update_animation()
	move_and_slide()


func die() -> void:
	_set_action(Action.NONE)
	move = Move.DEAD
	_sprite.play(&"dead")


# --- Move state machine -------------------------------------------------------

func _update_move(delta: float) -> void:
	move = Move.GROUND if is_on_floor() else Move.AIR

	if move == Move.AIR:
		velocity += get_gravity() * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	if action == Action.DIG:
		velocity.x = facing.x * SPEED   # keep pressing against the wall being dug
	else:
		var direction := Input.get_axis("move_left", "move_right")
		velocity.x = direction * SPEED if direction else move_toward(velocity.x, 0, SPEED)


func _update_facing() -> void:
	if Input.is_action_pressed("move_down"):
		facing = Vector2i.DOWN
	elif Input.is_action_pressed("move_left"):
		facing = Vector2i.LEFT
	elif Input.is_action_pressed("move_right"):
		facing = Vector2i.RIGHT


# --- Action state machine -----------------------------------------------------

func _update_action(delta: float) -> void:
	var target := _get_dig_target()
	if _is_dig_pressed() and _can_dig(target):
		_set_action(Action.DIG)
		_dig(target, delta)
	else:
		_set_action(Action.NONE)


func _set_action(new_action: Action) -> void:
	if new_action == action:
		return
	action = new_action
	_dig_progress = 0.0
	_dig_target = NO_TARGET


func _is_dig_pressed() -> bool:
	return Input.is_action_pressed("move_left") \
		or Input.is_action_pressed("move_right") \
		or Input.is_action_pressed("move_down")


func _get_dig_target() -> Vector2i:
	var half := (_body.shape as RectangleShape2D).size / 2.0
	# A point just past the edge of the body, in the direction the miner faces.
	var probe := global_position + _body.position \
		+ Vector2(facing) * (half + Vector2(PROBE, PROBE))
	return terrain.world_to_cell(probe)


func _can_dig(cell: Vector2i) -> bool:
	if not terrain.is_diggable(cell):
		return false
	if facing.x != 0:   # sideways: the miner must be against the wall
		return is_on_wall() and signf(get_wall_normal().x) == -facing.x
	return is_on_floor()   # downwards: the miner must stand on the block


func _dig(target: Vector2i, delta: float) -> void:
	if target != _dig_target:
		_dig_target = target
		_dig_progress = 0.0
		_sprite.set_frame_and_progress(0, 0.0)
	_dig_progress += delta
	if _dig_progress < dig_time:
		return

	_play_hit_sound(target)
	terrain.hit(target, pickaxe_power)
	energy -= energy_cost
	energy_changed.emit(energy)
	_dig_progress = 0.0
	_dig_target = NO_TARGET


# The ore sounds different from the ground around it: gold rings, dirt thuds.
func _play_hit_sound(cell: Vector2i) -> void:
	var ore := terrain.get_ore(cell)
	var sound := ore.hit_sound if ore and ore.hit_sound else terrain.get_block(cell).hit_sound
	if sound and _pickaxe_sound.stream != sound:
		_pickaxe_sound.stream = sound
	_pickaxe_sound.play()


# --- Animation ----------------------------------------------------------------

func _update_animation() -> void:
	if action == Action.DIG:
		_play_dig_animation()
	elif velocity.x != 0:
		_sprite.flip_h = velocity.x < 0
		_sprite.play(&"walk_right")
	else:
		_sprite.play(&"default")


func _play_dig_animation() -> void:
	var anim := &"mine_down" if facing == Vector2i.DOWN else &"mine_right"
	if facing.x != 0:
		_sprite.flip_h = facing.x < 0
	_sprite.play(anim, _animation_length(anim) / dig_time)


func _animation_length(anim: StringName) -> float:
	var frames := _sprite.sprite_frames
	var total := 0.0
	for i in frames.get_frame_count(anim):
		total += frames.get_frame_duration(anim, i)
	return total / frames.get_animation_speed(anim)

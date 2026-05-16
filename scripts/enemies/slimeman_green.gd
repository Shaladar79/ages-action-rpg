extends CharacterBody2D

@export var move_speed: float = 45.0
@export var wander_time_min: float = 1.0
@export var wander_time_max: float = 2.5
@export var idle_time_min: float = 0.6
@export var idle_time_max: float = 1.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var move_direction: Vector2 = Vector2.ZERO
var last_direction: String = "down"
var state: String = "idle"
var state_timer: float = 0.0


func _ready() -> void:
    randomize()
    _enter_idle_state()


func _physics_process(delta: float) -> void:
    state_timer -= delta

    if state_timer <= 0.0:
        if state == "idle":
            _enter_wander_state()
        else:
            _enter_idle_state()

    if state == "wander":
        velocity = move_direction * move_speed
    else:
        velocity = Vector2.ZERO

    move_and_slide()
    _update_animation()


func _enter_idle_state() -> void:
    state = "idle"
    move_direction = Vector2.ZERO
    state_timer = randf_range(idle_time_min, idle_time_max)


func _enter_wander_state() -> void:
    state = "wander"

    var possible_directions: Array[Vector2] = [
        Vector2.UP,
        Vector2.DOWN,
        Vector2.LEFT,
        Vector2.RIGHT
    ]

    move_direction = possible_directions.pick_random()
    state_timer = randf_range(wander_time_min, wander_time_max)

    _update_last_direction(move_direction)


func _update_last_direction(direction: Vector2) -> void:
    if direction == Vector2.ZERO:
        return

    if abs(direction.x) > abs(direction.y):
        if direction.x > 0:
            last_direction = "right"
        else:
            last_direction = "left"
    else:
        if direction.y > 0:
            last_direction = "down"
        else:
            last_direction = "up"


func _update_animation() -> void:
    if velocity == Vector2.ZERO:
        animated_sprite.play("idle_" + last_direction)
    else:
        animated_sprite.play("walk_" + last_direction)

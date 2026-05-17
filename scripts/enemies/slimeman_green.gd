extends CharacterBody2D

@export var max_health: int = 3
@export var move_speed: float = 45.0
@export var wander_time_min: float = 1.0
@export var wander_time_max: float = 2.5
@export var idle_time_min: float = 0.6
@export var idle_time_max: float = 1.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_collision: CollisionShape2D = $Hurtbox/CollisionShape2D

var current_health: int = 0
var move_direction: Vector2 = Vector2.ZERO
var last_direction: String = "down"
var state: String = "idle"
var state_timer: float = 0.0
var is_dead: bool = false


func _ready() -> void:
    randomize()
    current_health = max_health

    _validate_enemy_setup()

    print("SlimemanGreen ready. HP: ", current_health, "/", max_health)

    _enter_idle_state()


func _physics_process(delta: float) -> void:
    if is_dead:
        return

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


func take_damage(amount: int) -> void:
    if is_dead:
        return

    current_health -= amount
    print(name, " took ", amount, " damage. HP: ", current_health, "/", max_health)

    if current_health <= 0:
        _die()


func _die() -> void:
    is_dead = true
    velocity = Vector2.ZERO
    print(name, " defeated.")
    queue_free()


func _validate_enemy_setup() -> void:
    if animated_sprite == null:
        push_warning("SlimemanGreen is missing AnimatedSprite2D.")

    if hurtbox == null:
        push_warning("SlimemanGreen is missing Hurtbox. Hurtbox must be a direct child of SlimemanGreen.")
        return

    if hurtbox_collision == null:
        push_warning("SlimemanGreen Hurtbox is missing CollisionShape2D.")
        return

    hurtbox.monitoring = true
    hurtbox.monitorable = true
    hurtbox_collision.disabled = false

    print("SlimemanGreen Hurtbox ready. Monitoring: ", hurtbox.monitoring, " Monitorable: ", hurtbox.monitorable)


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
    if animated_sprite == null:
        return

    if velocity == Vector2.ZERO:
        animated_sprite.play("idle_" + last_direction)
    else:
        animated_sprite.play("walk_" + last_direction)

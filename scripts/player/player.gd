extends CharacterBody2D

@export var move_speed: float = 120.0
@export var attack_duration: float = 0.15
@export var attack_cooldown: float = 0.35
@export var attack_offset: float = 24.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D

var last_direction: String = "down"
var is_attacking: bool = false
var attack_timer: float = 0.0
var cooldown_timer: float = 0.0


func _ready() -> void:
    _disable_attack_hitbox()


func _physics_process(delta: float) -> void:
    _update_attack_timers(delta)

    var input_vector := Vector2.ZERO

    input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

    if input_vector.length() > 1.0:
        input_vector = input_vector.normalized()

    velocity = input_vector * move_speed
    move_and_slide()

    if Input.is_action_just_pressed("attack"):
        _try_attack()

    _update_animation(input_vector)


func _try_attack() -> void:
    if is_attacking:
        return

    if cooldown_timer > 0.0:
        return

    is_attacking = true
    attack_timer = attack_duration
    cooldown_timer = attack_cooldown

    _position_attack_area()
    _enable_attack_hitbox()

    print("Player attack: ", last_direction)


func _update_attack_timers(delta: float) -> void:
    if cooldown_timer > 0.0:
        cooldown_timer -= delta

    if not is_attacking:
        return

    attack_timer -= delta

    if attack_timer <= 0.0:
        is_attacking = false
        _disable_attack_hitbox()


func _position_attack_area() -> void:
    match last_direction:
        "down":
            attack_area.position = Vector2(0, attack_offset)
        "up":
            attack_area.position = Vector2(0, -attack_offset)
        "left":
            attack_area.position = Vector2(-attack_offset, 0)
        "right":
            attack_area.position = Vector2(attack_offset, 0)


func _enable_attack_hitbox() -> void:
    attack_area.monitoring = true
    attack_area.monitorable = true
    attack_collision.disabled = false
    attack_area.visible = true


func _disable_attack_hitbox() -> void:
    attack_area.monitoring = false
    attack_area.monitorable = false
    attack_collision.disabled = true
    attack_area.visible = false


func _update_animation(input_vector: Vector2) -> void:
    if input_vector == Vector2.ZERO:
        animated_sprite.play("idle_" + last_direction)
        return

    if abs(input_vector.x) > abs(input_vector.y):
        if input_vector.x > 0:
            last_direction = "right"
        else:
            last_direction = "left"
    else:
        if input_vector.y > 0:
            last_direction = "down"
        else:
            last_direction = "up"

    animated_sprite.play("walk_" + last_direction)

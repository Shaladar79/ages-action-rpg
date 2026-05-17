extends CharacterBody2D

@export var move_speed: float = 120.0
@export var attack_duration: float = 0.5
@export var attack_cooldown: float = 0.35
@export var attack_offset: float = 24.0
@export var attack_damage: int = 1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var dialogue_bubble: Node2D = $DialogueBubble

var last_direction: String = "down"
var is_attacking: bool = false
var attack_timer: float = 0.0
var cooldown_timer: float = 0.0
var hit_targets: Array[Node] = []

var nearby_interactable: Node = null


func _ready() -> void:
    _disable_attack_hitbox()

    if not attack_area.area_entered.is_connected(_on_attack_area_entered):
        attack_area.area_entered.connect(_on_attack_area_entered)


func _physics_process(delta: float) -> void:
    _update_attack_timers(delta)

    if Input.is_action_just_pressed("ui_accept"):
        if is_dialogue_active():
            hide_dialogue()
            _notify_nearby_interactable_dialogue_closed()
            return

    var input_vector := Vector2.ZERO

    input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

    if input_vector.length() > 1.0:
        input_vector = input_vector.normalized()

    velocity = input_vector * move_speed
    move_and_slide()

    if Input.is_action_just_pressed("interact"):
        _try_interact()

    if Input.is_action_just_pressed("attack"):
        _try_attack()

    if is_attacking:
        _check_attack_overlaps()

    _update_animation(input_vector)


func show_dialogue(message: String) -> void:
    if dialogue_bubble == null:
        return

    if dialogue_bubble.has_method("show_dialogue"):
        dialogue_bubble.show_dialogue(message)


func hide_dialogue() -> void:
    if dialogue_bubble == null:
        return

    if dialogue_bubble.has_method("hide_dialogue"):
        dialogue_bubble.hide_dialogue()


func is_dialogue_active() -> bool:
    if dialogue_bubble == null:
        return false

    if dialogue_bubble.has_method("is_dialogue_active"):
        return dialogue_bubble.is_dialogue_active()

    return false


func _notify_nearby_interactable_dialogue_closed() -> void:
    if nearby_interactable == null:
        return

    if nearby_interactable.has_method("on_player_dialogue_closed"):
        nearby_interactable.on_player_dialogue_closed(self)


func set_nearby_interactable(interactable: Node) -> void:
    nearby_interactable = interactable
    print("Nearby interactable: ", interactable.name)
    _show_interaction_prompt()


func clear_nearby_interactable(interactable: Node) -> void:
    if nearby_interactable != interactable:
        return

    print("Cleared interactable: ", interactable.name)
    nearby_interactable = null
    _hide_interaction_prompt()


func _show_interaction_prompt() -> void:
    var interaction_ui := get_tree().get_first_node_in_group("interaction_ui")

    if interaction_ui == null:
        push_warning("No node found in group: interaction_ui")
        return

    if interaction_ui.has_method("show_prompt"):
        interaction_ui.show_prompt("E")


func _hide_interaction_prompt() -> void:
    var interaction_ui := get_tree().get_first_node_in_group("interaction_ui")

    if interaction_ui == null:
        return

    if interaction_ui.has_method("hide_prompt"):
        interaction_ui.hide_prompt()


func _try_interact() -> void:
    if is_dialogue_active():
        return

    if nearby_interactable == null:
        print("No nearby interactable.")
        return

    if nearby_interactable.has_method("interact"):
        nearby_interactable.interact(self)


func _try_attack() -> void:
    if is_dialogue_active():
        return

    if is_attacking:
        return

    if cooldown_timer > 0.0:
        return

    is_attacking = true
    attack_timer = attack_duration
    cooldown_timer = attack_cooldown
    hit_targets.clear()

    _position_attack_area()
    _enable_attack_hitbox()

    print("Player attack: ", last_direction)
    print("AttackArea position: ", attack_area.position)


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


func _on_attack_area_entered(area: Area2D) -> void:
    print("AttackArea entered area: ", area.name)
    _damage_area_target(area)


func _check_attack_overlaps() -> void:
    var overlapping_areas := attack_area.get_overlapping_areas()

    for area in overlapping_areas:
        print("AttackArea overlapping: ", area.name)
        _damage_area_target(area)


func _damage_area_target(area: Area2D) -> void:
    if not is_attacking:
        return

    var target := area.get_parent()

    if target == null:
        return

    if hit_targets.has(target):
        return

    if target.has_method("take_damage"):
        hit_targets.append(target)
        target.take_damage(attack_damage)
        print("Hit target: ", target.name)


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

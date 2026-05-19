extends CharacterBody2D
class_name Monster

@export var monster_name: String = "Monster"
@export var max_hit_points: int = 3
@export var attack: int = 1
@export var defense: int = 0
@export var xp_reward: int = 1

@export var attack_cooldown: float = 1.25
@export var can_attack_player: bool = true

@export var destroy_on_death: bool = true
@export var hide_sprite_on_death: bool = true
@export var disable_collision_on_death: bool = true

@onready var sprite_2d: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var animated_sprite_2d: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var attack_area: Area2D = get_node_or_null("AttackArea") as Area2D

var current_hit_points: int = 0
var is_dead: bool = false

var attack_timer: float = 0.0
var player_in_attack_range: Node2D = null


func _ready() -> void:
    current_hit_points = max_hit_points
    _start_default_animation()
    _connect_attack_area()


func _physics_process(delta: float) -> void:
    if is_dead:
        return

    _update_attack_timer(delta)

    if can_attack_player:
        _try_attack_player()


func _start_default_animation() -> void:
    if animated_sprite_2d == null:
        return

    if animated_sprite_2d.sprite_frames == null:
        return

    if animated_sprite_2d.sprite_frames.has_animation("idle_down"):
        animated_sprite_2d.play("idle_down")
        return

    if animated_sprite_2d.sprite_frames.has_animation("walk_down"):
        animated_sprite_2d.play("walk_down")
        return


func _connect_attack_area() -> void:
    if attack_area == null:
        return

    if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
        attack_area.body_entered.connect(_on_attack_area_body_entered)

    if not attack_area.body_exited.is_connected(_on_attack_area_body_exited):
        attack_area.body_exited.connect(_on_attack_area_body_exited)


func _update_attack_timer(delta: float) -> void:
    if attack_timer > 0.0:
        attack_timer -= delta


func _try_attack_player() -> void:
    if player_in_attack_range == null:
        return

    if attack_timer > 0.0:
        return

    if not player_in_attack_range.has_method("take_damage"):
        return

    player_in_attack_range.take_damage(attack)
    attack_timer = attack_cooldown

    print(monster_name, " attacked player for base damage: ", attack)


func _on_attack_area_body_entered(body: Node2D) -> void:
    if body == null:
        return

    if not body.is_in_group("player"):
        return

    player_in_attack_range = body
    print(monster_name, " has player in attack range.")


func _on_attack_area_body_exited(body: Node2D) -> void:
    if body != player_in_attack_range:
        return

    player_in_attack_range = null
    print(monster_name, " lost player attack range.")


func take_damage_from_player(damage_amount: int, player: Node2D) -> void:
    if is_dead:
        return

    var final_damage: int = maxi(1, damage_amount - defense)

    current_hit_points -= final_damage

    print(monster_name, " took damage: ", final_damage)
    print(monster_name, " HP: ", current_hit_points, " / ", max_hit_points)

    if current_hit_points <= 0:
        die(player)


func take_damage(damage_amount: int) -> void:
    if is_dead:
        return

    var final_damage: int = maxi(1, damage_amount - defense)

    current_hit_points -= final_damage

    print(monster_name, " took damage: ", final_damage)
    print(monster_name, " HP: ", current_hit_points, " / ", max_hit_points)

    if current_hit_points <= 0:
        die(null)


func die(player: Node2D = null) -> void:
    if is_dead:
        return

    is_dead = true

    print(monster_name, " defeated. XP reward: ", xp_reward)

    if player != null and player.has_method("gain_xp"):
        player.gain_xp(xp_reward)

    if disable_collision_on_death:
        _disable_all_collision_shapes(self)
        collision_layer = 0
        collision_mask = 0

    if hide_sprite_on_death:
        if sprite_2d != null:
            sprite_2d.visible = false

        if animated_sprite_2d != null:
            animated_sprite_2d.visible = false

    if destroy_on_death:
        queue_free()


func _disable_all_collision_shapes(node: Node) -> void:
    for child in node.get_children():
        if child is CollisionShape2D:
            child.set_deferred("disabled", true)

        if child is CollisionPolygon2D:
            child.set_deferred("disabled", true)

        if child is Area2D:
            child.set_deferred("monitoring", false)
            child.set_deferred("monitorable", false)
            child.set_deferred("collision_layer", 0)
            child.set_deferred("collision_mask", 0)

        if child is PhysicsBody2D:
            child.set_deferred("collision_layer", 0)
            child.set_deferred("collision_mask", 0)

        _disable_all_collision_shapes(child)

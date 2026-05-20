extends CharacterBody2D

@export var base_move_speed: float = 120.0
@export var move_speed_per_speed_point: float = 4.0

@export var attack_duration: float = 0.5
@export var base_attack_cooldown: float = 0.35
@export var attack_speed_bonus_per_agility: float = 0.01
@export var attack_offset: float = 24.0

@export var respawn_delay: float = 1.5

@export var weapon_visual_offset: float = 22.0
@export var weapon_visual_scale: Vector2 = Vector2(1.0, 1.0)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var dialogue_bubble: Node2D = $DialogueBubble
@onready var weapon_sprite: Sprite2D = get_node_or_null("WeaponSprite") as Sprite2D

var character_stats: CharacterStats = CharacterStats.new()

var last_direction: String = "down"
var is_attacking: bool = false
var is_defeated: bool = false
var is_respawning: bool = false
var attack_timer: float = 0.0
var cooldown_timer: float = 0.0
var hit_targets: Array[Node] = []

var nearby_interactable: Node = null

var inventory: Array[Dictionary] = []


func _ready() -> void:
    _disable_attack_hitbox()
    _hide_weapon_sprite()

    if not attack_area.area_entered.is_connected(_on_attack_area_entered):
        attack_area.area_entered.connect(_on_attack_area_entered)

    call_deferred("_apply_startup_position_if_needed")


func _apply_startup_position_if_needed() -> void:
    if not SaveManager.pending_loaded_data.is_empty():
        print("Applying pending save data to player.")
        SaveManager.apply_pending_loaded_data(self)
        return

    if SceneTransitionManager.has_pending_player_data():
        SceneTransitionManager.apply_player_data(self)

    if SceneTransitionManager.has_pending_spawn():
        var spawn_id: String = SceneTransitionManager.consume_pending_spawn()
        _move_to_map_spawn(spawn_id)
        return

    print("No pending save data or map spawn to apply.")

func _move_to_map_spawn(spawn_id: String) -> void:
    if spawn_id.strip_edges() == "":
        return

    var current_scene := get_tree().current_scene

    if current_scene == null:
        push_warning("Cannot move player to map spawn. Current scene is null.")
        return

    var spawn_point := _find_map_spawn_point(current_scene, spawn_id)

    if spawn_point == null:
        push_warning("No MapSpawnPoint found with spawn_id: " + spawn_id)
        return

    global_position = spawn_point.global_position
    velocity = Vector2.ZERO

    print("Player moved to map spawn: ", spawn_id, " at ", global_position)


func _find_map_spawn_point(node: Node, spawn_id: String) -> Node2D:
    if node == null:
        return null

    if node is MapSpawnPoint:
        var map_spawn := node as MapSpawnPoint

        if map_spawn.spawn_id == spawn_id:
            return map_spawn

    for child in node.get_children():
        var found := _find_map_spawn_point(child, spawn_id)

        if found != null:
            return found

    return null

func _apply_pending_save_if_needed() -> void:
    if SaveManager.pending_loaded_data.is_empty():
        print("No pending save data to apply.")
        return

    print("Applying pending save data to player.")
    SaveManager.apply_pending_loaded_data(self)

func _physics_process(delta: float) -> void:
    _update_attack_timers(delta)

    if Input.is_action_just_pressed("dialogue_continue"):
        if is_dialogue_active():
            hide_dialogue()
            _notify_nearby_interactable_dialogue_closed()
            return

    if is_defeated:
        velocity = Vector2.ZERO
        move_and_slide()
        return

    var input_vector := Vector2.ZERO

    input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

    if input_vector.length() > 1.0:
        input_vector = input_vector.normalized()

    velocity = input_vector * get_current_move_speed()
    move_and_slide()

    if Input.is_action_just_pressed("interact"):
        _try_interact()

    if Input.is_action_just_pressed("attack"):
        _try_attack()

    if is_attacking:
        _check_attack_overlaps()

    _update_animation(input_vector)


func get_character_stats() -> CharacterStats:
    return character_stats


func get_current_move_speed() -> float:
    return character_stats.get_move_speed(base_move_speed, move_speed_per_speed_point)


func get_current_attack_cooldown() -> float:
    return character_stats.get_attack_cooldown(base_attack_cooldown, attack_speed_bonus_per_agility)


func gain_xp(amount: int) -> bool:
    if is_defeated:
        return false

    var leveled_up := character_stats.add_xp(amount)

    _notify_ui_stats_changed()

    if leveled_up:
        show_dialogue("You gained a level. Open your character sheet and spend your character point.")

    return leveled_up


func spend_stat_point(stat_id: String) -> bool:
    if is_defeated:
        return false

    var spent := character_stats.spend_stat_point(stat_id)

    if spent:
        _notify_ui_stats_changed()

    return spent


func _notify_ui_stats_changed() -> void:
    var game_ui := get_tree().get_first_node_in_group("interaction_ui")

    if game_ui != null and game_ui.has_method("refresh_character_display"):
        game_ui.refresh_character_display()
        return

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null and autoload_ui.has_method("refresh_character_display"):
        autoload_ui.refresh_character_display()


func add_inventory_item(item_id: String, item_name: String) -> void:
    if is_defeated:
        return

    if has_inventory_item(item_id):
        print("Inventory already has item: ", item_name)
        return

    inventory.append({
        "id": item_id,
        "name": item_name
    })

    print("Added to inventory: ", item_name)
    _notify_ui_stats_changed()


func has_inventory_item(item_id: String) -> bool:
    for item in inventory:
        if item.get("id", "") == item_id:
            return true

    return false


func get_inventory_item_name(item_id: String) -> String:
    for item in inventory:
        if item.get("id", "") == item_id:
            return item.get("name", item_id)

    return item_id


func equip_weapon(item_id: String) -> void:
    if is_defeated:
        return

    if not has_inventory_item(item_id):
        push_warning("Cannot equip weapon. Item not found in inventory: " + item_id)
        return

    var item_name := get_inventory_item_name(item_id)
    character_stats.equip_weapon(item_id, item_name)

    print("Equipped weapon: ", character_stats.get_equipped_weapon_name())
    _notify_ui_stats_changed()


func unequip_weapon() -> void:
    character_stats.unequip_weapon()
    _hide_weapon_sprite()
    print("Weapon unequipped.")
    _notify_ui_stats_changed()


func has_equipped_weapon() -> bool:
    return character_stats.equipped_weapon_id != ""


func get_equipped_weapon_name() -> String:
    return character_stats.get_equipped_weapon_name()


func get_equipped_armor_name() -> String:
    return character_stats.get_equipped_armor_name()


func get_equipped_accessory_name() -> String:
    return character_stats.get_equipped_accessory_name()


func get_attack_damage() -> int:
    return character_stats.get_attack()


func get_defense() -> int:
    return character_stats.get_defense()


func get_inventory_items() -> Array[Dictionary]:
    return inventory

func set_inventory_items(saved_inventory: Array) -> void:
    inventory.clear()

    for item in saved_inventory:
        if typeof(item) != TYPE_DICTIONARY:
            continue

        var item_id: String = str(item.get("id", ""))
        var item_name: String = str(item.get("name", item_id))

        if item_id.strip_edges() == "":
            continue

        inventory.append({
            "id": item_id,
            "name": item_name
        })

    print("Inventory loaded. Item count: ", inventory.size())
    _notify_ui_stats_changed()

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
    if is_defeated:
        return

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
    if is_defeated:
        return

    if is_dialogue_active():
        return

    if nearby_interactable == null:
        print("No nearby interactable.")
        return

    if nearby_interactable.has_method("interact"):
        nearby_interactable.interact(self)


func _try_attack() -> void:
    if is_defeated:
        return

    if is_dialogue_active():
        return

    if is_attacking:
        return

    if cooldown_timer > 0.0:
        return

    is_attacking = true
    attack_timer = attack_duration
    cooldown_timer = get_current_attack_cooldown()
    hit_targets.clear()

    _position_attack_area()
    _show_weapon_sprite_for_attack()
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
        _hide_weapon_sprite()


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


func _show_weapon_sprite_for_attack() -> void:
    if weapon_sprite == null:
        return

    if not has_equipped_weapon():
        _hide_weapon_sprite()
        return

    weapon_sprite.visible = true
    weapon_sprite.scale = weapon_visual_scale
    weapon_sprite.flip_h = false
    weapon_sprite.flip_v = false

    match last_direction:
        "down":
            weapon_sprite.position = Vector2(0, weapon_visual_offset)
            weapon_sprite.rotation_degrees = 180.0
            weapon_sprite.z_index = 10
        "up":
            weapon_sprite.position = Vector2(0, -weapon_visual_offset)
            weapon_sprite.rotation_degrees = 0.0
            weapon_sprite.z_index = -1
        "left":
            weapon_sprite.position = Vector2(-weapon_visual_offset, 0)
            weapon_sprite.rotation_degrees = -90.0
            weapon_sprite.z_index = 10
        "right":
            weapon_sprite.position = Vector2(weapon_visual_offset, 0)
            weapon_sprite.rotation_degrees = 90.0
            weapon_sprite.z_index = 10


func _hide_weapon_sprite() -> void:
    if weapon_sprite == null:
        return

    weapon_sprite.visible = false


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
    if is_defeated:
        return

    if not is_attacking:
        return

    var target := area.get_parent()

    if target == null:
        return

    if hit_targets.has(target):
        return

    if target.has_method("take_damage_from_player"):
        hit_targets.append(target)
        target.take_damage_from_player(get_attack_damage(), self)
        print("Hit target with player-aware damage: ", target.name)
        return

    if target.has_method("take_damage"):
        hit_targets.append(target)
        target.take_damage(get_attack_damage())
        print("Hit target: ", target.name)


func _update_animation(input_vector: Vector2) -> void:
    if is_defeated:
        return

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


func take_damage(incoming_damage: int) -> void:
    if is_defeated:
        return

    if incoming_damage <= 0:
        return

    var final_damage: int = maxi(1, incoming_damage - get_defense())

    character_stats.current_health -= final_damage
    character_stats.current_health = maxi(character_stats.current_health, 0)

    print("Player took damage: ", final_damage)
    print("Player HP: ", character_stats.current_health, " / ", character_stats.max_health)

    _notify_ui_stats_changed()

    if character_stats.current_health <= 0:
        _on_player_defeated()


func _on_player_defeated() -> void:
    if is_defeated:
        return

    is_defeated = true
    is_respawning = false
    is_attacking = false
    velocity = Vector2.ZERO

    _disable_attack_hitbox()
    _hide_weapon_sprite()
    _hide_interaction_prompt()

    if animated_sprite != null:
        animated_sprite.visible = false

    print("Player defeated.")
    show_dialogue("You have been defeated.")
    _notify_ui_stats_changed()

    _try_start_respawn()


func _try_start_respawn() -> void:
    if is_respawning:
        return

    if not RespawnManager.can_respawn():
        print("No active respawn point. Player remains defeated.")
        return

    is_respawning = true
    print("Respawning player in ", respawn_delay, " seconds.")

    await get_tree().create_timer(respawn_delay).timeout

    _respawn_player()


func _respawn_player() -> void:
    if not RespawnManager.can_respawn():
        is_respawning = false
        return

    global_position = RespawnManager.get_respawn_position()
    velocity = Vector2.ZERO

    character_stats.current_health = character_stats.max_health

    is_defeated = false
    is_respawning = false
    is_attacking = false
    attack_timer = 0.0
    cooldown_timer = 0.0
    hit_targets.clear()

    _disable_attack_hitbox()
    _hide_weapon_sprite()

    if animated_sprite != null:
        animated_sprite.visible = true
        animated_sprite.play("idle_" + last_direction)

    show_dialogue("You return to the totem.")
    _notify_ui_stats_changed()

    print("Player respawned at: ", global_position)

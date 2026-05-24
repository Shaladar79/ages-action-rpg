extends CharacterBody2D
class_name Monster

signal monster_defeated(monster: Monster, player: Node2D)

enum RespawnMode {
    USE_MAP_DEFAULT,
    ALWAYS_RESPAWN,
    NEVER_RESPAWN
}

enum AttackStyle {
    MELEE_ONLY,
    RANGED_ONLY,
    MIXED
}

@export var persistent_id: String = ""
@export var respawn_mode: RespawnMode = RespawnMode.USE_MAP_DEFAULT

@export var monster_name: String = "Monster"
@export var monster_level: int = 0
@export var max_hit_points: int = 3

# Kept for backward compatibility. New monsters should mainly use Melee Damage / Ranged Damage.
@export var attack: int = 1

@export var defense: int = 0
@export var xp_reward: int = 1
@export var xp_level_cutoff_below_player: int = 5

@export_group("Drops")
@export var drop_item_1_id: String = ""
@export_range(0.0, 100.0, 0.1) var drop_item_1_chance_percent: float = 0.0

@export var drop_item_2_id: String = ""
@export_range(0.0, 100.0, 0.1) var drop_item_2_chance_percent: float = 0.0

@export var drop_currency_id: String = "shines"
@export_range(0.0, 100.0, 0.1) var drop_currency_chance_percent: float = 0.0
@export var drop_currency_min_amount: int = 1
@export var drop_currency_max_amount: int = 1

@export_flags(
    "Bashing",
    "Slashing",
    "Chopping",
    "Piercing",
    "Fire",
    "Ice",
    "Lightning",
    "Acid",
    "Light",
    "Shadow"
)
var weakness_types: int = DamageTypes.NONE

# Kept for backward compatibility. New monsters should mainly use Melee Damage Types / Ranged Damage Types.
@export_flags(
    "Bashing",
    "Slashing",
    "Chopping",
    "Piercing",
    "Fire",
    "Ice",
    "Lightning",
    "Acid",
    "Light",
    "Shadow"
)
var damage_types: int = DamageTypes.BASHING

@export var weakness_damage_multiplier: float = 1.5

@export_group("Movement")
@export var move_speed: float = 45.0
@export var detection_range: float = 140.0
@export var stop_distance: float = 22.0
@export var wander_enabled: bool = true
@export var wander_radius: float = 64.0
@export var wander_interval: float = 2.0

@export_group("Attack Style")
@export var attack_style: AttackStyle = AttackStyle.MELEE_ONLY
@export var can_attack_player: bool = true

@export_group("Melee Attack")
@export var melee_damage: int = 1
@export_flags(
    "Bashing",
    "Slashing",
    "Chopping",
    "Piercing",
    "Fire",
    "Ice",
    "Lightning",
    "Acid",
    "Light",
    "Shadow"
)
var melee_damage_types: int = DamageTypes.BASHING
@export var melee_cooldown: float = 1.25

@export_group("Ranged Attack")
@export var ranged_damage: int = 1
@export_flags(
    "Bashing",
    "Slashing",
    "Chopping",
    "Piercing",
    "Fire",
    "Ice",
    "Lightning",
    "Acid",
    "Light",
    "Shadow"
)
var ranged_damage_types: int = DamageTypes.PIERCING
@export var ranged_range: float = 180.0
@export var ranged_cooldown: float = 1.75
@export var ranged_stop_distance: float = 96.0
@export var ranged_attack_icon_texture: Texture2D = null
@export var ranged_attack_icon_scale: Vector2 = Vector2(1.0, 1.0)
@export var ranged_attack_icon_speed: float = 260.0
@export var ranged_attack_icon_lifetime: float = 0.8
@export var ranged_attack_icon_z_index: int = 20

@export_group("Death")
@export var destroy_on_death: bool = true
@export var hide_sprite_on_death: bool = true
@export var disable_collision_on_death: bool = true

@export_group("Combat Flash")
@export var flash_on_attack: bool = true
@export var attack_flash_color: Color = Color(2.5, 2.5, 2.5, 1.0)
@export var attack_flash_duration: float = 0.12

@export var flash_on_damage: bool = true
@export var damage_flash_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var damage_flash_duration: float = 0.12

@export_group("Boss Identity")
@export var boss_defeated_flag: String = ""

@export_group("Special Attacks")
@export var special_attacks_enabled: bool = false
@export var special_global_cooldown: float = 1.0

# Master movement lock switch.
# If this is Off, no special attack locks movement.
# If this is On, each special attack uses its own movement-lock setting.
@export var lock_movement_during_special: bool = true

@export var telegraph_polygon_sides: int = 48
@export var telegraph_z_index: int = 200
@export var telegraph_impact_flash_time: float = 0.12
@export var telegraph_impact_flash_color: Color = Color(1.0, 0.0, 0.0, 0.85)

@export_group("AOE Special")
@export var aoe_enabled: bool = false
@export var aoe_lock_movement: bool = true
@export var aoe_damage: int = 1
@export_flags(
    "Bashing",
    "Slashing",
    "Chopping",
    "Piercing",
    "Fire",
    "Ice",
    "Lightning",
    "Acid",
    "Light",
    "Shadow"
)
var aoe_damage_types: int = DamageTypes.FIRE
@export var aoe_radius: float = 72.0
@export var aoe_trigger_range: float = 160.0
@export var aoe_windup_time: float = 1.25
@export var aoe_cooldown: float = 8.0
@export var aoe_telegraph_color: Color = Color(1.0, 0.25, 0.05, 0.35)

@export_group("Slam Special")
@export var slam_enabled: bool = false
@export var slam_lock_movement: bool = true
@export var slam_damage: int = 5
@export_flags(
    "Bashing",
    "Slashing",
    "Chopping",
    "Piercing",
    "Fire",
    "Ice",
    "Lightning",
    "Acid",
    "Light",
    "Shadow"
)
var slam_damage_types: int = DamageTypes.BASHING
@export var slam_length: float = 82.0
@export var slam_width: float = 36.0
@export var slam_trigger_range: float = 72.0
@export var slam_windup_time: float = 0.8
@export var slam_cooldown: float = 3.5
@export var slam_telegraph_color: Color = Color(1.0, 0.0, 0.0, 0.45)

@export_group("Burst Special")
@export var burst_enabled: bool = false
@export var burst_lock_movement: bool = false
@export var burst_damage: int = 1
@export_flags(
    "Bashing",
    "Slashing",
    "Chopping",
    "Piercing",
    "Fire",
    "Ice",
    "Lightning",
    "Acid",
    "Light",
    "Shadow"
)
var burst_damage_types: int = DamageTypes.PIERCING
@export var burst_trigger_range: float = 260.0
@export var burst_cooldown: float = 5.0
@export var burst_followup_delay: float = 2.0
@export var burst_projectile_range: float = 260.0
@export var burst_projectile_speed: float = 240.0
@export var burst_projectile_hit_radius: float = 10.0
@export var burst_projectile_spawn_offset: float = 16.0
@export var burst_projectile_texture: Texture2D = null
@export var burst_projectile_scale: Vector2 = Vector2(1.0, 1.0)
@export var burst_projectile_color: Color = Color(1.0, 0.85, 0.25, 1.0)
@export var burst_projectile_z_index: int = 220
@export var burst_projectile_collision_layer: int = 0
@export var burst_projectile_collision_mask: int = 1

@onready var sprite_2d: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var animated_sprite_2d: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var attack_area: Area2D = get_node_or_null("AttackArea") as Area2D

var current_hit_points: int = 0
var is_dead: bool = false

var melee_attack_timer: float = 0.0
var ranged_attack_timer: float = 0.0

var player_in_attack_range: Node2D = null
var player_target: Node2D = null

var spawn_position: Vector2 = Vector2.ZERO
var wander_target: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0

var last_direction: String = "down"
var special_attacks: MonsterSpecialAttacks = null

var flash_tween: Tween = null


func _ready() -> void:
    if _should_remove_because_defeated_in_save():
        queue_free()
        return

    current_hit_points = max_hit_points
    spawn_position = global_position
    wander_target = spawn_position

    _apply_legacy_attack_defaults()

    player_target = get_tree().get_first_node_in_group("player") as Node2D

    _ensure_special_attack_controller()
    _start_default_animation()
    _connect_attack_area()


func _physics_process(delta: float) -> void:
    if is_dead:
        return

    _update_attack_timers(delta)

    if special_attacks != null:
        special_attacks.update_special_timers(delta)

        if special_attacks.is_busy():
            if special_attacks.is_locking_movement():
                velocity = Vector2.ZERO
                move_and_slide()
                _update_animation_from_velocity(Vector2.ZERO)
                return

            _update_movement(delta)
            return

        if special_attacks.try_start_special_attack():
            return

    _update_movement(delta)

    if can_attack_player:
        _try_attack_player()


func _ensure_special_attack_controller() -> void:
    if special_attacks != null:
        return

    special_attacks = MonsterSpecialAttacks.new()
    special_attacks.name = "MonsterSpecialAttacks"
    add_child(special_attacks)
    special_attacks.setup(self)


func _apply_legacy_attack_defaults() -> void:
    if melee_damage <= 0:
        melee_damage = attack

    if damage_types != DamageTypes.NONE:
        melee_damage_types = damage_types


func _should_remove_because_defeated_in_save() -> bool:
    if persistent_id.strip_edges() == "":
        return false

    if not SaveManager.is_monster_defeated(persistent_id):
        return false

    print(monster_name, " removed because persistent monster is already defeated: ", persistent_id)
    return true


func _update_movement(delta: float) -> void:
    if player_target == null:
        player_target = get_tree().get_first_node_in_group("player") as Node2D

    var desired_velocity := Vector2.ZERO

    if _should_chase_player():
        desired_velocity = _get_chase_velocity()
    elif wander_enabled:
        desired_velocity = _get_wander_velocity(delta)

    velocity = desired_velocity
    move_and_slide()

    _update_animation_from_velocity(velocity)


func _should_chase_player() -> bool:
    if player_target == null:
        return false

    var distance_to_player := global_position.distance_to(player_target.global_position)
    return distance_to_player <= detection_range


func _get_chase_velocity() -> Vector2:
    if player_target == null:
        return Vector2.ZERO

    var distance_to_player := global_position.distance_to(player_target.global_position)
    var desired_stop_distance := _get_desired_stop_distance()

    if distance_to_player <= desired_stop_distance:
        return Vector2.ZERO

    var direction := global_position.direction_to(player_target.global_position)
    return direction * move_speed


func _get_desired_stop_distance() -> float:
    match attack_style:
        AttackStyle.RANGED_ONLY:
            return ranged_stop_distance

        AttackStyle.MIXED:
            if _is_player_in_ranged_range() and not _is_player_in_melee_range():
                return ranged_stop_distance

    return stop_distance


func _get_wander_velocity(delta: float) -> Vector2:
    wander_timer -= delta

    if wander_timer <= 0.0 or global_position.distance_to(wander_target) <= 6.0:
        _choose_new_wander_target()

    var direction_to_wander := global_position.direction_to(wander_target)

    if global_position.distance_to(wander_target) <= 6.0:
        return Vector2.ZERO

    return direction_to_wander * (move_speed * 0.5)


func _choose_new_wander_target() -> void:
    wander_timer = wander_interval

    var random_direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
    var random_distance := randf_range(8.0, wander_radius)

    wander_target = spawn_position + (random_direction * random_distance)


func _update_attack_timers(delta: float) -> void:
    if melee_attack_timer > 0.0:
        melee_attack_timer -= delta

    if ranged_attack_timer > 0.0:
        ranged_attack_timer -= delta


func _try_attack_player() -> void:
    match attack_style:
        AttackStyle.MELEE_ONLY:
            _try_melee_attack_player()

        AttackStyle.RANGED_ONLY:
            _try_ranged_attack_player()

        AttackStyle.MIXED:
            if _is_player_in_melee_range():
                _try_melee_attack_player()
            else:
                _try_ranged_attack_player()


func _try_melee_attack_player() -> void:
    if player_in_attack_range == null:
        return

    if melee_attack_timer > 0.0:
        return

    _flash_attack()
    _damage_player(player_in_attack_range, melee_damage, melee_damage_types)

    melee_attack_timer = melee_cooldown
    print(monster_name, " used melee attack for base damage: ", melee_damage)


func _try_ranged_attack_player() -> void:
    if player_target == null:
        return

    if ranged_attack_timer > 0.0:
        return

    if not _is_player_in_ranged_range():
        return

    _flash_attack()
    _show_ranged_attack_icon(player_target)
    _damage_player(player_target, ranged_damage, ranged_damage_types)

    ranged_attack_timer = ranged_cooldown
    print(monster_name, " used ranged attack for base damage: ", ranged_damage)


func _show_ranged_attack_icon(target: Node2D) -> void:
    if target == null:
        return

    if ranged_attack_icon_texture == null:
        _show_default_ranged_attack_icon(target)
        return

    var icon := Sprite2D.new()
    icon.name = "RangedAttackIcon"
    icon.texture = ranged_attack_icon_texture
    icon.scale = ranged_attack_icon_scale
    icon.z_index = ranged_attack_icon_z_index
    icon.global_position = global_position

    var current_scene := get_tree().current_scene

    if current_scene != null:
        current_scene.add_child(icon)
    else:
        add_child(icon)

    var target_position := target.global_position
    var travel_distance := icon.global_position.distance_to(target_position)
    var travel_time := ranged_attack_icon_lifetime

    if ranged_attack_icon_speed > 0.0:
        travel_time = travel_distance / ranged_attack_icon_speed
        travel_time = clampf(travel_time, 0.08, ranged_attack_icon_lifetime)

    var direction := icon.global_position.direction_to(target_position)

    if direction != Vector2.ZERO:
        icon.rotation = direction.angle()

    var tween := icon.create_tween()
    tween.tween_property(icon, "global_position", target_position, travel_time)
    tween.tween_property(icon, "modulate:a", 0.0, 0.12)
    tween.finished.connect(icon.queue_free)


func _show_default_ranged_attack_icon(target: Node2D) -> void:
    if target == null:
        return

    var icon := ColorRect.new()
    icon.name = "DefaultRangedAttackIcon"
    icon.size = Vector2(8.0, 8.0)
    icon.pivot_offset = icon.size * 0.5
    icon.color = Color(1.0, 0.85, 0.25, 1.0)
    icon.z_index = ranged_attack_icon_z_index
    icon.global_position = global_position

    var current_scene := get_tree().current_scene

    if current_scene != null:
        current_scene.add_child(icon)
    else:
        add_child(icon)

    var target_position := target.global_position
    var travel_distance := icon.global_position.distance_to(target_position)
    var travel_time := ranged_attack_icon_lifetime

    if ranged_attack_icon_speed > 0.0:
        travel_time = travel_distance / ranged_attack_icon_speed
        travel_time = clampf(travel_time, 0.08, ranged_attack_icon_lifetime)

    var tween := icon.create_tween()
    tween.tween_property(icon, "global_position", target_position, travel_time)
    tween.tween_property(icon, "modulate:a", 0.0, 0.12)
    tween.finished.connect(icon.queue_free)


func _damage_player(player: Node2D, damage_amount: int, attack_damage_types: int) -> void:
    if player == null:
        return

    if player.has_method("take_damage_with_types"):
        player.take_damage_with_types(damage_amount, attack_damage_types)
    elif player.has_method("take_damage"):
        player.take_damage(damage_amount)


func _is_player_in_melee_range() -> bool:
    return player_in_attack_range != null


func _is_player_in_ranged_range() -> bool:
    if player_target == null:
        return false

    return global_position.distance_to(player_target.global_position) <= ranged_range


func _connect_attack_area() -> void:
    if attack_area == null:
        return

    if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
        attack_area.body_entered.connect(_on_attack_area_body_entered)

    if not attack_area.body_exited.is_connected(_on_attack_area_body_exited):
        attack_area.body_exited.connect(_on_attack_area_body_exited)


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


func _update_animation_from_velocity(current_velocity: Vector2) -> void:
    if animated_sprite_2d == null:
        return

    if animated_sprite_2d.sprite_frames == null:
        return

    if current_velocity.length() <= 1.0:
        _play_monster_animation("idle_" + last_direction)
        return

    if abs(current_velocity.x) > abs(current_velocity.y):
        if current_velocity.x > 0.0:
            last_direction = "right"
        else:
            last_direction = "left"
    else:
        if current_velocity.y > 0.0:
            last_direction = "down"
        else:
            last_direction = "up"

    _play_monster_animation("walk_" + last_direction)


func _play_monster_animation(animation_name: String) -> void:
    if animated_sprite_2d == null:
        return

    if animated_sprite_2d.sprite_frames == null:
        return

    if animated_sprite_2d.sprite_frames.has_animation(animation_name):
        if animated_sprite_2d.animation != animation_name:
            animated_sprite_2d.play(animation_name)
        return

    if animated_sprite_2d.sprite_frames.has_animation("walk_down"):
        if animated_sprite_2d.animation != "walk_down":
            animated_sprite_2d.play("walk_down")


func take_damage_from_player(damage_amount: int, player: Node2D) -> void:
    if is_dead:
        return

    var incoming_damage_types := DamageTypes.NONE

    if player != null and player.has_method("get_character_stats"):
        var stats: CharacterStats = player.get_character_stats()

        if stats != null:
            incoming_damage_types = stats.get_equipped_weapon_damage_types()

    _apply_damage(damage_amount, incoming_damage_types, player)


func take_damage(damage_amount: int) -> void:
    if is_dead:
        return

    _apply_damage(damage_amount, DamageTypes.NONE, null)


func take_damage_with_types(damage_amount: int, incoming_damage_types: int, attacker: Node2D = null) -> void:
    if is_dead:
        return

    _apply_damage(damage_amount, incoming_damage_types, attacker)


func _apply_damage(damage_amount: int, incoming_damage_types: int, attacker: Node2D = null) -> void:
    var final_damage: int = maxi(1, damage_amount - defense)

    if _is_weak_to_damage_types(incoming_damage_types):
        final_damage = maxi(1, int(ceil(float(final_damage) * weakness_damage_multiplier)))
        print(monster_name, " weakness hit! Damage types: ", DamageTypes.get_damage_type_names(incoming_damage_types))

    current_hit_points -= final_damage
    _flash_damage()

    print(monster_name, " took damage: ", final_damage)
    print(monster_name, " HP: ", current_hit_points, " / ", max_hit_points)

    if current_hit_points <= 0:
        die(attacker)


func _is_weak_to_damage_types(incoming_damage_types: int) -> bool:
    if incoming_damage_types == DamageTypes.NONE:
        return false

    if weakness_types == DamageTypes.NONE:
        return false

    return DamageTypes.damage_types_overlap(incoming_damage_types, weakness_types)


func flash_for_special_attack() -> void:
    _flash_attack()


func _flash_attack() -> void:
    if not flash_on_attack:
        return

    _flash_sprite(attack_flash_color, attack_flash_duration)


func _flash_damage() -> void:
    if not flash_on_damage:
        return

    _flash_sprite(damage_flash_color, damage_flash_duration)


func _flash_sprite(flash_color: Color, flash_duration: float) -> void:
    var visual_node := _get_primary_visual_node()

    if visual_node == null:
        return

    if flash_tween != null:
        flash_tween.kill()
        flash_tween = null

    var original_modulate: Color = visual_node.modulate

    visual_node.modulate = flash_color

    flash_tween = create_tween()
    flash_tween.tween_property(visual_node, "modulate", original_modulate, flash_duration)

func _get_primary_visual_node() -> CanvasItem:
    if animated_sprite_2d != null:
        return animated_sprite_2d

    if sprite_2d != null:
        return sprite_2d

    return null


func die(player: Node2D = null) -> void:
    if is_dead:
        return

    is_dead = true

    print(monster_name, " defeated. XP reward: ", xp_reward)

    if boss_defeated_flag.strip_edges() != "":
        SaveManager.set_flag(boss_defeated_flag, true)
        print("Boss defeated flag set: ", boss_defeated_flag)

    if special_attacks != null:
        special_attacks.clear_all_special_visuals()

    if _should_save_defeat_state():
        SaveManager.mark_monster_defeated(persistent_id)

    _award_xp_to_player_if_eligible(player)
    _roll_drops_for_player(player)
    monster_defeated.emit(self, player)
    _show_first_monster_defeated_lesson(player)

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


func _roll_drops_for_player(player: Node2D) -> void:
    if player == null:
        return

    _roll_item_drop(player, drop_item_1_id, drop_item_1_chance_percent, "Item Slot 1")
    _roll_item_drop(player, drop_item_2_id, drop_item_2_chance_percent, "Item Slot 2")
    _roll_currency_drop(player)


func _roll_item_drop(player: Node2D, item_id: String, chance_percent: float, slot_name: String) -> void:
    var clean_item_id := item_id.strip_edges()

    if clean_item_id == "":
        return

    if chance_percent <= 0.0:
        return

    var roll := randf_range(0.0, 100.0)

    if roll > chance_percent:
        print(monster_name, " ", slot_name, " drop failed. Roll: ", roll, " Chance: ", chance_percent)
        return

    if not player.has_method("add_inventory_item"):
        push_warning("Player cannot receive item drops. Missing add_inventory_item().")
        return

    var item_name := ItemDatabase.get_item_name(clean_item_id)
    player.add_inventory_item(clean_item_id, item_name)

    print(monster_name, " dropped item: ", item_name, " Roll: ", roll, " Chance: ", chance_percent)


func _roll_currency_drop(player: Node2D) -> void:
    var clean_currency_id := drop_currency_id.strip_edges()

    if clean_currency_id == "":
        return

    if drop_currency_chance_percent <= 0.0:
        return

    var roll := randf_range(0.0, 100.0)

    if roll > drop_currency_chance_percent:
        print(monster_name, " currency drop failed. Roll: ", roll, " Chance: ", drop_currency_chance_percent)
        return

    if not player.has_method("add_currency"):
        push_warning("Player cannot receive currency drops. Missing add_currency().")
        return

    var min_amount: int = maxi(0, drop_currency_min_amount)
    var max_amount: int = maxi(min_amount, drop_currency_max_amount)

    if max_amount <= 0:
        return

    var amount := randi_range(min_amount, max_amount)

    if amount <= 0:
        return

    player.add_currency(clean_currency_id, amount)

    print(monster_name, " dropped currency: ", clean_currency_id, " x", amount, " Roll: ", roll, " Chance: ", drop_currency_chance_percent)


func _show_first_monster_defeated_lesson(player: Node2D) -> void:
    if player == null:
        return

    if SaveManager.is_flag_set("first_monster_defeated"):
        return

    SaveManager.set_flag("first_monster_defeated", true)

    var dialogue_lines: Array[String] = [
        "You felt it, did you not?",
        "Mezoria answers struggle with growth.",
        "Defeating creatures grants experience.",
        "Enough experience will strengthen you.",
        "But do not become careless.",
        "Growth is useful only to the living."
    ]

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_story_dialogue"):
        game_ui.show_story_dialogue(dialogue_lines, "Echo Spirit")
        return

    if player.has_method("show_dialogue"):
        player.show_dialogue("You gained experience from defeating the creature.")


func _get_game_ui() -> Node:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("show_story_dialogue"):
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null and autoload_ui.has_method("show_story_dialogue"):
        return autoload_ui

    return null


func _award_xp_to_player_if_eligible(player: Node2D) -> void:
    if player == null:
        return

    if not player.has_method("gain_xp"):
        return

    var player_level: int = _get_player_level(player)
    var lowest_xp_level: int = player_level - xp_level_cutoff_below_player

    if monster_level < lowest_xp_level:
        print(
            monster_name,
            " gave no XP. Monster level ",
            monster_level,
            " is below XP cutoff level ",
            lowest_xp_level,
            " for player level ",
            player_level,
            "."
        )
        return

    player.gain_xp(xp_reward)


func _get_player_level(player: Node2D) -> int:
    if player == null:
        return 0

    if not player.has_method("get_character_stats"):
        return 0

    var stats: CharacterStats = player.get_character_stats()

    if stats == null:
        return 0

    return stats.level


func _should_save_defeat_state() -> bool:
    if persistent_id.strip_edges() == "":
        return false

    match respawn_mode:
        RespawnMode.ALWAYS_RESPAWN:
            return false

        RespawnMode.NEVER_RESPAWN:
            return true

        RespawnMode.USE_MAP_DEFAULT:
            return not _get_map_monsters_respawn_by_default()

    return false


func _get_map_monsters_respawn_by_default() -> bool:
    var current_scene := get_tree().current_scene

    if current_scene == null:
        return false

    var map_settings := current_scene.find_child("MapSettings", true, false) as MapSettings

    if map_settings == null:
        return false

    return map_settings.monsters_respawn_by_default


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

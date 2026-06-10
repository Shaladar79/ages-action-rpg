extends CharacterBody2D

const PlayerInventoryComponentScript = preload("res://scripts/player/components/player_inventory_component.gd")
const PlayerEquipmentComponentScript = preload("res://scripts/player/components/player_equipment_component.gd")

const HOTBAR_SLOT_COUNT: int = 8
const STARTING_ARMOR_ID: String = "grass_tunic"

const CURRENCY_MARKS: String = "marks"

const CURRENCY_DISPLAY_NAMES: Dictionary = {
    CURRENCY_MARKS: "Marks"
}
const QUEST_HOTBAR_AND_CLUB_LESSON_ID: String = "starter_hotbar_and_club_lesson"
const QUEST_HEALING_TONIC_HOTBAR_OBJECTIVE_ID: String = "equip_healing_tonic_hotbar_01"
const QUEST_HEALING_TONIC_HOTBAR_FLAG: String = "starter_healing_tonic_hotbar_equipped"

const ITEM_HEALING_TONIC_ID: String = "healing_tonic"

@export var base_move_speed: float = 120.0
@export var move_speed_per_speed_point: float = 4.0

@export_group("Attack Timing")
@export var attack_damage_window: float = 0.14
@export var weapon_visual_duration: float = 0.20
@export var base_attack_cooldown: float = 0.5
@export var attack_speed_bonus_per_agility: float = 0.05
@export var attack_offset: float = 24.0

@export var respawn_delay: float = 1.5

@export var weapon_visual_offset: float = 22.0
@export var weapon_visual_scale: Vector2 = Vector2(1.0, 1.0)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var weapon_sprite: Sprite2D = get_node_or_null("WeaponSprite") as Sprite2D

var character_stats: CharacterStats = CharacterStats.new()

var last_direction: String = "down"
var is_attacking: bool = false
var is_defeated: bool = false
var is_respawning: bool = false
var attack_damage_timer: float = 0.0
var weapon_visual_timer: float = 0.0
var cooldown_timer: float = 0.0
var hit_targets: Array[Node] = []

var nearby_interactable: Node = null

var inventory: Array[Dictionary] = []
var hotbar_slots: Array[Dictionary] = []

var currencies: Dictionary = {}
var discovered_currency_ids: Array[String] = []
var active_status_effects: Dictionary = {}

var inventory_component: PlayerInventoryComponent = null
var equipment_component: PlayerEquipmentComponent = null

@export_group("Spell Casting")
@export var spell_projectile_speed: float = 260.0
@export var spell_projectile_spawn_offset: float = 18.0
@export var spell_projectile_collision_layer: int = 0
@export var spell_projectile_collision_mask: int = 1

@export_group("Ranged Attack")
@export var ranged_attack_cooldown: float = 0.65
@export var ranged_projectile_collision_layer: int = 0
@export var ranged_projectile_collision_mask: int = 1


func _ready() -> void:
    add_to_group("player")

    inventory_component = PlayerInventoryComponentScript.new()
    inventory_component.setup(self)

    equipment_component = PlayerEquipmentComponentScript.new()
    equipment_component.setup(self)

    _initialize_hotbar_slots()
    _initialize_currencies()
    _ensure_starting_equipment()
    _disable_attack_hitbox()
    _hide_weapon_sprite()

    if not attack_area.area_entered.is_connected(_on_attack_area_entered):
        attack_area.area_entered.connect(_on_attack_area_entered)

    call_deferred("_apply_startup_position_if_needed")


func _initialize_hotbar_slots() -> void:
    if hotbar_slots.size() == HOTBAR_SLOT_COUNT:
        return

    hotbar_slots.clear()

    for slot_index in range(HOTBAR_SLOT_COUNT):
        hotbar_slots.append({
            "slot": slot_index + 1,
            "item_id": "",
            "item_type": "",
            "cooldown_remaining": 0.0
        })


func _ensure_starting_equipment() -> void:
    if not has_inventory_item(STARTING_ARMOR_ID):
        inventory.append({
            "id": STARTING_ARMOR_ID,
            "name": ItemDatabase.get_item_name(STARTING_ARMOR_ID)
        })

    if character_stats.equipped_armor_id.strip_edges() == "":
        character_stats.equip_armor(STARTING_ARMOR_ID, ItemDatabase.get_item_name(STARTING_ARMOR_ID))


func _apply_startup_position_if_needed() -> void:
    if not SaveManager.pending_loaded_data.is_empty():
        print("Applying pending save data to player.")
        SaveManager.apply_pending_loaded_data(self)
        _notify_ui_stats_changed()
        return

    if SceneTransitionManager.has_pending_player_data():
        SceneTransitionManager.apply_player_data(self)

    if SceneTransitionManager.has_pending_respawn_position():
        var respawn_position: Vector2 = SceneTransitionManager.consume_pending_respawn_position()
        global_position = respawn_position
        velocity = Vector2.ZERO
        _notify_ui_stats_changed()
        show_dialogue("You return to the totem.")
        print("Player moved to pending respawn position: ", respawn_position)
        return

    if SceneTransitionManager.has_pending_spawn():
        var spawn_id: String = SceneTransitionManager.consume_pending_spawn()
        _move_to_map_spawn(spawn_id)
        _notify_ui_stats_changed()
        return

    _notify_ui_stats_changed()
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


func _physics_process(delta: float) -> void:
    _update_attack_timers(delta)
    _update_hotbar_cooldowns(delta)
    _update_status_effects(delta)

    if Input.is_action_just_pressed("dialogue_continue"):
        if is_dialogue_active():
            hide_dialogue()
            _notify_nearby_interactable_dialogue_closed()
            return

    if is_defeated:
        velocity = Vector2.ZERO
        move_and_slide()
        return

    if _handle_hotbar_input():
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

    if InputMap.has_action("r_attack") and Input.is_action_just_pressed("r_attack"):
        _try_ranged_attack()
    elif InputMap.has_action("m_attack") and Input.is_action_just_pressed("m_attack"):
        _try_attack()

    if attack_damage_timer > 0.0:
        _check_attack_overlaps()

    _update_animation(input_vector)


func get_character_stats() -> CharacterStats:
    return character_stats


func get_current_move_speed() -> float:
    return character_stats.get_move_speed(base_move_speed, move_speed_per_speed_point) * StatusEffects.get_move_speed_multiplier(active_status_effects)


func get_current_attack_cooldown() -> float:
    return character_stats.get_attack_cooldown(base_attack_cooldown, attack_speed_bonus_per_agility)


func apply_status_effect(status_id: String, duration: float, effect_data: Dictionary = {}) -> bool:
    if is_defeated:
        return false

    var applied := StatusEffects.apply_status_effect(active_status_effects, status_id, duration, effect_data)

    if applied:
        print("Player status applied/refreshed: ", status_id, " duration: ", duration)

    return applied


func remove_status_effect(status_id: String) -> bool:
    var removed := StatusEffects.remove_status_effect(active_status_effects, status_id)

    if removed:
        print("Player status removed: ", status_id)

    return removed


func has_status_effect(status_id: String) -> bool:
    return StatusEffects.has_status_effect(active_status_effects, status_id)


func _update_status_effects(delta: float) -> void:
    var update_result := StatusEffects.update_status_effects(active_status_effects, delta)

    var tick_events: Array = update_result.get("tick_events", [])

    for tick_event in tick_events:
        if typeof(tick_event) != TYPE_DICTIONARY:
            continue

        var damage_amount: int = int(tick_event.get("damage_amount", 0))
        var damage_types: int = int(tick_event.get("damage_types", DamageTypes.NONE))
        var status_id: String = str(tick_event.get("status_id", ""))

        if damage_amount <= 0:
            continue

        print("Player status tick: ", status_id, " damage: ", damage_amount)
        var ignore_defense: bool = bool(tick_event.get("ignore_defense", false))

        if ignore_defense:
            take_status_tick_damage(damage_amount, damage_types)
        else:
            take_damage_with_types(damage_amount, damage_types)

    var expired_status_ids: Array = update_result.get("expired_status_ids", [])

    for status_id in expired_status_ids:
        print("Player status expired: ", status_id)


func take_status_tick_damage(incoming_damage: int, incoming_damage_types: int = DamageTypes.NONE) -> void:
    if is_defeated:
        return

    if incoming_damage <= 0:
        return

    if incoming_damage_types != DamageTypes.NONE and _is_resistant_to_damage_types(incoming_damage_types):
        print("Status tick negated by resistance: ", DamageTypes.get_damage_type_names(incoming_damage_types))
        return

    character_stats.current_health -= incoming_damage
    character_stats.current_health = maxi(character_stats.current_health, 0)

    print("Player took status tick damage: ", incoming_damage)

    if incoming_damage_types != DamageTypes.NONE:
        print("Status tick damage types: ", DamageTypes.get_damage_type_names(incoming_damage_types))

    print("Player HP: ", character_stats.current_health, " / ", character_stats.max_health)

    _notify_ui_stats_changed()

    if character_stats.current_health <= 0:
        _on_player_defeated()


func gain_xp(amount: int) -> bool:
    if is_defeated:
        return false

    if amount <= 0:
        return false

    if character_stats == null:
        return false

    var previous_level: int = character_stats.level
    var leveled_up := character_stats.add_xp(amount)
    var current_level: int = character_stats.level

    print("Player gained XP: ", amount)
    print("Player XP: ", character_stats.xp, " / ", character_stats.xp_to_next_level)

    _notify_ui_stats_changed()

    if leveled_up:
        print("Player leveled up from ", previous_level, " to ", current_level)

        if not SaveManager.is_flag_set("level_up_lesson_seen"):
            _show_first_level_up_lesson()
        else:
            print("Level-up lesson already seen. Skipping repeated level-up dialogue.")

    return leveled_up


func _show_first_level_up_lesson() -> void:
    if SaveManager.is_flag_set("level_up_lesson_seen"):
        return

    SaveManager.set_flag("level_up_lesson_seen", true)

    var dialogue_lines: Array[String] = [
        "Your body is changing.",
        "Mezoria has begun to recognize you.",
        "This is growth, Gene Ambrose.",
        "When you grow stronger, open your character screen.",
        "There you may shape what you become.",
        "Strength, endurance, precision, will — each path leaves a mark."
    ]

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_story_dialogue"):
        game_ui.show_story_dialogue(dialogue_lines, "Echo Spirit")
        return

    show_dialogue("You gained a level. Open your character sheet and spend your character point.")


func _get_game_ui() -> Node:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("show_story_dialogue"):
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null and autoload_ui.has_method("show_story_dialogue"):
        return autoload_ui

    return null


func _show_notification(message: String) -> void:
    var clean_message := message.strip_edges()

    if clean_message == "":
        return

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_notification"):
        game_ui.show_notification(clean_message)


func _show_reward_notification(message: String) -> void:
    var clean_message := message.strip_edges()

    if clean_message == "":
        return

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_reward_notification"):
        game_ui.show_reward_notification(clean_message)
        return

    _show_notification(clean_message)


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


func add_inventory_item(item_id: String, item_name: String, quantity: int = 1) -> void:
    if inventory_component == null:
        return

    inventory_component.add_inventory_item(item_id, item_name, quantity)


func _handle_spell_book_acquisition(item_id: String) -> void:
    if item_id.strip_edges() == "":
        return

    if not ItemDatabase.is_spell_book(item_id):
        return

    _unlock_mana_and_focus_from_first_spell_book()


func _handle_key_item_acquisition(item_id: String) -> void:
    var clean_item_id := item_id.strip_edges()

    if clean_item_id == "":
        return

    if not ItemDatabase.is_key_item(clean_item_id):
        return

    var story_flag := ItemDatabase.get_story_flag_on_acquire(clean_item_id)

    if story_flag.strip_edges() == "":
        return

    SaveManager.set_flag(story_flag, true)
    print("Key item acquisition flag set: ", story_flag)


func _unlock_mana_and_focus_from_first_spell_book() -> bool:
    if character_stats == null:
        return false

    if character_stats.has_mana_resource:
        return false

    var unlocked := character_stats.unlock_mana_resource(true)

    SaveManager.set_flag("mana_unlocked", true)
    SaveManager.set_flag("focus_unlocked", true)

    _notify_ui_stats_changed()
    _show_first_spell_book_lesson()

    return unlocked


func _show_first_spell_book_lesson() -> void:
    if SaveManager.is_flag_set("spellbook_lesson_seen"):
        return

    SaveManager.set_flag("spellbook_lesson_seen", true)

    var dialogue_lines: Array[String] = [
        "This is a spell book.",
        "A spell book can be assigned to your hotbar.",
        "Casting spells uses Mana.",
        "Your Focus increases your maximum Mana.",
        "As you learn more spells, different schools of magic may grow stronger through use."
    ]

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_story_dialogue"):
        game_ui.show_story_dialogue(dialogue_lines, "Echo Spirit")
        return

    show_dialogue("You found a spell book. Mana and Focus are now unlocked.")


func remove_inventory_item(item_id: String, quantity: int = 1) -> bool:
    if inventory_component == null:
        return false

    return inventory_component.remove_inventory_item(item_id, quantity)


func has_inventory_item(item_id: String) -> bool:
    if inventory_component == null:
        return false

    return inventory_component.has_inventory_item(item_id)



func get_inventory_item_name(item_id: String) -> String:
    if inventory_component == null:
        return item_id

    return inventory_component.get_inventory_item_name(item_id)


func get_inventory_items() -> Array[Dictionary]:
    if inventory_component == null:
        return inventory

    return inventory_component.get_inventory_items()


func set_inventory_items(saved_inventory: Array) -> void:
    if inventory_component == null:
        inventory = []
        return

    inventory_component.set_inventory_items(saved_inventory)


func _add_loaded_stackable_inventory_item(item_id: String, item_name: String, quantity: int) -> void:
    if inventory_component == null:
        return

    inventory_component._add_loaded_stackable_inventory_item(item_id, item_name, quantity)


func _is_stackable_inventory_item(item_id: String) -> bool:
    if inventory_component == null:
        return ItemDatabase.is_stackable_item(item_id)

    return inventory_component._is_stackable_inventory_item(item_id)



func _initialize_currencies() -> void:
    if not currencies.has(CURRENCY_MARKS):
        currencies[CURRENCY_MARKS] = 0

    if not discovered_currency_ids.has(CURRENCY_MARKS):
        discovered_currency_ids.append(CURRENCY_MARKS)


func get_currency_display_name(_currency_id: String = CURRENCY_MARKS) -> String:
    return "Marks"


func add_marks(amount: int) -> bool:
    if is_defeated:
        return false

    if amount <= 0:
        return false

    _initialize_currencies()

    var current_amount: int = int(currencies.get(CURRENCY_MARKS, 0))
    currencies[CURRENCY_MARKS] = current_amount + amount

    _discover_currency(CURRENCY_MARKS)

    print("Added Marks: +", amount)
    print("Marks total: ", currencies[CURRENCY_MARKS])

    _show_reward_notification("Received: " + str(amount) + " Marks")
    _notify_ui_stats_changed()

    return true


func spend_marks(amount: int) -> bool:
    if amount <= 0:
        return false

    _initialize_currencies()

    var current_amount: int = int(currencies.get(CURRENCY_MARKS, 0))

    if current_amount < amount:
        return false

    currencies[CURRENCY_MARKS] = current_amount - amount

    print("Spent Marks: -", amount)
    print("Marks total: ", currencies[CURRENCY_MARKS])

    _notify_ui_stats_changed()

    return true


func get_marks() -> int:
    _initialize_currencies()
    return int(currencies.get(CURRENCY_MARKS, 0))


func add_currency(_currency_id: String, amount: int) -> bool:
    return add_marks(amount)


func spend_currency(_currency_id: String, amount: int) -> bool:
    return spend_marks(amount)


func get_currency_amount(_currency_id: String = CURRENCY_MARKS) -> int:
    return get_marks()


func is_currency_discovered(_currency_id: String = CURRENCY_MARKS) -> bool:
    _initialize_currencies()
    return true


func _discover_currency(_currency_id: String) -> void:
    _initialize_currencies()

    if discovered_currency_ids.has(CURRENCY_MARKS):
        return

    discovered_currency_ids.append(CURRENCY_MARKS)
    print("Currency discovered: Marks")


func get_discovered_currency_rows() -> Array[Dictionary]:
    _initialize_currencies()

    return [
        {
            "id": CURRENCY_MARKS,
            "name": "Marks",
            "amount": get_marks()
        }
    ]


func get_currency_save_data() -> Dictionary:
    _initialize_currencies()

    return {
        "currencies": currencies.duplicate(true),
        "discovered_currency_ids": discovered_currency_ids.duplicate()
    }


func set_currency_save_data(saved_currency_data: Dictionary) -> void:
    currencies.clear()
    discovered_currency_ids.clear()

    var total_marks: int = 0
    var saved_currencies: Dictionary = saved_currency_data.get("currencies", {})

    for currency_id in saved_currencies.keys():
        total_marks += int(saved_currencies.get(currency_id, 0))

    currencies[CURRENCY_MARKS] = maxi(0, total_marks)
    discovered_currency_ids.append(CURRENCY_MARKS)

    print("Currency save data loaded as Marks. Total Marks: ", currencies[CURRENCY_MARKS])
    _notify_ui_stats_changed()


func equip_melee_weapon(item_id: String) -> bool:
    if equipment_component == null:
        return false

    return equipment_component.equip_melee_weapon(item_id)


func equip_ranged_weapon(item_id: String) -> bool:
    if equipment_component == null:
        return false

    return equipment_component.equip_ranged_weapon(item_id)


func equip_armor(item_id: String) -> bool:
    if equipment_component == null:
        return false

    return equipment_component.equip_armor(item_id)


func equip_accessory_1(item_id: String) -> bool:
    if equipment_component == null:
        return false

    return equipment_component.equip_accessory_1(item_id)


func equip_accessory_2(item_id: String) -> bool:
    if equipment_component == null:
        return false

    return equipment_component.equip_accessory_2(item_id)


func equip_weapon(item_id: String) -> void:
    if equipment_component == null:
        return

    equipment_component.equip_weapon(item_id)


func equip_accessory(item_id: String) -> void:
    if equipment_component == null:
        return

    equipment_component.equip_accessory(item_id)


func _equip_weapon_compat(item_id: String) -> bool:
    if equipment_component == null:
        return false

    return equipment_component._equip_weapon_compat(item_id)


func _equip_item_to_slot(item_id: String, target_slot: String) -> bool:
    if equipment_component == null:
        return false

    return equipment_component._equip_item_to_slot(item_id, target_slot)


func _unequip_slot(target_slot: String) -> void:
    if equipment_component == null:
        return

    equipment_component._unequip_slot(target_slot)


func unequip_melee_weapon() -> void:
    if equipment_component == null:
        return

    equipment_component.unequip_melee_weapon()


func unequip_ranged_weapon() -> void:
    if equipment_component == null:
        return

    equipment_component.unequip_ranged_weapon()


func unequip_armor() -> void:
    if equipment_component == null:
        return

    equipment_component.unequip_armor()


func unequip_accessory_1() -> void:
    if equipment_component == null:
        return

    equipment_component.unequip_accessory_1()


func unequip_accessory_2() -> void:
    if equipment_component == null:
        return

    equipment_component.unequip_accessory_2()


func unequip_weapon() -> void:
    unequip_melee_weapon()


func unequip_accessory() -> void:
    unequip_accessory_1()


func has_equipped_weapon() -> bool:
    if equipment_component == null:
        return character_stats.equipped_melee_weapon_id.strip_edges() != ""

    return equipment_component.has_equipped_weapon()


func has_equipped_melee_weapon() -> bool:
    if equipment_component == null:
        return character_stats.equipped_melee_weapon_id.strip_edges() != ""

    return equipment_component.has_equipped_melee_weapon()


func has_equipped_ranged_weapon() -> bool:
    if equipment_component == null:
        return character_stats.equipped_ranged_weapon_id.strip_edges() != ""

    return equipment_component.has_equipped_ranged_weapon()


func get_equipped_weapon_name() -> String:
    if equipment_component == null:
        return character_stats.get_equipped_weapon_name()

    return equipment_component.get_equipped_weapon_name()


func get_equipped_melee_weapon_name() -> String:
    if equipment_component == null:
        return character_stats.get_equipped_melee_weapon_name()

    return equipment_component.get_equipped_melee_weapon_name()


func get_equipped_ranged_weapon_name() -> String:
    if equipment_component == null:
        return character_stats.get_equipped_ranged_weapon_name()

    return equipment_component.get_equipped_ranged_weapon_name()


func get_equipped_armor_name() -> String:
    if equipment_component == null:
        return character_stats.get_equipped_armor_name()

    return equipment_component.get_equipped_armor_name()


func get_equipped_accessory_name() -> String:
    if equipment_component == null:
        return character_stats.get_equipped_accessory_name()

    return equipment_component.get_equipped_accessory_name()


func get_equipped_accessory_1_name() -> String:
    if equipment_component == null:
        return character_stats.get_equipped_accessory_1_name()

    return equipment_component.get_equipped_accessory_1_name()


func get_equipped_accessory_2_name() -> String:
    if equipment_component == null:
        return character_stats.get_equipped_accessory_2_name()

    return equipment_component.get_equipped_accessory_2_name()


func _unequip_missing_item_if_needed(item_id: String) -> void:
    if equipment_component == null:
        return

    equipment_component.unequip_missing_item_if_needed(item_id)


func _validate_equipment_after_inventory_load() -> void:
    if equipment_component == null:
        return

    equipment_component.validate_equipment_after_inventory_load()

func get_attack_damage() -> int:
    var base_damage: int = character_stats.get_attack()
    var mastery_id := get_equipped_melee_weapon_mastery_id()

    if mastery_id.strip_edges() == "":
        return base_damage

    if MasteryManager == null:
        return base_damage

    var multiplier: float = MasteryManager.get_weapon_damage_multiplier(mastery_id)

    return maxi(1, int(ceil(float(base_damage) * multiplier)))


func get_equipped_melee_weapon_mastery_id() -> String:
    if character_stats == null:
        return ""

    var weapon_id := character_stats.equipped_melee_weapon_id.strip_edges()

    if weapon_id == "":
        return ""

    return ItemDatabase.get_weapon_mastery_id(weapon_id)


func get_equipped_ranged_weapon_mastery_id() -> String:
    if character_stats == null:
        return ""

    var weapon_id := character_stats.equipped_ranged_weapon_id.strip_edges()

    if weapon_id == "":
        return ""

    return ItemDatabase.get_weapon_mastery_id(weapon_id)


func get_ranged_attack_damage() -> int:
    var base_damage: int = character_stats.get_ranged_attack()
    var mastery_id := get_equipped_ranged_weapon_mastery_id()

    if mastery_id.strip_edges() == "":
        return base_damage

    if MasteryManager == null:
        return base_damage

    var multiplier: float = MasteryManager.get_weapon_damage_multiplier(mastery_id)

    return maxi(1, int(ceil(float(base_damage) * multiplier)))


func get_defense() -> int:
    return character_stats.get_defense() + StatusEffects.get_defense_bonus(active_status_effects)
    
func get_hotbar_slots() -> Array[Dictionary]:
    _initialize_hotbar_slots()

    var saved_slots: Array[Dictionary] = []

    for slot in hotbar_slots:
        saved_slots.append({
            "slot": int(slot.get("slot", 0)),
            "item_id": str(slot.get("item_id", "")),
            "item_type": str(slot.get("item_type", "")),
            "cooldown_remaining": float(slot.get("cooldown_remaining", 0.0))
        })

    return saved_slots


func set_hotbar_slots(saved_slots: Array) -> void:
    _initialize_hotbar_slots()

    for saved_slot in saved_slots:
        if typeof(saved_slot) != TYPE_DICTIONARY:
            continue

        var slot_number: int = int(saved_slot.get("slot", 0))
        var item_id: String = str(saved_slot.get("item_id", ""))
        var item_type: String = str(saved_slot.get("item_type", ""))
        var cooldown_remaining: float = float(saved_slot.get("cooldown_remaining", 0.0))

        if slot_number < 1 or slot_number > HOTBAR_SLOT_COUNT:
            continue

        var slot_index: int = slot_number - 1
        hotbar_slots[slot_index] = {
            "slot": slot_number,
            "item_id": item_id,
            "item_type": item_type,
            "cooldown_remaining": cooldown_remaining
        }

    _clear_invalid_hotbar_slots()
    _notify_ui_stats_changed()


func assign_hotbar_slot(slot_number: int, item_id: String) -> bool:
    _initialize_hotbar_slots()

    if slot_number < 1 or slot_number > HOTBAR_SLOT_COUNT:
        push_warning("Invalid hotbar slot: " + str(slot_number))
        return false

    if item_id.strip_edges() == "":
        clear_hotbar_slot(slot_number)
        return true

    if not has_inventory_item(item_id):
        push_warning("Cannot assign hotbar item. Item not in inventory: " + item_id)
        return false

    if not ItemDatabase.is_hotbar_usable(item_id):
        push_warning("Cannot assign item to hotbar. Item is not hotbar usable: " + item_id)
        return false

    var slot_index: int = slot_number - 1
    var item_type: String = ItemDatabase.get_item_type(item_id)

    hotbar_slots[slot_index] = {
        "slot": slot_number,
        "item_id": item_id,
        "item_type": item_type,
        "cooldown_remaining": 0.0
    }

    print("Assigned hotbar slot ", slot_number, ": ", ItemDatabase.get_item_name(item_id))

    _try_progress_healing_tonic_hotbar_quest(item_id)
    _notify_ui_stats_changed()

    return true

func _try_progress_healing_tonic_hotbar_quest(item_id: String) -> void:
    var clean_item_id := item_id.strip_edges()

    if clean_item_id != ITEM_HEALING_TONIC_ID:
        return

    if SaveManager.is_flag_set(QUEST_HEALING_TONIC_HOTBAR_FLAG):
        return

    if not QuestManager.is_quest_active(QUEST_HOTBAR_AND_CLUB_LESSON_ID):
        return

    var progress_added := QuestManager.add_objective_progress(
        QUEST_HOTBAR_AND_CLUB_LESSON_ID,
        QUEST_HEALING_TONIC_HOTBAR_OBJECTIVE_ID,
        1
    )

    if not progress_added:
        print("Healing Tonic hotbar quest progress failed.")
        return

    SaveManager.set_flag(QUEST_HEALING_TONIC_HOTBAR_FLAG, true)
    print("Healing Tonic hotbar quest objective completed.")

func clear_hotbar_slot(slot_number: int) -> void:
    _initialize_hotbar_slots()

    if slot_number < 1 or slot_number > HOTBAR_SLOT_COUNT:
        return

    var slot_index: int = slot_number - 1

    hotbar_slots[slot_index] = {
        "slot": slot_number,
        "item_id": "",
        "item_type": "",
        "cooldown_remaining": 0.0
    }

    print("Cleared hotbar slot: ", slot_number)
    _notify_ui_stats_changed()


func _clear_hotbar_slots_for_missing_item(item_id: String) -> void:
    _initialize_hotbar_slots()

    for slot_index in range(hotbar_slots.size()):
        var slot: Dictionary = hotbar_slots[slot_index]
        var slot_item_id: String = str(slot.get("item_id", ""))

        if slot_item_id == item_id and not has_inventory_item(item_id):
            var slot_number: int = int(slot.get("slot", slot_index + 1))
            hotbar_slots[slot_index] = {
                "slot": slot_number,
                "item_id": "",
                "item_type": "",
                "cooldown_remaining": 0.0
            }


func _clear_invalid_hotbar_slots() -> void:
    _initialize_hotbar_slots()

    for slot_index in range(hotbar_slots.size()):
        var slot: Dictionary = hotbar_slots[slot_index]
        var slot_number: int = int(slot.get("slot", slot_index + 1))
        var item_id: String = str(slot.get("item_id", ""))

        if item_id.strip_edges() == "":
            continue

        if not has_inventory_item(item_id):
            hotbar_slots[slot_index] = {
                "slot": slot_number,
                "item_id": "",
                "item_type": "",
                "cooldown_remaining": 0.0
            }
            continue

        if not ItemDatabase.is_hotbar_usable(item_id):
            hotbar_slots[slot_index] = {
                "slot": slot_number,
                "item_id": "",
                "item_type": "",
                "cooldown_remaining": 0.0
            }


func _update_hotbar_cooldowns(delta: float) -> void:
    _initialize_hotbar_slots()

    for slot_index in range(hotbar_slots.size()):
        var slot: Dictionary = hotbar_slots[slot_index]
        var cooldown_remaining: float = float(slot.get("cooldown_remaining", 0.0))

        if cooldown_remaining <= 0.0:
            continue

        cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
        slot["cooldown_remaining"] = cooldown_remaining
        hotbar_slots[slot_index] = slot


func _handle_hotbar_input() -> bool:
    if is_dialogue_active():
        return false

    for slot_number in range(1, HOTBAR_SLOT_COUNT + 1):
        var action_name: String = "hotbar_" + str(slot_number)

        if not InputMap.has_action(action_name):
            continue

        if Input.is_action_just_pressed(action_name):
            use_hotbar_slot(slot_number)
            return true

    return false


func use_hotbar_slot(slot_number: int) -> bool:
    _initialize_hotbar_slots()

    if is_defeated:
        return false

    if slot_number < 1 or slot_number > HOTBAR_SLOT_COUNT:
        return false

    var slot_index: int = slot_number - 1
    var slot: Dictionary = hotbar_slots[slot_index]
    var item_id: String = str(slot.get("item_id", ""))
    var item_type: String = str(slot.get("item_type", ""))
    var cooldown_remaining: float = float(slot.get("cooldown_remaining", 0.0))

    if item_id.strip_edges() == "":
        print("Hotbar slot ", slot_number, " is empty.")
        return false

    if not has_inventory_item(item_id):
        print("Hotbar item missing from inventory: ", item_id)
        clear_hotbar_slot(slot_number)
        return false

    if cooldown_remaining > 0.0:
        print("Hotbar slot ", slot_number, " is on cooldown: ", cooldown_remaining)
        return false

    if item_type == "":
        item_type = ItemDatabase.get_item_type(item_id)

    match item_type:
        "consumable":
            return _use_hotbar_consumable(slot_number, item_id)

        "spell_book":
            return _use_hotbar_spell_book(slot_number, item_id)

        "technique_manual":
            return _use_hotbar_technique_manual(slot_number, item_id)

        _:
            print("Hotbar item type cannot be used yet: ", item_type)
            return false


func _use_hotbar_consumable(slot_number: int, item_id: String) -> bool:
    var effect: String = ItemDatabase.get_consumable_effect(item_id)

    match effect:
        "heal":
            var heal_amount: int = ItemDatabase.get_heal_amount(item_id)

            if heal_amount <= 0:
                print("Consumable has no heal amount: ", item_id)
                return false

            var healed: bool = heal_player(heal_amount)

            if not healed:
                print("Consumable not used. Player is already at full health.")
                return false

        "restore_mana":
            var mana_gain: int = ItemDatabase.get_mana_gain(item_id)

            if mana_gain <= 0:
                print("Consumable has no mana gain: ", item_id)
                return false

            var restored: bool = restore_player_mana(mana_gain)

            if not restored:
                print("Consumable not used. Mana is locked or already full.")
                return false

        _:
            print("Unknown consumable effect: ", effect)
            return false

    if ItemDatabase.is_consumed_on_use(item_id):
        remove_inventory_item(item_id)

    print("Used consumable from hotbar slot ", slot_number, ": ", ItemDatabase.get_item_name(item_id))
    _notify_ui_stats_changed()

    return true


func _use_hotbar_spell_book(slot_number: int, item_id: String) -> bool:
    if character_stats == null:
        return false

    if not character_stats.has_mana_resource:
        print("Cannot cast spell. Mana is not unlocked.")
        return false

    var mana_cost: int = ItemDatabase.get_spell_mana_cost(item_id)

    if not character_stats.can_spend_mana(mana_cost):
        print("Not enough Mana to cast: ", ItemDatabase.get_spell_name(item_id))
        return false

    var cooldown: float = ItemDatabase.get_spell_cooldown(item_id)
    var cast_target: String = ItemDatabase.get_spell_cast_target(item_id)
    var status_effect: String = ItemDatabase.get_spell_status_effect(item_id)
    var status_duration: float = ItemDatabase.get_spell_status_duration(item_id)

    if status_effect.strip_edges() == "":
        print("Spell has no status effect: ", item_id)
        return false

    if status_duration <= 0.0:
        print("Spell has no valid status duration: ", item_id)
        return false

    var spent := character_stats.spend_mana(mana_cost)

    if not spent:
        print("Failed to spend Mana for spell: ", ItemDatabase.get_spell_name(item_id))
        return false

    match cast_target:
        "self":
            _cast_self_buff_spell(item_id, status_effect, status_duration)

        _:
            var spell_range: float = ItemDatabase.get_spell_range(item_id)

            if spell_range <= 0.0:
                print("Spell has no valid range: ", item_id)
                character_stats.restore_mana(mana_cost)
                _notify_ui_stats_changed()
                return false

            var cast_direction := _get_last_direction_vector()

            if cast_direction == Vector2.ZERO:
                cast_direction = Vector2.DOWN

            _spawn_spell_projectile(
                item_id,
                cast_direction,
                spell_range,
                status_effect,
                status_duration
            )

    _set_hotbar_slot_cooldown(slot_number, cooldown)
    _record_spell_school_mastery_cast(item_id)

    print("Cast spell from hotbar slot ", slot_number, ": ", ItemDatabase.get_spell_name(item_id))
    _notify_ui_stats_changed()

    return true


func _record_spell_school_mastery_cast(item_id: String) -> void:
    var spell_school := ItemDatabase.get_spell_school(item_id).strip_edges()

    if spell_school == "":
        return

    if MasteryManager == null:
        return

    if not MasteryManager.has_method("add_school_cast"):
        return

    var added := MasteryManager.add_school_cast(spell_school, 1)

    if added:
        print("School mastery cast added: ", spell_school)


func _cast_self_buff_spell(item_id: String, status_effect: String, status_duration: float) -> void:
    var status_effect_data := {
        StatusEffects.KEY_MOVE_SPEED_MULTIPLIER: ItemDatabase.get_spell_move_speed_multiplier(item_id)
    }

    if status_effect == StatusEffects.STATUS_ROCK_SKIN:
        status_effect_data[StatusEffects.KEY_DEFENSE_BONUS] = ItemDatabase.get_spell_defense_bonus(item_id)

    if status_effect == StatusEffects.STATUS_BURNING:
        status_effect_data[StatusEffects.KEY_DAMAGE_PER_TICK] = ItemDatabase.get_spell_status_damage_per_tick(item_id)
        status_effect_data[StatusEffects.KEY_DAMAGE_TICK_INTERVAL] = ItemDatabase.get_spell_status_tick_interval(item_id)
        status_effect_data[StatusEffects.KEY_DAMAGE_TYPES] = ItemDatabase.get_spell_damage_types(item_id)
        status_effect_data[StatusEffects.KEY_IGNORE_DEFENSE] = true

    apply_status_effect(status_effect, status_duration, status_effect_data)

    print(
        "Self-cast spell applied: ",
        ItemDatabase.get_spell_name(item_id),
        " status: ",
        status_effect,
        " duration: ",
        status_duration
    )


func _spawn_spell_projectile(
        item_id: String,
        cast_direction: Vector2,
        spell_range: float,
        status_effect: String,
        status_duration: float
) -> void:
    var projectile := PlayerSpellProjectile.new()
    projectile.name = "PlayerSpellProjectile"

    var spawn_position := global_position + (cast_direction.normalized() * spell_projectile_spawn_offset)
    projectile.global_position = spawn_position
    projectile.speed = spell_projectile_speed
    projectile.collision_layer = spell_projectile_collision_layer
    projectile.collision_mask = spell_projectile_collision_mask

    var status_effect_data := {
        StatusEffects.KEY_MOVE_SPEED_MULTIPLIER: ItemDatabase.get_spell_move_speed_multiplier(item_id)
    }

    if status_effect == StatusEffects.STATUS_BURNING:
        status_effect_data[StatusEffects.KEY_DAMAGE_PER_TICK] = ItemDatabase.get_spell_status_damage_per_tick(item_id)
        status_effect_data[StatusEffects.KEY_DAMAGE_TICK_INTERVAL] = ItemDatabase.get_spell_status_tick_interval(item_id)
        status_effect_data[StatusEffects.KEY_DAMAGE_TYPES] = ItemDatabase.get_spell_damage_types(item_id)
        status_effect_data[StatusEffects.KEY_IGNORE_DEFENSE] = true

    projectile.setup(
        self,
        cast_direction,
        item_id,
        spell_range,
        status_effect,
        status_duration,
        status_effect_data,
        ItemDatabase.get_spell_damage(item_id),
        ItemDatabase.get_spell_damage_types(item_id)
    )

    var current_scene := get_tree().current_scene

    if current_scene != null:
        current_scene.add_child(projectile)
    else:
        get_parent().add_child(projectile)


func _get_last_direction_vector() -> Vector2:
    match last_direction:
        "up":
            return Vector2.UP
        "down":
            return Vector2.DOWN
        "left":
            return Vector2.LEFT
        "right":
            return Vector2.RIGHT

    return Vector2.DOWN


func _set_hotbar_slot_cooldown(slot_number: int, cooldown: float) -> void:
    _initialize_hotbar_slots()

    if slot_number < 1 or slot_number > HOTBAR_SLOT_COUNT:
        return

    if cooldown <= 0.0:
        return

    var slot_index := slot_number - 1
    var slot: Dictionary = hotbar_slots[slot_index]
    slot["cooldown_remaining"] = cooldown
    hotbar_slots[slot_index] = slot


func _use_hotbar_technique_manual(slot_number: int, item_id: String) -> bool:
    print("Technique manual hotbar use placeholder. Slot: ", slot_number, " Item: ", item_id)
    return false


func heal_player(heal_amount: int) -> bool:
    if heal_amount <= 0:
        return false

    if character_stats.current_health >= character_stats.max_health:
        return false

    character_stats.current_health += heal_amount
    character_stats.current_health = mini(character_stats.current_health, character_stats.max_health)

    print("Player healed: ", heal_amount)
    print("Player HP: ", character_stats.current_health, " / ", character_stats.max_health)

    _notify_ui_stats_changed()

    return true


func restore_player_mana(mana_amount: int) -> bool:
    if mana_amount <= 0:
        return false

    if character_stats == null:
        return false

    var restored: bool = character_stats.restore_mana(mana_amount)

    if restored:
        _notify_ui_stats_changed()

    return restored


func show_dialogue(message: String, speaker_name: String = "System") -> void:
    var clean_message := message.strip_edges()

    if clean_message == "":
        return

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_story_message"):
        game_ui.show_story_message(clean_message, speaker_name)
        return

    print("Dialogue message with no GameUi available: ", clean_message)


func hide_dialogue() -> void:
    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("hide_story_dialogue"):
        game_ui.hide_story_dialogue()
        return


func is_dialogue_active() -> bool:
    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("is_story_dialogue_active"):
        return game_ui.is_story_dialogue_active()

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
        interaction_ui.show_prompt("🖱 Right Mouse / Alt")


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

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("should_block_player_interact"):
        if game_ui.should_block_player_interact():
            return

    if nearby_interactable == null:
        print("No nearby interactable.")
        return

    if nearby_interactable.has_method("interact"):
        nearby_interactable.interact(self)


func _try_ranged_attack() -> void:
    if is_defeated:
        return

    if is_dialogue_active():
        return

    if is_attacking:
        return

    if cooldown_timer > 0.0:
        return

    if character_stats.equipped_ranged_weapon_id.strip_edges() == "":
        print("No ranged weapon equipped.")
        return

    var ranged_weapon_id := character_stats.equipped_ranged_weapon_id

    if ItemDatabase.weapon_requires_ammo(ranged_weapon_id):
        var ammo_item_id := ItemDatabase.get_weapon_ammo_item_id(ranged_weapon_id)
        var ammo_per_shot := ItemDatabase.get_weapon_ammo_per_shot(ranged_weapon_id)

        if ammo_item_id.strip_edges() == "":
            print("Ranged weapon requires ammo but has no ammo item id: ", ranged_weapon_id)
            return

        if not _has_inventory_quantity(ammo_item_id, ammo_per_shot):
            print("No ammo for ranged weapon. Need: ", ItemDatabase.get_item_name(ammo_item_id))
            return

        var removed_ammo := remove_inventory_item(ammo_item_id, ammo_per_shot)

        if not removed_ammo:
            print("Failed to remove ammo for ranged weapon.")
            return

    _fire_ranged_weapon_projectile(ranged_weapon_id)

    cooldown_timer = ranged_attack_cooldown
    print("Player fired ranged weapon: ", ItemDatabase.get_item_name(ranged_weapon_id))


func _fire_ranged_weapon_projectile(ranged_weapon_id: String) -> void:
    var cast_direction := _get_last_direction_vector()

    if cast_direction == Vector2.ZERO:
        cast_direction = Vector2.DOWN

    var projectile := PlayerRangedProjectile.new()
    projectile.name = "PlayerRangedProjectile"

    var spawn_offset := ItemDatabase.get_weapon_projectile_spawn_offset(ranged_weapon_id)
    projectile.global_position = global_position + (cast_direction.normalized() * spawn_offset)
    projectile.collision_layer = ranged_projectile_collision_layer
    projectile.collision_mask = ranged_projectile_collision_mask

    projectile.setup(
        self,
        cast_direction,
        get_ranged_attack_damage(),
        character_stats.get_equipped_ranged_weapon_damage_types(),
        ItemDatabase.get_weapon_projectile_speed(ranged_weapon_id),
        ItemDatabase.get_weapon_projectile_range(ranged_weapon_id),
        ItemDatabase.get_weapon_projectile_hit_radius(ranged_weapon_id),
        ItemDatabase.get_weapon_projectile_color(ranged_weapon_id)
    )

    var current_scene := get_tree().current_scene

    if current_scene != null:
        current_scene.add_child(projectile)
    else:
        get_parent().add_child(projectile)


func _has_inventory_quantity(item_id: String, required_quantity: int) -> bool:
    if inventory_component == null:
        return false

    return inventory_component.has_inventory_quantity(item_id, required_quantity)


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
    attack_damage_timer = attack_damage_window
    weapon_visual_timer = weapon_visual_duration
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

    if attack_damage_timer > 0.0:
        attack_damage_timer -= delta

        if attack_damage_timer <= 0.0:
            attack_damage_timer = 0.0
            _disable_attack_hitbox()

    if weapon_visual_timer > 0.0:
        weapon_visual_timer -= delta

        if weapon_visual_timer <= 0.0:
            weapon_visual_timer = 0.0
            _hide_weapon_sprite()

    if attack_damage_timer <= 0.0 and weapon_visual_timer <= 0.0:
        is_attacking = false


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

    if attack_damage_timer <= 0.0:
        return

    if area == null:
        return

    var target := area.get_parent()

    if target == null:
        return

    if target == self:
        return

    if target.is_in_group("player"):
        return

    if self.is_ancestor_of(target):
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
    take_damage_with_types(incoming_damage, DamageTypes.NONE)


func take_damage_with_types(incoming_damage: int, incoming_damage_types: int = DamageTypes.NONE) -> void:
    if is_defeated:
        return

    if incoming_damage <= 0:
        return

    var final_damage: int = _calculate_incoming_damage(incoming_damage, incoming_damage_types)

    character_stats.current_health -= final_damage
    character_stats.current_health = maxi(character_stats.current_health, 0)

    print("Player took damage: ", final_damage)

    if incoming_damage_types != DamageTypes.NONE:
        print("Incoming damage types: ", DamageTypes.get_damage_type_names(incoming_damage_types))

    print("Player HP: ", character_stats.current_health, " / ", character_stats.max_health)

    _notify_ui_stats_changed()

    if character_stats.current_health <= 0:
        _on_player_defeated()


func _calculate_incoming_damage(incoming_damage: int, incoming_damage_types: int) -> int:
    var final_damage: int = maxi(1, incoming_damage - get_defense())

    if incoming_damage_types == DamageTypes.NONE:
        return final_damage

    if _is_resistant_to_damage_types(incoming_damage_types):
        final_damage = maxi(1, int(floor(float(final_damage) * 0.5)))
        print("Armor resistance applied.")

    if _is_weak_to_damage_types(incoming_damage_types):
        final_damage = maxi(1, int(ceil(float(final_damage) * 1.5)))
        print("Armor weakness applied.")

    return final_damage


func _is_resistant_to_damage_types(incoming_damage_types: int) -> bool:
    if incoming_damage_types == DamageTypes.NONE:
        return false

    var resistance_types := character_stats.get_total_damage_resistances()

    if resistance_types == DamageTypes.NONE:
        return false

    return DamageTypes.damage_types_overlap(incoming_damage_types, resistance_types)


func _is_weak_to_damage_types(incoming_damage_types: int) -> bool:
    if incoming_damage_types == DamageTypes.NONE:
        return false

    var weakness_types := character_stats.get_total_damage_weaknesses()

    if weakness_types == DamageTypes.NONE:
        return false

    return DamageTypes.damage_types_overlap(incoming_damage_types, weakness_types)


func _on_player_defeated() -> void:
    if is_defeated:
        return

    is_defeated = true
    is_respawning = false
    is_attacking = false
    attack_damage_timer = 0.0
    weapon_visual_timer = 0.0
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
        print("Respawn failed. No active respawn point.")
        return

    hide_dialogue()

    var respawn_scene_path: String = RespawnManager.get_respawn_scene_path()
    var respawn_position: Vector2 = RespawnManager.get_respawn_position()
    var current_scene := get_tree().current_scene
    var current_scene_path := ""

    if current_scene != null:
        current_scene_path = current_scene.scene_file_path

    character_stats.current_health = character_stats.max_health

    is_defeated = false
    is_respawning = false
    is_attacking = false
    attack_damage_timer = 0.0
    weapon_visual_timer = 0.0
    cooldown_timer = 0.0
    hit_targets.clear()

    _disable_attack_hitbox()
    _hide_weapon_sprite()

    if animated_sprite != null:
        animated_sprite.visible = true
        animated_sprite.play("idle_" + last_direction)

    if respawn_scene_path.strip_edges() != "" and respawn_scene_path != current_scene_path:
        SceneTransitionManager.store_player_data(self)
        SceneTransitionManager.clear_pending_spawn()
        SceneTransitionManager.set_pending_respawn_position(respawn_position)

        print("Changing scene for cross-map respawn.")
        print("Current scene: ", current_scene_path)
        print("Respawn scene: ", respawn_scene_path)
        print("Respawn position: ", respawn_position)

        get_tree().change_scene_to_file(respawn_scene_path)
        return

    global_position = respawn_position
    velocity = Vector2.ZERO

    show_dialogue("You return to the totem.")
    _notify_ui_stats_changed()

    print("Player respawned at: ", global_position)

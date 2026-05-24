extends Node

var pending_spawn_id: String = ""
var pending_player_data: Dictionary = {}


func set_pending_spawn(spawn_id: String) -> void:
    pending_spawn_id = spawn_id
    print("Pending map spawn set: ", pending_spawn_id)


func has_pending_spawn() -> bool:
    return pending_spawn_id.strip_edges() != ""


func consume_pending_spawn() -> String:
    var spawn_id: String = pending_spawn_id
    pending_spawn_id = ""
    return spawn_id


func clear_pending_spawn() -> void:
    pending_spawn_id = ""


func store_player_data(player: Node) -> void:
    pending_player_data = {}

    if player == null:
        push_warning("Cannot store transition player data. Player is null.")
        return

    if not player.has_method("get_character_stats"):
        push_warning("Cannot store transition player data. Player has no get_character_stats().")
        return

    var stats: CharacterStats = player.get_character_stats()

    if stats == null:
        push_warning("Cannot store transition player data. CharacterStats is null.")
        return

    pending_player_data = {
        "character_stats": _build_character_stats_data(stats),
        "inventory": _get_player_inventory(player),
        "hotbar_slots": _get_player_hotbar_slots(player),
        "currency_data": _get_player_currency_save_data(player)
    }

    print("Stored player transition data.")


func has_pending_player_data() -> bool:
    return not pending_player_data.is_empty()


func apply_player_data(player: Node) -> void:
    if pending_player_data.is_empty():
        return

    if player == null:
        return

    _apply_character_stats(player, pending_player_data)
    _apply_inventory(player, pending_player_data)
    _apply_hotbar_slots(player, pending_player_data)
    _apply_currency_data(player, pending_player_data)

    pending_player_data = {}

    if player.has_method("_notify_ui_stats_changed"):
        player._notify_ui_stats_changed()

    print("Applied player transition data.")


func clear_pending_player_data() -> void:
    pending_player_data = {}


func clear_all_transition_data() -> void:
    clear_pending_spawn()
    clear_pending_player_data()


func _build_character_stats_data(stats: CharacterStats) -> Dictionary:
    return {
        "character_name": stats.character_name,
        "level": stats.level,
        "xp": stats.xp,
        "xp_to_next_level": stats.xp_to_next_level,
        "stat_points": stats.stat_points,
        "ability_points": stats.ability_points,

        "max_health": stats.max_health,
        "current_health": stats.current_health,

        "has_mana_resource": stats.has_mana_resource,
        "max_mana": stats.max_mana,
        "current_mana": stats.current_mana,

        "has_stamina_resource": stats.has_stamina_resource,
        "max_stamina": stats.max_stamina,
        "current_stamina": stats.current_stamina,

        "might": stats.might,
        "agility": stats.agility,
        "toughness": stats.toughness,
        "endurance": stats.endurance,
        "focus": stats.focus,
        "speed": stats.speed,

        "base_attack": stats.base_attack,
        "base_defense": stats.base_defense,

        "equipped_melee_weapon_id": stats.equipped_melee_weapon_id,
        "equipped_melee_weapon_name": stats.equipped_melee_weapon_name,

        "equipped_ranged_weapon_id": stats.equipped_ranged_weapon_id,
        "equipped_ranged_weapon_name": stats.equipped_ranged_weapon_name,

        "equipped_armor_id": stats.equipped_armor_id,
        "equipped_armor_name": stats.equipped_armor_name,

        "equipped_accessory_1_id": stats.equipped_accessory_1_id,
        "equipped_accessory_1_name": stats.equipped_accessory_1_name,

        "equipped_accessory_2_id": stats.equipped_accessory_2_id,
        "equipped_accessory_2_name": stats.equipped_accessory_2_name,

        # Legacy aliases for old transition compatibility/debug readability.
        "equipped_weapon_id": stats.equipped_melee_weapon_id,
        "equipped_weapon_name": stats.equipped_melee_weapon_name,
        "equipped_accessory_id": stats.equipped_accessory_1_id,
        "equipped_accessory_name": stats.equipped_accessory_1_name
    }


func _get_player_inventory(player: Node) -> Array:
    if player.has_method("get_inventory_items"):
        return player.get_inventory_items()

    return []


func _get_player_hotbar_slots(player: Node) -> Array:
    if player.has_method("get_hotbar_slots"):
        return player.get_hotbar_slots()

    return []


func _get_player_currency_save_data(player: Node) -> Dictionary:
    if player.has_method("get_currency_save_data"):
        return player.get_currency_save_data()

    return {
        "currencies": {},
        "discovered_currency_ids": []
    }


func _apply_character_stats(player: Node, data: Dictionary) -> void:
    if not player.has_method("get_character_stats"):
        return

    var stats: CharacterStats = player.get_character_stats()

    if stats == null:
        return

    var stats_data: Dictionary = data.get("character_stats", {})

    if stats_data.is_empty():
        return

    stats.character_name = stats_data.get("character_name", stats.character_name)
    stats.level = int(stats_data.get("level", stats.level))
    stats.xp = int(stats_data.get("xp", stats.xp))
    stats.xp_to_next_level = int(stats_data.get("xp_to_next_level", stats.xp_to_next_level))
    stats.stat_points = int(stats_data.get("stat_points", stats.stat_points))
    stats.ability_points = int(stats_data.get("ability_points", stats.ability_points))

    stats.max_health = int(stats_data.get("max_health", stats.max_health))
    stats.current_health = int(stats_data.get("current_health", stats.current_health))

    stats.has_mana_resource = bool(stats_data.get("has_mana_resource", stats.has_mana_resource))
    stats.max_mana = int(stats_data.get("max_mana", stats.max_mana))
    stats.current_mana = int(stats_data.get("current_mana", stats.current_mana))

    stats.has_stamina_resource = bool(stats_data.get("has_stamina_resource", stats.has_stamina_resource))
    stats.max_stamina = int(stats_data.get("max_stamina", stats.max_stamina))
    stats.current_stamina = int(stats_data.get("current_stamina", stats.current_stamina))

    stats.might = int(stats_data.get("might", stats.might))
    stats.agility = int(stats_data.get("agility", stats.agility))
    stats.toughness = int(stats_data.get("toughness", stats.toughness))
    stats.endurance = int(stats_data.get("endurance", stats.endurance))
    stats.focus = int(stats_data.get("focus", stats.focus))
    stats.speed = int(stats_data.get("speed", stats.speed))

    stats.base_attack = int(stats_data.get("base_attack", stats.base_attack))
    stats.base_defense = int(stats_data.get("base_defense", stats.base_defense))

    stats.equipped_melee_weapon_id = str(stats_data.get(
        "equipped_melee_weapon_id",
        stats_data.get("equipped_weapon_id", stats.equipped_melee_weapon_id)
    ))
    stats.equipped_melee_weapon_name = str(stats_data.get(
        "equipped_melee_weapon_name",
        stats_data.get("equipped_weapon_name", stats.equipped_melee_weapon_name)
    ))

    stats.equipped_ranged_weapon_id = str(stats_data.get("equipped_ranged_weapon_id", stats.equipped_ranged_weapon_id))
    stats.equipped_ranged_weapon_name = str(stats_data.get("equipped_ranged_weapon_name", stats.equipped_ranged_weapon_name))

    stats.equipped_armor_id = str(stats_data.get("equipped_armor_id", stats.equipped_armor_id))
    stats.equipped_armor_name = str(stats_data.get("equipped_armor_name", stats.equipped_armor_name))

    stats.equipped_accessory_1_id = str(stats_data.get(
        "equipped_accessory_1_id",
        stats_data.get("equipped_accessory_id", stats.equipped_accessory_1_id)
    ))
    stats.equipped_accessory_1_name = str(stats_data.get(
        "equipped_accessory_1_name",
        stats_data.get("equipped_accessory_name", stats.equipped_accessory_1_name)
    ))

    stats.equipped_accessory_2_id = str(stats_data.get("equipped_accessory_2_id", stats.equipped_accessory_2_id))
    stats.equipped_accessory_2_name = str(stats_data.get("equipped_accessory_2_name", stats.equipped_accessory_2_name))

    stats.recalculate_derived_stats(false)


func _apply_inventory(player: Node, data: Dictionary) -> void:
    var saved_inventory: Array = data.get("inventory", [])

    if player.has_method("set_inventory_items"):
        player.set_inventory_items(saved_inventory)
        return

    push_warning("Player does not have set_inventory_items(). Inventory was not transferred.")


func _apply_hotbar_slots(player: Node, data: Dictionary) -> void:
    var saved_hotbar_slots: Array = data.get("hotbar_slots", [])

    if saved_hotbar_slots.is_empty():
        return

    if player.has_method("set_hotbar_slots"):
        player.set_hotbar_slots(saved_hotbar_slots)
        return

    push_warning("Player does not have set_hotbar_slots(). Hotbar was not transferred.")


func _apply_currency_data(player: Node, data: Dictionary) -> void:
    var saved_currency_data: Dictionary = data.get("currency_data", {})

    if saved_currency_data.is_empty():
        return

    if player.has_method("set_currency_save_data"):
        player.set_currency_save_data(saved_currency_data)
        return

    push_warning("Player does not have set_currency_save_data(). Currency data was not transferred.")

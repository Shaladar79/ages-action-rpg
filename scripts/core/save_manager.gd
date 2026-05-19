extends Node

const SAVE_FILE_PATH: String = "user://savegame.json"

var pending_loaded_data: Dictionary = {}

var defeated_monster_ids: Array[String] = []
var collected_collectable_ids: Array[String] = []
var broken_breakable_ids: Array[String] = []
var activated_save_point_ids: Array[String] = []
var persistent_object_positions: Dictionary = {}


func has_save_file() -> bool:
    return FileAccess.file_exists(SAVE_FILE_PATH)


func get_save_display_name() -> String:
    if not has_save_file():
        return "No Save Found"

    var save_data := load_save_data()

    if save_data.is_empty():
        return "No Save Found"

    return save_data.get("save_display_name", "Saved Game")


func clear_runtime_world_state() -> void:
    defeated_monster_ids.clear()
    collected_collectable_ids.clear()
    broken_breakable_ids.clear()
    activated_save_point_ids.clear()
    persistent_object_positions.clear()


func mark_monster_defeated(monster_persistent_id: String) -> void:
    if monster_persistent_id.strip_edges() == "":
        return

    if defeated_monster_ids.has(monster_persistent_id):
        return

    defeated_monster_ids.append(monster_persistent_id)
    print("Marked monster defeated: ", monster_persistent_id)


func is_monster_defeated(monster_persistent_id: String) -> bool:
    if monster_persistent_id.strip_edges() == "":
        return false

    return defeated_monster_ids.has(monster_persistent_id)


func mark_collectable_collected(collectable_persistent_id: String) -> void:
    if collectable_persistent_id.strip_edges() == "":
        return

    if collected_collectable_ids.has(collectable_persistent_id):
        return

    collected_collectable_ids.append(collectable_persistent_id)
    print("Marked collectable collected: ", collectable_persistent_id)


func is_collectable_collected(collectable_persistent_id: String) -> bool:
    if collectable_persistent_id.strip_edges() == "":
        return false

    return collected_collectable_ids.has(collectable_persistent_id)


func mark_breakable_broken(breakable_persistent_id: String) -> void:
    if breakable_persistent_id.strip_edges() == "":
        return

    if broken_breakable_ids.has(breakable_persistent_id):
        return

    broken_breakable_ids.append(breakable_persistent_id)
    print("Marked breakable broken: ", breakable_persistent_id)


func is_breakable_broken(breakable_persistent_id: String) -> bool:
    if breakable_persistent_id.strip_edges() == "":
        return false

    return broken_breakable_ids.has(breakable_persistent_id)


func mark_save_point_activated(save_point_id: String) -> void:
    if save_point_id.strip_edges() == "":
        return

    if activated_save_point_ids.has(save_point_id):
        return

    activated_save_point_ids.append(save_point_id)
    print("Marked save point activated: ", save_point_id)


func is_save_point_activated(save_point_id: String) -> bool:
    if save_point_id.strip_edges() == "":
        return false

    return activated_save_point_ids.has(save_point_id)


func set_persistent_object_position(object_id: String, object_position: Vector2) -> void:
    if object_id.strip_edges() == "":
        return

    persistent_object_positions[object_id] = {
        "x": object_position.x,
        "y": object_position.y
    }


func has_persistent_object_position(object_id: String) -> bool:
    if object_id.strip_edges() == "":
        return false

    return persistent_object_positions.has(object_id)


func get_persistent_object_position(object_id: String, fallback_position: Vector2) -> Vector2:
    if not has_persistent_object_position(object_id):
        return fallback_position

    var position_data: Dictionary = persistent_object_positions.get(object_id, {})

    if position_data.is_empty():
        return fallback_position

    return Vector2(
        float(position_data.get("x", fallback_position.x)),
        float(position_data.get("y", fallback_position.y))
    )


func save_game(player: Node) -> bool:
    if player == null:
        push_warning("Cannot save game. Player is null.")
        return false

    if not player.has_method("get_character_stats"):
        push_warning("Cannot save game. Player has no get_character_stats().")
        return false

    var stats: CharacterStats = player.get_character_stats()

    if stats == null:
        push_warning("Cannot save game. CharacterStats is null.")
        return false

    var current_scene := get_tree().current_scene
    var scene_path := ""

    if current_scene != null:
        scene_path = current_scene.scene_file_path

    var age_name := _get_current_age_name(scene_path)
    var map_name := _get_current_map_name(scene_path)
    var character_name := stats.character_name
    var level_text := "Lv" + str(stats.level)

    var save_display_name := "%s - %s - %s - %s" % [
        age_name,
        map_name,
        character_name,
        level_text
    ]

    var save_data := {
        "save_display_name": save_display_name,
        "age_name": age_name,
        "map_name": map_name,
        "scene_path": scene_path,
        "player_position": {
            "x": player.global_position.x,
            "y": player.global_position.y
        },
        "character_stats": _build_character_stats_data(stats),
        "inventory": _get_player_inventory(player),
        "respawn": _build_respawn_data(),
        "world_state": _build_world_state_data()
    }

    var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)

    if file == null:
        push_warning("Could not open save file for writing: " + SAVE_FILE_PATH)
        return false

    file.store_string(JSON.stringify(save_data, "\t"))
    file.close()

    print("Game saved: ", save_display_name)
    print("Save path: ", SAVE_FILE_PATH)

    return true


func load_save_data() -> Dictionary:
    if not has_save_file():
        return {}

    var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)

    if file == null:
        push_warning("Could not open save file for reading: " + SAVE_FILE_PATH)
        return {}

    var json_text := file.get_as_text()
    file.close()

    var parsed = JSON.parse_string(json_text)

    if typeof(parsed) != TYPE_DICTIONARY:
        push_warning("Save file did not contain a valid Dictionary.")
        return {}

    return parsed


func load_game_from_menu() -> void:
    var save_data := load_save_data()

    if save_data.is_empty():
        print("No save data found.")
        return

    pending_loaded_data = save_data
    _apply_world_state_data(save_data)

    var scene_path: String = save_data.get("scene_path", "")

    if scene_path.strip_edges() == "":
        push_warning("Saved scene path is blank.")
        return

    if not ResourceLoader.exists(scene_path):
        push_warning("Saved scene path does not exist: " + scene_path)
        return

    var game_ui := get_node_or_null("/root/GameUi")
    if game_ui != null:
        game_ui.visible = true

    get_tree().change_scene_to_file(scene_path)


func apply_pending_loaded_data(player: Node) -> void:
    if pending_loaded_data.is_empty():
        return

    if player == null:
        return

    _apply_player_position(player, pending_loaded_data)
    _apply_character_stats(player, pending_loaded_data)
    _apply_inventory(player, pending_loaded_data)
    _apply_respawn_data(pending_loaded_data)
    _apply_world_state_data(pending_loaded_data)

    pending_loaded_data = {}

    if player.has_method("_notify_ui_stats_changed"):
        player._notify_ui_stats_changed()

    print("Loaded save applied to player.")


func clear_pending_loaded_data() -> void:
    pending_loaded_data = {}


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

        "equipped_weapon_id": stats.equipped_weapon_id,
        "equipped_weapon_name": stats.equipped_weapon_name,
        "equipped_armor_id": stats.equipped_armor_id,
        "equipped_armor_name": stats.equipped_armor_name,
        "equipped_accessory_id": stats.equipped_accessory_id,
        "equipped_accessory_name": stats.equipped_accessory_name
    }


func _get_player_inventory(player: Node) -> Array:
    if player.has_method("get_inventory_items"):
        return player.get_inventory_items()

    return []


func _build_respawn_data() -> Dictionary:
    return {
        "has_active_respawn_point": RespawnManager.has_active_respawn_point,
        "active_respawn_id": RespawnManager.active_respawn_id,
        "active_scene_path": RespawnManager.active_scene_path,
        "active_respawn_position": {
            "x": RespawnManager.active_respawn_position.x,
            "y": RespawnManager.active_respawn_position.y
        }
    }


func _build_world_state_data() -> Dictionary:
    return {
        "defeated_monster_ids": defeated_monster_ids.duplicate(),
        "collected_collectable_ids": collected_collectable_ids.duplicate(),
        "broken_breakable_ids": broken_breakable_ids.duplicate(),
        "activated_save_point_ids": activated_save_point_ids.duplicate(),
        "persistent_object_positions": persistent_object_positions.duplicate(true)
    }


func _apply_player_position(player: Node, save_data: Dictionary) -> void:
    var position_data: Dictionary = save_data.get("player_position", {})

    if position_data.is_empty():
        return

    var x := float(position_data.get("x", player.global_position.x))
    var y := float(position_data.get("y", player.global_position.y))

    player.global_position = Vector2(x, y)


func _apply_character_stats(player: Node, save_data: Dictionary) -> void:
    if not player.has_method("get_character_stats"):
        return

    var stats: CharacterStats = player.get_character_stats()

    if stats == null:
        return

    var stats_data: Dictionary = save_data.get("character_stats", {})

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

    stats.equipped_weapon_id = stats_data.get("equipped_weapon_id", stats.equipped_weapon_id)
    stats.equipped_weapon_name = stats_data.get("equipped_weapon_name", stats.equipped_weapon_name)
    stats.equipped_armor_id = stats_data.get("equipped_armor_id", stats.equipped_armor_id)
    stats.equipped_armor_name = stats_data.get("equipped_armor_name", stats.equipped_armor_name)
    stats.equipped_accessory_id = stats_data.get("equipped_accessory_id", stats.equipped_accessory_id)
    stats.equipped_accessory_name = stats_data.get("equipped_accessory_name", stats.equipped_accessory_name)

    stats.recalculate_derived_stats(false)


func _apply_inventory(player: Node, save_data: Dictionary) -> void:
    var saved_inventory: Array = save_data.get("inventory", [])

    if player.has_method("set_inventory_items"):
        player.set_inventory_items(saved_inventory)
        return

    push_warning("Player does not have set_inventory_items(). Inventory was not loaded.")


func _apply_respawn_data(save_data: Dictionary) -> void:
    var respawn_data: Dictionary = save_data.get("respawn", {})

    if respawn_data.is_empty():
        return

    if not bool(respawn_data.get("has_active_respawn_point", false)):
        RespawnManager.clear_respawn_point()
        return

    var pos_data: Dictionary = respawn_data.get("active_respawn_position", {})
    var pos := Vector2(
        float(pos_data.get("x", 0.0)),
        float(pos_data.get("y", 0.0))
    )

    RespawnManager.set_respawn_point(
        respawn_data.get("active_respawn_id", ""),
        respawn_data.get("active_scene_path", ""),
        pos
    )


func _apply_world_state_data(save_data: Dictionary) -> void:
    clear_runtime_world_state()

    var world_state: Dictionary = save_data.get("world_state", {})

    if world_state.is_empty():
        return

    var saved_defeated_monsters: Array = world_state.get("defeated_monster_ids", [])
    for monster_id in saved_defeated_monsters:
        _append_unique_string(defeated_monster_ids, monster_id)

    var saved_collected_collectables: Array = world_state.get("collected_collectable_ids", [])
    for collectable_id in saved_collected_collectables:
        _append_unique_string(collected_collectable_ids, collectable_id)

    var saved_broken_breakables: Array = world_state.get("broken_breakable_ids", [])
    for breakable_id in saved_broken_breakables:
        _append_unique_string(broken_breakable_ids, breakable_id)

    var saved_activated_save_points: Array = world_state.get("activated_save_point_ids", [])
    for save_point_id in saved_activated_save_points:
        _append_unique_string(activated_save_point_ids, save_point_id)

    var saved_positions: Dictionary = world_state.get("persistent_object_positions", {})
    persistent_object_positions = saved_positions.duplicate(true)

    print("Loaded defeated monster count: ", defeated_monster_ids.size())
    print("Loaded collected collectable count: ", collected_collectable_ids.size())
    print("Loaded broken breakable count: ", broken_breakable_ids.size())
    print("Loaded activated save point count: ", activated_save_point_ids.size())
    print("Loaded persistent object position count: ", persistent_object_positions.size())


func _append_unique_string(target_array: Array[String], value) -> void:
    var id_string := str(value)

    if id_string.strip_edges() == "":
        return

    if target_array.has(id_string):
        return

    target_array.append(id_string)


func _get_current_age_name(scene_path: String) -> String:
    var settings := _get_current_map_settings()

    if settings != null:
        return settings.age_name

    return "Stone Age"


func _get_current_map_name(scene_path: String) -> String:
    var settings := _get_current_map_settings()

    if settings != null:
        return settings.map_name

    return _get_map_name_from_scene_path(scene_path)


func _get_current_map_settings() -> MapSettings:
    var current_scene := get_tree().current_scene

    if current_scene == null:
        return null

    return current_scene.find_child("MapSettings", true, false) as MapSettings


func _get_map_name_from_scene_path(scene_path: String) -> String:
    if scene_path.strip_edges() == "":
        return "Unknown Map"

    var file_name := scene_path.get_file().get_basename()
    return file_name.capitalize()

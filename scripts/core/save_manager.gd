extends Node

const SAVE_FILE_PATH: String = "user://savegame.json" # Legacy single-save path.

const SAVE_DIR_PATH: String = "user://saves"
const SAVE_INDEX_PATH: String = SAVE_DIR_PATH + "/save_index.json"
const SAVE_FILE_PREFIX: String = "save_"
const SAVE_FILE_EXTENSION: String = ".json"
const LEGACY_SAVE_FILE_ID: String = "__legacy__"

var pending_loaded_data: Dictionary = {}

var defeated_monster_ids: Array[String] = []
var collected_collectable_ids: Array[String] = []
var broken_breakable_ids: Array[String] = []
var activated_save_point_ids: Array[String] = []
var persistent_object_positions: Dictionary = {}

# Story flags are simple true/false progress markers.
# Examples:
# intro_spirit_met
# push_rock_lesson_seen
# healing_tonic_collected
# intro_boss_defeated
var story_flags: Dictionary = {}


func has_save_file() -> bool:
    if not get_save_slot_rows().is_empty():
        return true

    return FileAccess.file_exists(SAVE_FILE_PATH)


func get_save_display_name() -> String:
    var rows := get_save_slot_rows()

    if rows.is_empty():
        return "No Save Found"

    var first_row: Dictionary = rows[0]
    return str(first_row.get("display_name", "Saved Game"))

func get_save_slot_rows() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []

    var save_index := _load_save_index()
    var slots: Array = save_index.get("slots", [])

    for slot in slots:
        if typeof(slot) != TYPE_DICTIONARY:
            continue

        var file_id := str(slot.get("file_id", "")).strip_edges()

        if file_id == "":
            continue

        var save_path := _get_save_file_path(file_id)

        if not FileAccess.file_exists(save_path):
            continue

        rows.append({
            "file_id": file_id,
            "display_name": str(slot.get("display_name", "Saved Game")),
            "map_name": str(slot.get("map_name", "")),
            "character_name": str(slot.get("character_name", "")),
            "level": int(slot.get("level", 0)),
            "saved_at": str(slot.get("saved_at", "")),
            "scene_path": str(slot.get("scene_path", ""))
        })

    if rows.is_empty() and FileAccess.file_exists(SAVE_FILE_PATH):
        var legacy_data := load_save_data(LEGACY_SAVE_FILE_ID)

        if not legacy_data.is_empty():
            rows.append({
                "file_id": LEGACY_SAVE_FILE_ID,
                "display_name": str(legacy_data.get("save_display_name", "Legacy Save")),
                "map_name": str(legacy_data.get("map_name", "")),
                "character_name": str(legacy_data.get("character_stats", {}).get("character_name", "")),
                "level": int(legacy_data.get("character_stats", {}).get("level", 0)),
                "saved_at": str(legacy_data.get("saved_at", "")),
                "scene_path": str(legacy_data.get("scene_path", ""))
            })

    return rows

func delete_save_file(save_file_id: String) -> bool:
    var clean_file_id := save_file_id.strip_edges()

    if clean_file_id == "":
        return false

    if clean_file_id == LEGACY_SAVE_FILE_ID:
        if not FileAccess.file_exists(SAVE_FILE_PATH):
            return false

        var legacy_result := DirAccess.remove_absolute(SAVE_FILE_PATH)

        if legacy_result != OK:
            push_warning("Could not delete legacy save file: " + SAVE_FILE_PATH)
            return false

        print("Deleted legacy save file.")
        return true

    var save_file_path := _get_save_file_path(clean_file_id)

    if not FileAccess.file_exists(save_file_path):
        _remove_save_index_entry(clean_file_id)
        print("Save file was missing, removed stale index entry: ", clean_file_id)
        return true

    var result := DirAccess.remove_absolute(save_file_path)

    if result != OK:
        push_warning("Could not delete save file: " + save_file_path)
        return false

    _remove_save_index_entry(clean_file_id)

    print("Deleted save file: ", clean_file_id)
    return true

func get_latest_save_file_id() -> String:
    var rows := get_save_slot_rows()

    if rows.is_empty():
        return ""

    var first_row: Dictionary = rows[0]
    return str(first_row.get("file_id", ""))


func save_game_named(player: Node, save_name: String) -> bool:
    return save_game(player, save_name)

func clear_runtime_world_state() -> void:
    defeated_monster_ids.clear()
    collected_collectable_ids.clear()
    broken_breakable_ids.clear()
    activated_save_point_ids.clear()
    persistent_object_positions.clear()
    story_flags.clear()

    if FactionManager != null and FactionManager.has_method("clear_faction_state"):
        FactionManager.clear_faction_state()
    
    if MasteryManager != null and MasteryManager.has_method("clear_mastery_state"):
        MasteryManager.clear_mastery_state()

func _get_mastery_save_data() -> Dictionary:
    if MasteryManager == null:
        return {}

    if MasteryManager.has_method("get_mastery_save_data"):
        return MasteryManager.get_mastery_save_data()

    return {}


func _apply_mastery_data(save_data: Dictionary) -> void:
    var saved_mastery_data: Dictionary = save_data.get("mastery_data", {})

    if MasteryManager == null:
        return

    if MasteryManager.has_method("load_mastery_save_data"):
        MasteryManager.load_mastery_save_data(saved_mastery_data)
        return

    push_warning("MasteryManager does not have load_mastery_save_data(). Mastery data was not loaded.")

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


func set_story_flag(flag_name: String, value: bool = true) -> void:
    var clean_flag_name := flag_name.strip_edges()

    if clean_flag_name == "":
        return

    story_flags[clean_flag_name] = value
    print("Story flag set: ", clean_flag_name, " = ", value)


func is_story_flag_set(flag_name: String) -> bool:
    var clean_flag_name := flag_name.strip_edges()

    if clean_flag_name == "":
        return false

    return bool(story_flags.get(clean_flag_name, false))


func clear_story_flag(flag_name: String) -> void:
    var clean_flag_name := flag_name.strip_edges()

    if clean_flag_name == "":
        return

    if not story_flags.has(clean_flag_name):
        return

    story_flags.erase(clean_flag_name)
    print("Story flag cleared: ", clean_flag_name)


func get_story_flags() -> Dictionary:
    return story_flags.duplicate(true)


func load_story_flags(saved_story_flags: Dictionary) -> void:
    story_flags.clear()

    for flag_name in saved_story_flags.keys():
        var clean_flag_name := str(flag_name).strip_edges()

        if clean_flag_name == "":
            continue

        story_flags[clean_flag_name] = bool(saved_story_flags.get(flag_name, false))


func clear_story_flags() -> void:
    story_flags.clear()


# Short aliases for later story/dialogue scripts.
func set_flag(flag_name: String, value: bool = true) -> void:
    set_story_flag(flag_name, value)


func is_flag_set(flag_name: String) -> bool:
    return is_story_flag_set(flag_name)


func clear_flag(flag_name: String) -> void:
    clear_story_flag(flag_name)


func save_game(player: Node, custom_save_name: String = "") -> bool:
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

    var generated_save_display_name := "%s - %s - %s - %s" % [
        age_name,
        map_name,
        character_name,
        level_text
    ]

    var clean_custom_save_name := custom_save_name.strip_edges()
    var save_display_name := generated_save_display_name

    if clean_custom_save_name != "":
        save_display_name = clean_custom_save_name

    var existing_file_id := _find_save_file_id_by_display_name(save_display_name)
    var save_file_id := existing_file_id

    if save_file_id == "":
        save_file_id = _get_next_save_file_id()

    var saved_at := _get_current_save_timestamp()

    var save_data := {
        "save_file_id": save_file_id,
        "saved_at": saved_at,
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
        "hotbar_slots": _get_player_hotbar_slots(player),
        "currency_data": _get_player_currency_save_data(player),
        "faction_data": _get_faction_save_data(),
        "mastery_data": _get_mastery_save_data(),
        "respawn": _build_respawn_data(),
        "quest_data": _get_quest_save_data(),
        "world_state": _build_world_state_data()
    }

    if not _ensure_save_directory_exists():
        push_warning("Could not create save directory: " + SAVE_DIR_PATH)
        return false

    var save_file_path := _get_save_file_path(save_file_id)
    var file := FileAccess.open(save_file_path, FileAccess.WRITE)

    if file == null:
        push_warning("Could not open save file for writing: " + save_file_path)
        return false

    file.store_string(JSON.stringify(save_data, "\t"))
    file.close()

    _upsert_save_index_entry(save_data)

    print("Game saved: ", save_display_name)
    print("Save path: ", save_file_path)

    return true


func load_save_data(save_file_id: String = "") -> Dictionary:
    var clean_file_id := save_file_id.strip_edges()

    if clean_file_id == "":
        clean_file_id = get_latest_save_file_id()

    var save_path := ""

    if clean_file_id == LEGACY_SAVE_FILE_ID:
        save_path = SAVE_FILE_PATH
    elif clean_file_id != "":
        save_path = _get_save_file_path(clean_file_id)
    else:
        save_path = SAVE_FILE_PATH

    if not FileAccess.file_exists(save_path):
        return {}

    var file := FileAccess.open(save_path, FileAccess.READ)

    if file == null:
        push_warning("Could not open save file for reading: " + save_path)
        return {}

    var json_text := file.get_as_text()
    file.close()

    var parsed = JSON.parse_string(json_text)

    if typeof(parsed) != TYPE_DICTIONARY:
        push_warning("Save file did not contain a valid Dictionary.")
        return {}

    return parsed


func load_game_from_menu(save_file_id: String = "") -> void:
    var save_data := load_save_data(save_file_id)

    if save_data.is_empty():
        print("No save data found.")
        return

    pending_loaded_data = save_data
    _apply_world_state_data(save_data)
    _apply_quest_data(save_data)
    _apply_faction_data(save_data)
    _apply_mastery_data(save_data)

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
    _apply_hotbar_slots(player, pending_loaded_data)
    _apply_currency_data(player, pending_loaded_data)
    _apply_faction_data(pending_loaded_data)
    _apply_mastery_data(pending_loaded_data)
    _apply_respawn_data(pending_loaded_data)
    _apply_world_state_data(pending_loaded_data)
    _apply_quest_data(pending_loaded_data)

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

        # Legacy aliases for old save compatibility/debug readability.
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


func _apply_currency_data(player: Node, save_data: Dictionary) -> void:
    var saved_currency_data: Dictionary = save_data.get("currency_data", {})

    if saved_currency_data.is_empty():
        return

    if player.has_method("set_currency_save_data"):
        player.set_currency_save_data(saved_currency_data)
        return

    push_warning("Player does not have set_currency_save_data(). Currency data was not loaded.")

func _get_faction_save_data() -> Dictionary:
    if FactionManager == null:
        return {}

    if FactionManager.has_method("get_faction_save_data"):
        return FactionManager.get_faction_save_data()

    return {}


func _apply_faction_data(save_data: Dictionary) -> void:
    var saved_faction_data: Dictionary = save_data.get("faction_data", {})

    if FactionManager == null:
        return

    if FactionManager.has_method("load_faction_save_data"):
        FactionManager.load_faction_save_data(saved_faction_data)
        return

    push_warning("FactionManager does not have load_faction_save_data(). Faction data was not loaded.")

func _get_quest_save_data() -> Dictionary:
    if QuestManager == null:
        return {}

    if QuestManager.has_method("get_quest_save_data"):
        return QuestManager.get_quest_save_data()

    return {}


func _apply_quest_data(save_data: Dictionary) -> void:
    var saved_quest_data: Dictionary = save_data.get("quest_data", {})

    if QuestManager == null:
        return

    if QuestManager.has_method("load_quest_save_data"):
        QuestManager.load_quest_save_data(saved_quest_data)
        return

    push_warning("QuestManager does not have load_quest_save_data(). Quest data was not loaded.")


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
        "persistent_object_positions": persistent_object_positions.duplicate(true),
        "story_flags": story_flags.duplicate(true)
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


func _apply_inventory(player: Node, save_data: Dictionary) -> void:
    var saved_inventory: Array = save_data.get("inventory", [])

    if player.has_method("set_inventory_items"):
        player.set_inventory_items(saved_inventory)
        return

    push_warning("Player does not have set_inventory_items(). Inventory was not loaded.")


func _apply_hotbar_slots(player: Node, save_data: Dictionary) -> void:
    var saved_hotbar_slots: Array = save_data.get("hotbar_slots", [])

    if saved_hotbar_slots.is_empty():
        return

    if player.has_method("set_hotbar_slots"):
        player.set_hotbar_slots(saved_hotbar_slots)
        return

    push_warning("Player does not have set_hotbar_slots(). Hotbar was not loaded.")


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

    var saved_story_flags: Dictionary = world_state.get("story_flags", {})
    load_story_flags(saved_story_flags)

    print("Loaded defeated monster count: ", defeated_monster_ids.size())
    print("Loaded collected collectable count: ", collected_collectable_ids.size())
    print("Loaded broken breakable count: ", broken_breakable_ids.size())
    print("Loaded activated save point count: ", activated_save_point_ids.size())
    print("Loaded persistent object position count: ", persistent_object_positions.size())
    print("Loaded story flag count: ", story_flags.size())


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

func _ensure_save_directory_exists() -> bool:
    var dir := DirAccess.open("user://")

    if dir == null:
        return false

    if dir.dir_exists("saves"):
        return true

    var result := dir.make_dir("saves")

    return result == OK or result == ERR_ALREADY_EXISTS


func _get_save_file_path(save_file_id: String) -> String:
    var clean_file_id := save_file_id.strip_edges()

    if clean_file_id == "":
        clean_file_id = _get_next_save_file_id()

    return SAVE_DIR_PATH + "/" + clean_file_id + SAVE_FILE_EXTENSION


func _load_save_index() -> Dictionary:
    if not FileAccess.file_exists(SAVE_INDEX_PATH):
        return {
            "slots": []
        }

    var file := FileAccess.open(SAVE_INDEX_PATH, FileAccess.READ)

    if file == null:
        return {
            "slots": []
        }

    var json_text := file.get_as_text()
    file.close()

    var parsed = JSON.parse_string(json_text)

    if typeof(parsed) != TYPE_DICTIONARY:
        return {
            "slots": []
        }

    if not parsed.has("slots"):
        parsed["slots"] = []

    return parsed


func _save_save_index(save_index: Dictionary) -> bool:
    if not _ensure_save_directory_exists():
        return false

    var file := FileAccess.open(SAVE_INDEX_PATH, FileAccess.WRITE)

    if file == null:
        push_warning("Could not write save index: " + SAVE_INDEX_PATH)
        return false

    file.store_string(JSON.stringify(save_index, "\t"))
    file.close()

    return true


func _upsert_save_index_entry(save_data: Dictionary) -> void:
    var save_file_id := str(save_data.get("save_file_id", "")).strip_edges()

    if save_file_id == "":
        return

    var save_index := _load_save_index()
    var slots: Array = save_index.get("slots", [])

    var new_entry := {
        "file_id": save_file_id,
        "display_name": str(save_data.get("save_display_name", "Saved Game")),
        "age_name": str(save_data.get("age_name", "")),
        "map_name": str(save_data.get("map_name", "")),
        "scene_path": str(save_data.get("scene_path", "")),
        "character_name": str(save_data.get("character_stats", {}).get("character_name", "")),
        "level": int(save_data.get("character_stats", {}).get("level", 0)),
        "saved_at": str(save_data.get("saved_at", ""))
    }

    var replaced := false

    for index in range(slots.size()):
        if typeof(slots[index]) != TYPE_DICTIONARY:
            continue

        var existing_file_id := str(slots[index].get("file_id", ""))

        if existing_file_id == save_file_id:
            slots[index] = new_entry
            replaced = true
            break

    if not replaced:
        slots.push_front(new_entry)

    save_index["slots"] = slots
    _save_save_index(save_index)

func _remove_save_index_entry(save_file_id: String) -> void:
    var clean_file_id := save_file_id.strip_edges()

    if clean_file_id == "":
        return

    var save_index := _load_save_index()
    var slots: Array = save_index.get("slots", [])
    var updated_slots: Array = []

    for slot in slots:
        if typeof(slot) != TYPE_DICTIONARY:
            continue

        var existing_file_id := str(slot.get("file_id", "")).strip_edges()

        if existing_file_id == clean_file_id:
            continue

        updated_slots.append(slot)

    save_index["slots"] = updated_slots
    _save_save_index(save_index)
    
func _find_save_file_id_by_display_name(display_name: String) -> String:
    var clean_display_name := display_name.strip_edges()

    if clean_display_name == "":
        return ""

    var save_index := _load_save_index()
    var slots: Array = save_index.get("slots", [])

    for slot in slots:
        if typeof(slot) != TYPE_DICTIONARY:
            continue

        var existing_display_name := str(slot.get("display_name", "")).strip_edges()

        if existing_display_name == clean_display_name:
            return str(slot.get("file_id", ""))

    return ""


func _get_next_save_file_id() -> String:
    var save_index := _load_save_index()
    var slots: Array = save_index.get("slots", [])

    var highest_number := 0

    for slot in slots:
        if typeof(slot) != TYPE_DICTIONARY:
            continue

        var file_id := str(slot.get("file_id", ""))

        if not file_id.begins_with(SAVE_FILE_PREFIX):
            continue

        var number_text := file_id.replace(SAVE_FILE_PREFIX, "")

        if not number_text.is_valid_int():
            continue

        highest_number = maxi(highest_number, int(number_text))

    return SAVE_FILE_PREFIX + "%03d" % [highest_number + 1]


func _get_current_save_timestamp() -> String:
    var datetime := Time.get_datetime_dict_from_system()

    return "%04d-%02d-%02d %02d:%02d:%02d" % [
        int(datetime.get("year", 0)),
        int(datetime.get("month", 0)),
        int(datetime.get("day", 0)),
        int(datetime.get("hour", 0)),
        int(datetime.get("minute", 0)),
        int(datetime.get("second", 0))
    ]

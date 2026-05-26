extends Node

const MIN_MASTERY_LEVEL: int = 0
const MIN_PROGRESS: int = 0

var weapon_mastery: Dictionary = {}
var school_mastery: Dictionary = {}


func _ready() -> void:
    _ensure_default_masteries()


func _ensure_default_masteries() -> void:
    for mastery_id in MasteryDatabase.get_weapon_mastery_ids():
        if not weapon_mastery.has(mastery_id):
            weapon_mastery[mastery_id] = _build_default_mastery_data()

    for mastery_id in MasteryDatabase.get_school_mastery_ids():
        if not school_mastery.has(mastery_id):
            school_mastery[mastery_id] = _build_default_mastery_data()


func _build_default_mastery_data() -> Dictionary:
    return {
        "level": 0,
        "progress": 0,
        "total_progress": 0
    }


func add_weapon_kill(mastery_id: String, amount: int = 1) -> bool:
    var clean_mastery_id := mastery_id.strip_edges()

    if clean_mastery_id == "":
        return false

    if amount <= 0:
        return false

    if not MasteryDatabase.weapon_mastery_exists(clean_mastery_id):
        push_warning("Cannot add weapon mastery kill. Unknown weapon mastery: " + clean_mastery_id)
        return false

    _ensure_default_masteries()

    var mastery_data: Dictionary = weapon_mastery.get(clean_mastery_id, _build_default_mastery_data())
    _add_progress_to_mastery(
        mastery_data,
        MasteryDatabase.MASTERY_TYPE_WEAPON,
        clean_mastery_id,
        amount
    )

    weapon_mastery[clean_mastery_id] = mastery_data
    _notify_mastery_ui_changed()

    return true


func add_school_cast(mastery_id: String, amount: int = 1) -> bool:
    var clean_mastery_id := mastery_id.strip_edges()

    if clean_mastery_id == "":
        return false

    if amount <= 0:
        return false

    if not MasteryDatabase.school_mastery_exists(clean_mastery_id):
        push_warning("Cannot add school mastery cast. Unknown school mastery: " + clean_mastery_id)
        return false

    _ensure_default_masteries()

    var mastery_data: Dictionary = school_mastery.get(clean_mastery_id, _build_default_mastery_data())
    _add_progress_to_mastery(
        mastery_data,
        MasteryDatabase.MASTERY_TYPE_SCHOOL,
        clean_mastery_id,
        amount
    )

    school_mastery[clean_mastery_id] = mastery_data
    _notify_mastery_ui_changed()

    return true


func _add_progress_to_mastery(
    mastery_data: Dictionary,
    mastery_type: String,
    mastery_id: String,
    amount: int
) -> void:
    var current_level: int = int(mastery_data.get("level", 0))
    var current_progress: int = int(mastery_data.get("progress", 0))
    var total_progress: int = int(mastery_data.get("total_progress", 0))

    current_level = clampi(current_level, MIN_MASTERY_LEVEL, MasteryDatabase.MAX_MASTERY_LEVEL)

    if current_level >= MasteryDatabase.MAX_MASTERY_LEVEL:
        mastery_data["level"] = MasteryDatabase.MAX_MASTERY_LEVEL
        mastery_data["progress"] = 0
        mastery_data["total_progress"] = total_progress + amount
        return

    current_progress += amount
    total_progress += amount

    while current_level < MasteryDatabase.MAX_MASTERY_LEVEL:
        var required_progress := MasteryDatabase.get_required_progress_for_next_level(
            mastery_type,
            current_level
        )

        if required_progress <= 0:
            break

        if current_progress < required_progress:
            break

        current_progress -= required_progress
        current_level += 1

        _on_mastery_level_gained(mastery_type, mastery_id, current_level)

    if current_level >= MasteryDatabase.MAX_MASTERY_LEVEL:
        current_progress = 0

    mastery_data["level"] = current_level
    mastery_data["progress"] = maxi(MIN_PROGRESS, current_progress)
    mastery_data["total_progress"] = maxi(MIN_PROGRESS, total_progress)


func _on_mastery_level_gained(mastery_type: String, mastery_id: String, new_level: int) -> void:
    var mastery_name := MasteryDatabase.get_mastery_display_name(mastery_type, mastery_id)

    print(mastery_name, " increased to level ", new_level)

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_reward_notification"):
        game_ui.show_reward_notification(mastery_name + " reached level " + str(new_level))


func get_weapon_mastery_level(mastery_id: String) -> int:
    var mastery_data := get_weapon_mastery_data(mastery_id)
    return int(mastery_data.get("level", 0))


func get_school_mastery_level(mastery_id: String) -> int:
    var mastery_data := get_school_mastery_data(mastery_id)
    return int(mastery_data.get("level", 0))


func get_weapon_damage_multiplier(mastery_id: String) -> float:
    return MasteryDatabase.get_weapon_damage_multiplier(
        mastery_id,
        get_weapon_mastery_level(mastery_id)
    )


func has_weapon_technique_unlocked(mastery_id: String) -> bool:
    return MasteryDatabase.has_weapon_technique_unlocked(
        mastery_id,
        get_weapon_mastery_level(mastery_id)
    )


func get_weapon_mastery_data(mastery_id: String) -> Dictionary:
    var clean_mastery_id := mastery_id.strip_edges()

    if clean_mastery_id == "":
        return _build_default_mastery_data()

    if not MasteryDatabase.weapon_mastery_exists(clean_mastery_id):
        return _build_default_mastery_data()

    _ensure_default_masteries()

    return weapon_mastery.get(clean_mastery_id, _build_default_mastery_data()).duplicate(true)


func get_school_mastery_data(mastery_id: String) -> Dictionary:
    var clean_mastery_id := mastery_id.strip_edges()

    if clean_mastery_id == "":
        return _build_default_mastery_data()

    if not MasteryDatabase.school_mastery_exists(clean_mastery_id):
        return _build_default_mastery_data()

    _ensure_default_masteries()

    return school_mastery.get(clean_mastery_id, _build_default_mastery_data()).duplicate(true)


func get_weapon_mastery_rows() -> Array[Dictionary]:
    _ensure_default_masteries()

    var rows: Array[Dictionary] = []

    for mastery_id in MasteryDatabase.get_weapon_mastery_ids():
        var mastery_data: Dictionary = weapon_mastery.get(mastery_id, _build_default_mastery_data())
        rows.append(_build_mastery_row(MasteryDatabase.MASTERY_TYPE_WEAPON, mastery_id, mastery_data))

    return rows


func get_school_mastery_rows() -> Array[Dictionary]:
    _ensure_default_masteries()

    var rows: Array[Dictionary] = []

    for mastery_id in MasteryDatabase.get_school_mastery_ids():
        var mastery_data: Dictionary = school_mastery.get(mastery_id, _build_default_mastery_data())
        rows.append(_build_mastery_row(MasteryDatabase.MASTERY_TYPE_SCHOOL, mastery_id, mastery_data))

    return rows


func get_all_mastery_rows() -> Dictionary:
    return {
        "weapon_mastery": get_weapon_mastery_rows(),
        "school_mastery": get_school_mastery_rows()
    }

func get_mastery_row(mastery_type: String, mastery_id: String) -> Dictionary:
    var clean_mastery_type := mastery_type.strip_edges()
    var clean_mastery_id := mastery_id.strip_edges()

    if clean_mastery_type == "" or clean_mastery_id == "":
        return {}

    match clean_mastery_type:
        MasteryDatabase.MASTERY_TYPE_WEAPON:
            if not MasteryDatabase.weapon_mastery_exists(clean_mastery_id):
                return {}

            return _build_mastery_row(
                MasteryDatabase.MASTERY_TYPE_WEAPON,
                clean_mastery_id,
                get_weapon_mastery_data(clean_mastery_id)
            )

        MasteryDatabase.MASTERY_TYPE_SCHOOL:
            if not MasteryDatabase.school_mastery_exists(clean_mastery_id):
                return {}

            return _build_mastery_row(
                MasteryDatabase.MASTERY_TYPE_SCHOOL,
                clean_mastery_id,
                get_school_mastery_data(clean_mastery_id)
            )

        _:
            return {}

func _build_mastery_row(mastery_type: String, mastery_id: String, mastery_data: Dictionary) -> Dictionary:
    var level: int = int(mastery_data.get("level", 0))
    var progress: int = int(mastery_data.get("progress", 0))
    var total_progress: int = int(mastery_data.get("total_progress", 0))
    var required_progress := MasteryDatabase.get_required_progress_for_next_level(mastery_type, level)

    return {
        "type": mastery_type,
        "id": mastery_id,
        "name": MasteryDatabase.get_mastery_display_name(mastery_type, mastery_id),
        "description": MasteryDatabase.get_mastery_description(mastery_type, mastery_id),
        "level": level,
        "progress": progress,
        "required_progress": required_progress,
        "total_progress": total_progress
    }


func get_mastery_save_data() -> Dictionary:
    _ensure_default_masteries()

    return {
        "weapon_mastery": weapon_mastery.duplicate(true),
        "school_mastery": school_mastery.duplicate(true)
    }


func load_mastery_save_data(saved_mastery_data: Dictionary) -> void:
    weapon_mastery.clear()
    school_mastery.clear()
    _ensure_default_masteries()

    if saved_mastery_data.is_empty():
        _notify_mastery_ui_changed()
        print("MasteryManager loaded no saved mastery data.")
        return

    var saved_weapon_mastery: Dictionary = saved_mastery_data.get("weapon_mastery", {})
    var saved_school_mastery: Dictionary = saved_mastery_data.get("school_mastery", {})

    _load_mastery_dictionary(
        saved_weapon_mastery,
        weapon_mastery,
        MasteryDatabase.MASTERY_TYPE_WEAPON
    )

    _load_mastery_dictionary(
        saved_school_mastery,
        school_mastery,
        MasteryDatabase.MASTERY_TYPE_SCHOOL
    )

    _ensure_default_masteries()
    _notify_mastery_ui_changed()

    print("MasteryManager loaded weapon mastery count: ", weapon_mastery.size())
    print("MasteryManager loaded school mastery count: ", school_mastery.size())


func _load_mastery_dictionary(
    saved_data: Dictionary,
    target_data: Dictionary,
    mastery_type: String
) -> void:
    for mastery_id in saved_data.keys():
        var clean_mastery_id := str(mastery_id).strip_edges()

        if clean_mastery_id == "":
            continue

        var mastery_exists := false

        match mastery_type:
            MasteryDatabase.MASTERY_TYPE_WEAPON:
                mastery_exists = MasteryDatabase.weapon_mastery_exists(clean_mastery_id)

            MasteryDatabase.MASTERY_TYPE_SCHOOL:
                mastery_exists = MasteryDatabase.school_mastery_exists(clean_mastery_id)

        if not mastery_exists:
            continue

        var saved_mastery_entry = saved_data.get(mastery_id, {})

        if typeof(saved_mastery_entry) != TYPE_DICTIONARY:
            continue

        var saved_level: int = clampi(
            int(saved_mastery_entry.get("level", 0)),
            MIN_MASTERY_LEVEL,
            MasteryDatabase.MAX_MASTERY_LEVEL
        )

        var saved_progress: int = maxi(
            MIN_PROGRESS,
            int(saved_mastery_entry.get("progress", 0))
        )

        var saved_total_progress: int = maxi(
            MIN_PROGRESS,
            int(saved_mastery_entry.get("total_progress", 0))
        )

        if saved_level >= MasteryDatabase.MAX_MASTERY_LEVEL:
            saved_progress = 0

        target_data[clean_mastery_id] = {
            "level": saved_level,
            "progress": saved_progress,
            "total_progress": saved_total_progress
        }


func clear_mastery_state() -> void:
    weapon_mastery.clear()
    school_mastery.clear()
    _ensure_default_masteries()
    _notify_mastery_ui_changed()


func _notify_mastery_ui_changed() -> void:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("refresh_mastery_display"):
            ui_node.refresh_mastery_display()


func _get_game_ui() -> Node:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("show_reward_notification"):
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null and autoload_ui.has_method("show_reward_notification"):
        return autoload_ui

    return null
    

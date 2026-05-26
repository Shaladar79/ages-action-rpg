extends Node

const MIN_FACTION_POINTS: int = 0

var faction_points: Dictionary = {}


func _ready() -> void:
    _ensure_default_factions()


func _ensure_default_factions() -> void:
    for faction_id in FactionDatabase.get_all_faction_ids():
        if not faction_points.has(faction_id):
            faction_points[faction_id] = 0


func get_faction_points(faction_id: String) -> int:
    var clean_faction_id := faction_id.strip_edges()

    if clean_faction_id == "":
        return 0

    if not FactionDatabase.faction_exists(clean_faction_id):
        return 0

    if not faction_points.has(clean_faction_id):
        faction_points[clean_faction_id] = 0

    return int(faction_points.get(clean_faction_id, 0))


func set_faction_points(faction_id: String, points: int) -> bool:
    var clean_faction_id := faction_id.strip_edges()

    if clean_faction_id == "":
        return false

    if not FactionDatabase.faction_exists(clean_faction_id):
        push_warning("Cannot set faction points. Unknown faction: " + clean_faction_id)
        return false

    var safe_points: int = maxi(MIN_FACTION_POINTS, points)

    faction_points[clean_faction_id] = safe_points

    print(
        "Faction points set: ",
        FactionDatabase.get_faction_name(clean_faction_id),
        " = ",
        safe_points
    )

    _notify_faction_ui_changed()

    return true


func add_faction_points(faction_id: String, amount: int) -> bool:
    var clean_faction_id := faction_id.strip_edges()

    if clean_faction_id == "":
        return false

    if amount == 0:
        return false

    var current_points := get_faction_points(clean_faction_id)
    return set_faction_points(clean_faction_id, current_points + amount)


func remove_faction_points(faction_id: String, amount: int) -> bool:
    if amount <= 0:
        return false

    return add_faction_points(faction_id, -amount)


func get_faction_row(faction_id: String) -> Dictionary:
    var clean_faction_id := faction_id.strip_edges()

    if clean_faction_id == "":
        return {}

    if not FactionDatabase.faction_exists(clean_faction_id):
        return {}

    var points := get_faction_points(clean_faction_id)
    var current_tier := FactionDatabase.get_tier_for_points(clean_faction_id, points)
    var next_tier := FactionDatabase.get_next_tier_for_points(clean_faction_id, points)

    return {
        "id": clean_faction_id,
        "name": FactionDatabase.get_faction_name(clean_faction_id),
        "description": FactionDatabase.get_faction_description(clean_faction_id),
        "points": points,
        "current_tier": current_tier,
        "next_tier": next_tier
    }


func get_all_faction_rows() -> Array[Dictionary]:
    _ensure_default_factions()

    var rows: Array[Dictionary] = []

    for faction_id in FactionDatabase.get_all_faction_ids():
        var row := get_faction_row(faction_id)

        if row.is_empty():
            continue

        rows.append(row)

    return rows


func get_faction_save_data() -> Dictionary:
    _ensure_default_factions()

    return {
        "faction_points": faction_points.duplicate(true)
    }


func load_faction_save_data(saved_faction_data: Dictionary) -> void:
    faction_points.clear()
    _ensure_default_factions()

    if saved_faction_data.is_empty():
        _notify_faction_ui_changed()
        print("FactionManager loaded no saved faction data.")
        return

    var saved_points: Dictionary = saved_faction_data.get("faction_points", {})

    for faction_id in saved_points.keys():
        var clean_faction_id := str(faction_id).strip_edges()

        if clean_faction_id == "":
            continue

        if not FactionDatabase.faction_exists(clean_faction_id):
            continue

        faction_points[clean_faction_id] = maxi(
            MIN_FACTION_POINTS,
            int(saved_points.get(faction_id, 0))
        )

    _ensure_default_factions()
    _notify_faction_ui_changed()

    print("FactionManager loaded faction count: ", faction_points.size())


func clear_faction_state() -> void:
    faction_points.clear()
    _ensure_default_factions()
    _notify_faction_ui_changed()


func _notify_faction_ui_changed() -> void:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("refresh_faction_display"):
            ui_node.refresh_faction_display()

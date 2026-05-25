extends RefCounted
class_name StatusEffects

const STATUS_TANGLED: String = "tangled"

const KEY_REMAINING_DURATION: String = "remaining_duration"
const KEY_MOVE_SPEED_MULTIPLIER: String = "move_speed_multiplier"

const TANGLED_DEFAULT_MOVE_SPEED_MULTIPLIER: float = 0.5


static func apply_status_effect(
        active_status_effects: Dictionary,
        status_id: String,
        duration: float,
        effect_data: Dictionary = {}
) -> bool:
    var clean_status_id := status_id.strip_edges()

    if clean_status_id == "":
        return false

    if duration <= 0.0:
        return false

    var status_data: Dictionary = effect_data.duplicate(true)
    status_data[KEY_REMAINING_DURATION] = duration

    match clean_status_id:
        STATUS_TANGLED:
            if not status_data.has(KEY_MOVE_SPEED_MULTIPLIER):
                status_data[KEY_MOVE_SPEED_MULTIPLIER] = TANGLED_DEFAULT_MOVE_SPEED_MULTIPLIER

        _:
            pass

    active_status_effects[clean_status_id] = status_data

    return true


static func remove_status_effect(active_status_effects: Dictionary, status_id: String) -> bool:
    var clean_status_id := status_id.strip_edges()

    if clean_status_id == "":
        return false

    if not active_status_effects.has(clean_status_id):
        return false

    active_status_effects.erase(clean_status_id)

    return true


static func has_status_effect(active_status_effects: Dictionary, status_id: String) -> bool:
    var clean_status_id := status_id.strip_edges()

    if clean_status_id == "":
        return false

    return active_status_effects.has(clean_status_id)


static func update_status_effects(active_status_effects: Dictionary, delta: float) -> Array[String]:
    var expired_status_ids: Array[String] = []

    if active_status_effects.is_empty():
        return expired_status_ids

    for status_id in active_status_effects.keys():
        var status_data: Dictionary = active_status_effects.get(status_id, {})
        var remaining_duration: float = float(status_data.get(KEY_REMAINING_DURATION, 0.0))

        remaining_duration -= delta
        status_data[KEY_REMAINING_DURATION] = remaining_duration
        active_status_effects[status_id] = status_data

        if remaining_duration <= 0.0:
            expired_status_ids.append(str(status_id))

    for status_id in expired_status_ids:
        active_status_effects.erase(status_id)

    return expired_status_ids


static func get_move_speed_multiplier(active_status_effects: Dictionary) -> float:
    var multiplier: float = 1.0

    if active_status_effects.is_empty():
        return multiplier

    for status_id in active_status_effects.keys():
        var status_data: Dictionary = active_status_effects.get(status_id, {})

        if not status_data.has(KEY_MOVE_SPEED_MULTIPLIER):
            continue

        multiplier *= float(status_data.get(KEY_MOVE_SPEED_MULTIPLIER, 1.0))

    return multiplier

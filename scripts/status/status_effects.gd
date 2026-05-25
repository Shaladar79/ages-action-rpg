extends RefCounted
class_name StatusEffects

const STATUS_TANGLED: String = "tangled"
const STATUS_BURNING: String = "burning"
const STATUS_ROCK_SKIN: String = "rock_skin"

const KEY_REMAINING_DURATION: String = "remaining_duration"
const KEY_MOVE_SPEED_MULTIPLIER: String = "move_speed_multiplier"

const KEY_DAMAGE_PER_TICK: String = "damage_per_tick"
const KEY_DAMAGE_TICK_INTERVAL: String = "damage_tick_interval"
const KEY_DAMAGE_TICK_TIMER: String = "damage_tick_timer"
const KEY_DAMAGE_TYPES: String = "damage_types"
const KEY_IGNORE_DEFENSE: String = "ignore_defense"

const KEY_DEFENSE_BONUS: String = "defense_bonus"

const TANGLED_DEFAULT_MOVE_SPEED_MULTIPLIER: float = 0.5

const BURNING_DEFAULT_DAMAGE_PER_TICK: int = 1
const BURNING_DEFAULT_TICK_INTERVAL: float = 1.0
const BURNING_DEFAULT_DAMAGE_TYPES: int = DamageTypes.FIRE

const ROCK_SKIN_DEFAULT_DEFENSE_BONUS: int = 2


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

        STATUS_BURNING:
            if not status_data.has(KEY_DAMAGE_PER_TICK):
                status_data[KEY_DAMAGE_PER_TICK] = BURNING_DEFAULT_DAMAGE_PER_TICK

            if not status_data.has(KEY_DAMAGE_TICK_INTERVAL):
                status_data[KEY_DAMAGE_TICK_INTERVAL] = BURNING_DEFAULT_TICK_INTERVAL

            if not status_data.has(KEY_DAMAGE_TICK_TIMER):
                status_data[KEY_DAMAGE_TICK_TIMER] = BURNING_DEFAULT_TICK_INTERVAL

            if not status_data.has(KEY_DAMAGE_TYPES):
                status_data[KEY_DAMAGE_TYPES] = BURNING_DEFAULT_DAMAGE_TYPES

            if not status_data.has(KEY_IGNORE_DEFENSE):
                status_data[KEY_IGNORE_DEFENSE] = true

        STATUS_ROCK_SKIN:
            if not status_data.has(KEY_DEFENSE_BONUS):
                status_data[KEY_DEFENSE_BONUS] = ROCK_SKIN_DEFAULT_DEFENSE_BONUS

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


static func update_status_effects(active_status_effects: Dictionary, delta: float) -> Dictionary:
    var expired_status_ids: Array[String] = []
    var tick_events: Array[Dictionary] = []

    if active_status_effects.is_empty():
        return {
            "expired_status_ids": expired_status_ids,
            "tick_events": tick_events
        }

    for status_id in active_status_effects.keys():
        var clean_status_id := str(status_id)
        var status_data: Dictionary = active_status_effects.get(clean_status_id, {})
        var remaining_duration: float = float(status_data.get(KEY_REMAINING_DURATION, 0.0))

        remaining_duration -= delta
        status_data[KEY_REMAINING_DURATION] = remaining_duration

        if status_data.has(KEY_DAMAGE_PER_TICK):
            var tick_timer: float = float(status_data.get(KEY_DAMAGE_TICK_TIMER, BURNING_DEFAULT_TICK_INTERVAL))
            var tick_interval: float = float(status_data.get(KEY_DAMAGE_TICK_INTERVAL, BURNING_DEFAULT_TICK_INTERVAL))

            tick_timer -= delta

            while tick_timer <= 0.0 and remaining_duration > 0.0:
                tick_events.append({
                    "status_id": clean_status_id,
                    "damage_amount": int(status_data.get(KEY_DAMAGE_PER_TICK, 0)),
                    "damage_types": int(status_data.get(KEY_DAMAGE_TYPES, DamageTypes.NONE)),
                    "ignore_defense": bool(status_data.get(KEY_IGNORE_DEFENSE, false))
                })

                tick_timer += maxf(0.01, tick_interval)

            status_data[KEY_DAMAGE_TICK_TIMER] = tick_timer

        active_status_effects[clean_status_id] = status_data

        if remaining_duration <= 0.0:
            expired_status_ids.append(clean_status_id)

    for status_id in expired_status_ids:
        active_status_effects.erase(status_id)

    return {
        "expired_status_ids": expired_status_ids,
        "tick_events": tick_events
    }


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


static func get_defense_bonus(active_status_effects: Dictionary) -> int:
    var bonus: int = 0

    if active_status_effects.is_empty():
        return bonus

    for status_id in active_status_effects.keys():
        var status_data: Dictionary = active_status_effects.get(status_id, {})

        if not status_data.has(KEY_DEFENSE_BONUS):
            continue

        bonus += int(status_data.get(KEY_DEFENSE_BONUS, 0))

    return bonus

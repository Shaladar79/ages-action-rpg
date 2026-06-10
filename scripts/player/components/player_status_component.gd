extends RefCounted
class_name PlayerStatusComponent

var player: Node = null


func setup(owner_player: Node) -> void:
    player = owner_player


func apply_status_effect(status_id: String, duration: float, effect_data: Dictionary = {}) -> bool:
    if player == null:
        return false

    if bool(player.get("is_defeated")):
        return false

    var active_status_effects: Dictionary = player.get("active_status_effects")
    var applied := StatusEffects.apply_status_effect(active_status_effects, status_id, duration, effect_data)
    player.set("active_status_effects", active_status_effects)

    if applied:
        print("Player status applied/refreshed: ", status_id, " duration: ", duration)

    return applied


func remove_status_effect(status_id: String) -> bool:
    if player == null:
        return false

    var active_status_effects: Dictionary = player.get("active_status_effects")
    var removed := StatusEffects.remove_status_effect(active_status_effects, status_id)
    player.set("active_status_effects", active_status_effects)

    if removed:
        print("Player status removed: ", status_id)

    return removed


func has_status_effect(status_id: String) -> bool:
    if player == null:
        return false

    var active_status_effects: Dictionary = player.get("active_status_effects")
    return StatusEffects.has_status_effect(active_status_effects, status_id)


func update_status_effects(delta: float) -> void:
    if player == null:
        return

    var active_status_effects: Dictionary = player.get("active_status_effects")
    var update_result := StatusEffects.update_status_effects(active_status_effects, delta)
    player.set("active_status_effects", active_status_effects)

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
            if player.has_method("take_damage_with_types"):
                player.take_damage_with_types(damage_amount, damage_types)

    var expired_status_ids: Array = update_result.get("expired_status_ids", [])

    for status_id in expired_status_ids:
        print("Player status expired: ", status_id)


func take_status_tick_damage(incoming_damage: int, incoming_damage_types: int = DamageTypes.NONE) -> void:
    if player == null:
        return

    if bool(player.get("is_defeated")):
        return

    if incoming_damage <= 0:
        return

    if incoming_damage_types != DamageTypes.NONE:
        if player.has_method("_is_resistant_to_damage_types"):
            if player._is_resistant_to_damage_types(incoming_damage_types):
                print("Status tick negated by resistance: ", DamageTypes.get_damage_type_names(incoming_damage_types))
                return

    var stats: CharacterStats = player.get("character_stats")

    if stats == null:
        return

    stats.current_health -= incoming_damage
    stats.current_health = maxi(stats.current_health, 0)

    print("Player took status tick damage: ", incoming_damage)

    if incoming_damage_types != DamageTypes.NONE:
        print("Status tick damage types: ", DamageTypes.get_damage_type_names(incoming_damage_types))

    print("Player HP: ", stats.current_health, " / ", stats.max_health)

    if player.has_method("_notify_ui_stats_changed"):
        player._notify_ui_stats_changed()

    if stats.current_health <= 0:
        if player.has_method("_on_player_defeated"):
            player._on_player_defeated()

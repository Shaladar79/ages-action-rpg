extends RefCounted
class_name PlayerHotbarComponent

const HOTBAR_SLOT_COUNT: int = 8

const QUEST_HOTBAR_AND_CLUB_LESSON_ID: String = "starter_hotbar_and_club_lesson"
const QUEST_HEALING_TONIC_HOTBAR_OBJECTIVE_ID: String = "equip_healing_tonic_hotbar_01"
const QUEST_HEALING_TONIC_HOTBAR_FLAG: String = "starter_healing_tonic_hotbar_equipped"

const ITEM_HEALING_TONIC_ID: String = "healing_tonic"

var player: Node = null


func setup(owner_player: Node) -> void:
    player = owner_player
    initialize_hotbar_slots()


func initialize_hotbar_slots() -> void:
    if player == null:
        return

    var hotbar_slots: Array = player.get("hotbar_slots")

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

    player.set("hotbar_slots", hotbar_slots)


func get_hotbar_slots() -> Array[Dictionary]:
    initialize_hotbar_slots()

    if player == null:
        return []

    var hotbar_slots: Array = player.get("hotbar_slots")
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
    initialize_hotbar_slots()

    if player == null:
        return

    var hotbar_slots: Array = player.get("hotbar_slots")

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

    player.set("hotbar_slots", hotbar_slots)

    clear_invalid_hotbar_slots()
    _notify_ui_stats_changed()


func assign_hotbar_slot(slot_number: int, item_id: String) -> bool:
    initialize_hotbar_slots()

    if player == null:
        return false

    if slot_number < 1 or slot_number > HOTBAR_SLOT_COUNT:
        push_warning("Invalid hotbar slot: " + str(slot_number))
        return false

    if item_id.strip_edges() == "":
        clear_hotbar_slot(slot_number)
        return true

    if not _player_has_inventory_item(item_id):
        push_warning("Cannot assign hotbar item. Item not in inventory: " + item_id)
        return false

    if not ItemDatabase.is_hotbar_usable(item_id):
        push_warning("Cannot assign item to hotbar. Item is not hotbar usable: " + item_id)
        return false

    var hotbar_slots: Array = player.get("hotbar_slots")
    var slot_index: int = slot_number - 1
    var item_type: String = ItemDatabase.get_item_type(item_id)

    hotbar_slots[slot_index] = {
        "slot": slot_number,
        "item_id": item_id,
        "item_type": item_type,
        "cooldown_remaining": 0.0
    }

    player.set("hotbar_slots", hotbar_slots)

    print("Assigned hotbar slot ", slot_number, ": ", ItemDatabase.get_item_name(item_id))

    try_progress_healing_tonic_hotbar_quest(item_id)
    _notify_ui_stats_changed()

    return true


func try_progress_healing_tonic_hotbar_quest(item_id: String) -> void:
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
    initialize_hotbar_slots()

    if player == null:
        return

    if slot_number < 1 or slot_number > HOTBAR_SLOT_COUNT:
        return

    var hotbar_slots: Array = player.get("hotbar_slots")
    var slot_index: int = slot_number - 1

    hotbar_slots[slot_index] = {
        "slot": slot_number,
        "item_id": "",
        "item_type": "",
        "cooldown_remaining": 0.0
    }

    player.set("hotbar_slots", hotbar_slots)

    print("Cleared hotbar slot: ", slot_number)
    _notify_ui_stats_changed()


func clear_hotbar_slots_for_missing_item(item_id: String) -> void:
    initialize_hotbar_slots()

    if player == null:
        return

    var hotbar_slots: Array = player.get("hotbar_slots")

    for slot_index in range(hotbar_slots.size()):
        var slot: Dictionary = hotbar_slots[slot_index]
        var slot_item_id: String = str(slot.get("item_id", ""))

        if slot_item_id == item_id and not _player_has_inventory_item(item_id):
            var slot_number: int = int(slot.get("slot", slot_index + 1))
            hotbar_slots[slot_index] = {
                "slot": slot_number,
                "item_id": "",
                "item_type": "",
                "cooldown_remaining": 0.0
            }

    player.set("hotbar_slots", hotbar_slots)


func clear_invalid_hotbar_slots() -> void:
    initialize_hotbar_slots()

    if player == null:
        return

    var hotbar_slots: Array = player.get("hotbar_slots")

    for slot_index in range(hotbar_slots.size()):
        var slot: Dictionary = hotbar_slots[slot_index]
        var slot_number: int = int(slot.get("slot", slot_index + 1))
        var item_id: String = str(slot.get("item_id", ""))

        if item_id.strip_edges() == "":
            continue

        if not _player_has_inventory_item(item_id):
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

    player.set("hotbar_slots", hotbar_slots)


func update_hotbar_cooldowns(delta: float) -> void:
    initialize_hotbar_slots()

    if player == null:
        return

    var hotbar_slots: Array = player.get("hotbar_slots")

    for slot_index in range(hotbar_slots.size()):
        var slot: Dictionary = hotbar_slots[slot_index]
        var cooldown_remaining: float = float(slot.get("cooldown_remaining", 0.0))

        if cooldown_remaining <= 0.0:
            continue

        cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
        slot["cooldown_remaining"] = cooldown_remaining
        hotbar_slots[slot_index] = slot

    player.set("hotbar_slots", hotbar_slots)


func handle_hotbar_input() -> bool:
    if player == null:
        return false

    if player.has_method("is_dialogue_active"):
        if player.is_dialogue_active():
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
    initialize_hotbar_slots()

    if player == null:
        return false

    if bool(player.get("is_defeated")):
        return false

    if slot_number < 1 or slot_number > HOTBAR_SLOT_COUNT:
        return false

    var hotbar_slots: Array = player.get("hotbar_slots")
    var slot_index: int = slot_number - 1
    var slot: Dictionary = hotbar_slots[slot_index]
    var item_id: String = str(slot.get("item_id", ""))
    var item_type: String = str(slot.get("item_type", ""))
    var cooldown_remaining: float = float(slot.get("cooldown_remaining", 0.0))

    if item_id.strip_edges() == "":
        print("Hotbar slot ", slot_number, " is empty.")
        return false

    if not _player_has_inventory_item(item_id):
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
            return use_hotbar_consumable(slot_number, item_id)

        "spell_book":
            return use_hotbar_spell_book(slot_number, item_id)

        "technique_manual":
            return use_hotbar_technique_manual(slot_number, item_id)

        _:
            print("Hotbar item type cannot be used yet: ", item_type)
            return false


func use_hotbar_consumable(slot_number: int, item_id: String) -> bool:
    if player == null:
        return false

    var effect: String = ItemDatabase.get_consumable_effect(item_id)

    match effect:
        "heal":
            var heal_amount: int = ItemDatabase.get_heal_amount(item_id)

            if heal_amount <= 0:
                print("Consumable has no heal amount: ", item_id)
                return false

            var healed := false

            if player.has_method("heal_player"):
                healed = player.heal_player(heal_amount)

            if not healed:
                print("Consumable not used. Player is already at full health.")
                return false

        "restore_mana":
            var mana_gain: int = ItemDatabase.get_mana_gain(item_id)

            if mana_gain <= 0:
                print("Consumable has no mana gain: ", item_id)
                return false

            var restored := false

            if player.has_method("restore_player_mana"):
                restored = player.restore_player_mana(mana_gain)

            if not restored:
                print("Consumable not used. Mana is locked or already full.")
                return false

        _:
            print("Unknown consumable effect: ", effect)
            return false

    if ItemDatabase.is_consumed_on_use(item_id):
        if player.has_method("remove_inventory_item"):
            player.remove_inventory_item(item_id)

    print("Used consumable from hotbar slot ", slot_number, ": ", ItemDatabase.get_item_name(item_id))
    _notify_ui_stats_changed()

    return true


func use_hotbar_spell_book(slot_number: int, item_id: String) -> bool:
    if player == null:
        return false

    var character_stats: CharacterStats = player.get("character_stats")

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
            if player.has_method("_cast_self_buff_spell"):
                player._cast_self_buff_spell(item_id, status_effect, status_duration)

        _:
            var spell_range: float = ItemDatabase.get_spell_range(item_id)

            if spell_range <= 0.0:
                print("Spell has no valid range: ", item_id)
                character_stats.restore_mana(mana_cost)
                _notify_ui_stats_changed()
                return false

            var cast_direction := Vector2.DOWN

            if player.has_method("_get_last_direction_vector"):
                cast_direction = player._get_last_direction_vector()

            if cast_direction == Vector2.ZERO:
                cast_direction = Vector2.DOWN

            if player.has_method("_spawn_spell_projectile"):
                player._spawn_spell_projectile(
                    item_id,
                    cast_direction,
                    spell_range,
                    status_effect,
                    status_duration
                )

    set_hotbar_slot_cooldown(slot_number, cooldown)

    if player.has_method("_record_spell_school_mastery_cast"):
        player._record_spell_school_mastery_cast(item_id)

    print("Cast spell from hotbar slot ", slot_number, ": ", ItemDatabase.get_spell_name(item_id))
    _notify_ui_stats_changed()

    return true


func set_hotbar_slot_cooldown(slot_number: int, cooldown: float) -> void:
    initialize_hotbar_slots()

    if player == null:
        return

    if slot_number < 1 or slot_number > HOTBAR_SLOT_COUNT:
        return

    if cooldown <= 0.0:
        return

    var hotbar_slots: Array = player.get("hotbar_slots")
    var slot_index := slot_number - 1
    var slot: Dictionary = hotbar_slots[slot_index]
    slot["cooldown_remaining"] = cooldown
    hotbar_slots[slot_index] = slot

    player.set("hotbar_slots", hotbar_slots)


func use_hotbar_technique_manual(slot_number: int, item_id: String) -> bool:
    print("Technique manual hotbar use placeholder. Slot: ", slot_number, " Item: ", item_id)
    return false


func _player_has_inventory_item(item_id: String) -> bool:
    if player == null:
        return false

    if not player.has_method("has_inventory_item"):
        return false

    return player.has_inventory_item(item_id)


func _notify_ui_stats_changed() -> void:
    if player != null and player.has_method("_notify_ui_stats_changed"):
        player._notify_ui_stats_changed()

extends RefCounted
class_name PlayerEquipmentComponent

var player: Node = null


func setup(owner_player: Node) -> void:
    player = owner_player


func equip_melee_weapon(item_id: String) -> bool:
    return _equip_item_to_slot(item_id, ItemDatabase.EQUIPMENT_SLOT_MELEE_WEAPON)


func equip_ranged_weapon(item_id: String) -> bool:
    return _equip_item_to_slot(item_id, ItemDatabase.EQUIPMENT_SLOT_RANGED_WEAPON)


func equip_armor(item_id: String) -> bool:
    return _equip_item_to_slot(item_id, ItemDatabase.EQUIPMENT_SLOT_ARMOR)


func equip_accessory_1(item_id: String) -> bool:
    return _equip_item_to_slot(item_id, "accessory_1")


func equip_accessory_2(item_id: String) -> bool:
    return _equip_item_to_slot(item_id, "accessory_2")


func equip_weapon(item_id: String) -> bool:
    return _equip_weapon_compat(item_id)


func equip_accessory(item_id: String) -> bool:
    return equip_accessory_1(item_id)


func _equip_weapon_compat(item_id: String) -> bool:
    if item_id.strip_edges() == "":
        unequip_melee_weapon()
        return true

    var equipment_slot := ItemDatabase.get_equipment_slot(item_id)

    if equipment_slot == ItemDatabase.EQUIPMENT_SLOT_RANGED_WEAPON:
        return equip_ranged_weapon(item_id)

    return equip_melee_weapon(item_id)


func _equip_item_to_slot(item_id: String, target_slot: String) -> bool:
    if player == null:
        return false

    if bool(player.get("is_defeated")):
        return false

    if item_id.strip_edges() == "":
        _unequip_slot(target_slot)
        return true

    if not player.has_method("has_inventory_item"):
        push_warning("Player has no has_inventory_item(). Cannot equip item.")
        return false

    if not player.has_inventory_item(item_id):
        push_warning("Cannot equip item. Item not found in inventory: " + item_id)
        return false

    var item_name := item_id

    if player.has_method("get_inventory_item_name"):
        item_name = player.get_inventory_item_name(item_id)
    else:
        item_name = ItemDatabase.get_item_name(item_id)

    var item_equipment_slot := ItemDatabase.get_equipment_slot(item_id)
    var stats: CharacterStats = player.get("character_stats")

    if stats == null:
        push_warning("Cannot equip item. CharacterStats is null.")
        return false

    match target_slot:
        ItemDatabase.EQUIPMENT_SLOT_MELEE_WEAPON:
            if item_equipment_slot != ItemDatabase.EQUIPMENT_SLOT_MELEE_WEAPON:
                push_warning("Item is not a melee weapon: " + item_id)
                return false

            var equipped := stats.equip_melee_weapon(item_id, item_name)

            if equipped:
                print("Equipped melee weapon: ", stats.get_equipped_melee_weapon_name())
                _notify_ui_stats_changed()

            return equipped

        ItemDatabase.EQUIPMENT_SLOT_RANGED_WEAPON:
            if item_equipment_slot != ItemDatabase.EQUIPMENT_SLOT_RANGED_WEAPON:
                push_warning("Item is not a ranged weapon: " + item_id)
                return false

            var equipped := stats.equip_ranged_weapon(item_id, item_name)

            if equipped:
                print("Equipped ranged weapon: ", stats.get_equipped_ranged_weapon_name())
                _notify_ui_stats_changed()

            return equipped

        ItemDatabase.EQUIPMENT_SLOT_ARMOR:
            if item_equipment_slot != ItemDatabase.EQUIPMENT_SLOT_ARMOR:
                push_warning("Item is not armor: " + item_id)
                return false

            var equipped := stats.equip_armor(item_id, item_name)

            if equipped:
                print("Equipped armor: ", stats.get_equipped_armor_name())
                _notify_ui_stats_changed()

            return equipped

        "accessory_1":
            if item_equipment_slot != ItemDatabase.EQUIPMENT_SLOT_ACCESSORY:
                push_warning("Item is not an accessory: " + item_id)
                return false

            var equipped := stats.equip_accessory_1(item_id, item_name)

            if equipped:
                print("Equipped accessory 1: ", stats.get_equipped_accessory_1_name())
                _notify_ui_stats_changed()

            return equipped

        "accessory_2":
            if item_equipment_slot != ItemDatabase.EQUIPMENT_SLOT_ACCESSORY:
                push_warning("Item is not an accessory: " + item_id)
                return false

            var equipped := stats.equip_accessory_2(item_id, item_name)

            if equipped:
                print("Equipped accessory 2: ", stats.get_equipped_accessory_2_name())
                _notify_ui_stats_changed()

            return equipped

        _:
            push_warning("Unknown equipment slot: " + target_slot)
            return false


func _unequip_slot(target_slot: String) -> void:
    match target_slot:
        ItemDatabase.EQUIPMENT_SLOT_MELEE_WEAPON:
            unequip_melee_weapon()
        ItemDatabase.EQUIPMENT_SLOT_RANGED_WEAPON:
            unequip_ranged_weapon()
        ItemDatabase.EQUIPMENT_SLOT_ARMOR:
            unequip_armor()
        "accessory_1":
            unequip_accessory_1()
        "accessory_2":
            unequip_accessory_2()


func unequip_melee_weapon() -> void:
    var stats := _get_stats()

    if stats == null:
        return

    stats.unequip_melee_weapon()

    if player != null and player.has_method("_hide_weapon_sprite"):
        player._hide_weapon_sprite()

    print("Melee weapon unequipped.")
    _notify_ui_stats_changed()


func unequip_ranged_weapon() -> void:
    var stats := _get_stats()

    if stats == null:
        return

    stats.unequip_ranged_weapon()
    print("Ranged weapon unequipped.")
    _notify_ui_stats_changed()


func unequip_armor() -> void:
    var stats := _get_stats()

    if stats == null:
        return

    stats.unequip_armor()
    print("Armor unequipped.")
    _notify_ui_stats_changed()


func unequip_accessory_1() -> void:
    var stats := _get_stats()

    if stats == null:
        return

    stats.unequip_accessory_1()
    print("Accessory 1 unequipped.")
    _notify_ui_stats_changed()


func unequip_accessory_2() -> void:
    var stats := _get_stats()

    if stats == null:
        return

    stats.unequip_accessory_2()
    print("Accessory 2 unequipped.")
    _notify_ui_stats_changed()


func unequip_weapon() -> void:
    unequip_melee_weapon()


func unequip_accessory() -> void:
    unequip_accessory_1()


func has_equipped_weapon() -> bool:
    return has_equipped_melee_weapon()


func has_equipped_melee_weapon() -> bool:
    var stats := _get_stats()

    if stats == null:
        return false

    return stats.equipped_melee_weapon_id.strip_edges() != ""


func has_equipped_ranged_weapon() -> bool:
    var stats := _get_stats()

    if stats == null:
        return false

    return stats.equipped_ranged_weapon_id.strip_edges() != ""


func get_equipped_weapon_name() -> String:
    var stats := _get_stats()

    if stats == null:
        return "None"

    return stats.get_equipped_weapon_name()


func get_equipped_melee_weapon_name() -> String:
    var stats := _get_stats()

    if stats == null:
        return "None"

    return stats.get_equipped_melee_weapon_name()


func get_equipped_ranged_weapon_name() -> String:
    var stats := _get_stats()

    if stats == null:
        return "None"

    return stats.get_equipped_ranged_weapon_name()


func get_equipped_armor_name() -> String:
    var stats := _get_stats()

    if stats == null:
        return "None"

    return stats.get_equipped_armor_name()


func get_equipped_accessory_name() -> String:
    var stats := _get_stats()

    if stats == null:
        return "None"

    return stats.get_equipped_accessory_name()


func get_equipped_accessory_1_name() -> String:
    var stats := _get_stats()

    if stats == null:
        return "None"

    return stats.get_equipped_accessory_1_name()


func get_equipped_accessory_2_name() -> String:
    var stats := _get_stats()

    if stats == null:
        return "None"

    return stats.get_equipped_accessory_2_name()


func unequip_missing_item_if_needed(item_id: String) -> void:
    var stats := _get_stats()

    if stats == null:
        return

    if stats.equipped_melee_weapon_id == item_id:
        stats.unequip_melee_weapon()

    if stats.equipped_ranged_weapon_id == item_id:
        stats.unequip_ranged_weapon()

    if stats.equipped_armor_id == item_id:
        stats.unequip_armor()

    if stats.equipped_accessory_1_id == item_id:
        stats.unequip_accessory_1()

    if stats.equipped_accessory_2_id == item_id:
        stats.unequip_accessory_2()


func validate_equipment_after_inventory_load() -> void:
    var stats := _get_stats()

    if stats == null:
        return

    if player == null or not player.has_method("has_inventory_item"):
        return

    if stats.equipped_melee_weapon_id.strip_edges() != "" and not player.has_inventory_item(stats.equipped_melee_weapon_id):
        stats.unequip_melee_weapon()

    if stats.equipped_ranged_weapon_id.strip_edges() != "" and not player.has_inventory_item(stats.equipped_ranged_weapon_id):
        stats.unequip_ranged_weapon()

    if stats.equipped_armor_id.strip_edges() != "" and not player.has_inventory_item(stats.equipped_armor_id):
        stats.unequip_armor()

    if stats.equipped_accessory_1_id.strip_edges() != "" and not player.has_inventory_item(stats.equipped_accessory_1_id):
        stats.unequip_accessory_1()

    if stats.equipped_accessory_2_id.strip_edges() != "" and not player.has_inventory_item(stats.equipped_accessory_2_id):
        stats.unequip_accessory_2()


func _get_stats() -> CharacterStats:
    if player == null:
        return null

    return player.get("character_stats") as CharacterStats


func _notify_ui_stats_changed() -> void:
    if player != null and player.has_method("_notify_ui_stats_changed"):
        player._notify_ui_stats_changed()

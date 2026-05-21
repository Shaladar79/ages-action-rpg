extends RefCounted
class_name ItemDatabase


static func get_item_data(item_id: String) -> Dictionary:
    var item_data := WeaponDatabase.get_item_data(item_id)

    if not item_data.is_empty():
        return item_data

    item_data = ArmorDatabase.get_item_data(item_id)

    if not item_data.is_empty():
        return item_data

    return {}


static func get_item_name(item_id: String) -> String:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return item_id

    return item_data.get("name", item_id)


static func get_item_type(item_id: String) -> String:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return ""

    return item_data.get("type", "")


static func get_attack_bonus(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 0

    return int(item_data.get("attack_bonus", 0))


static func get_defense_bonus(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 0

    return int(item_data.get("defense_bonus", 0))


static func get_damage_types(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return DamageTypes.NONE

    return int(item_data.get("damage_types", DamageTypes.NONE))


static func get_damage_resistances(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return DamageTypes.NONE

    return int(item_data.get("damage_resistances", DamageTypes.NONE))


static func get_damage_weaknesses(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return DamageTypes.NONE

    return int(item_data.get("damage_weaknesses", DamageTypes.NONE))


static func damage_types_overlap(first_damage_types: int, second_damage_types: int) -> bool:
    return (first_damage_types & second_damage_types) != 0


static func item_has_breakable_tool_tag(item_id: String, required_tag: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    if not bool(item_data.get("required_for_breakables", false)):
        return false

    return item_data.get("breakable_tool_tag", "") == required_tag

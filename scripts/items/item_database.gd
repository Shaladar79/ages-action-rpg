extends RefCounted
class_name ItemDatabase


static func get_item_data(item_id: String) -> Dictionary:
    var item_data := WeaponDatabase.get_item_data(item_id)

    if not item_data.is_empty():
        return item_data

    item_data = ArmorDatabase.get_item_data(item_id)

    if not item_data.is_empty():
        return item_data

    item_data = ConsumableDatabase.get_item_data(item_id)

    if not item_data.is_empty():
        return item_data

    item_data = SpellBookDatabase.get_item_data(item_id)

    if not item_data.is_empty():
        return item_data

    item_data = TechniqueDatabase.get_item_data(item_id)

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


static func is_consumable(item_id: String) -> bool:
    return get_item_type(item_id) == "consumable"


static func is_spell_book(item_id: String) -> bool:
    return get_item_type(item_id) == "spell_book"


static func is_technique_manual(item_id: String) -> bool:
    return get_item_type(item_id) == "technique_manual"


static func is_hotbar_usable(item_id: String) -> bool:
    var item_type := get_item_type(item_id)

    return item_type == "consumable" or item_type == "spell_book" or item_type == "technique_manual"


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


static func get_consumable_effect(item_id: String) -> String:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return ""

    return str(item_data.get("consumable_effect", ""))


static func get_heal_amount(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 0

    return int(item_data.get("heal_amount", 0))


static func is_consumed_on_use(item_id: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    return bool(item_data.get("consumed_on_use", false))


static func damage_types_overlap(first_damage_types: int, second_damage_types: int) -> bool:
    return (first_damage_types & second_damage_types) != 0


static func item_has_breakable_tool_tag(item_id: String, required_tag: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    if not bool(item_data.get("required_for_breakables", false)):
        return false

    return item_data.get("breakable_tool_tag", "") == required_tag

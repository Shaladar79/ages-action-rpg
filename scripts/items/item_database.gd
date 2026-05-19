extends RefCounted
class_name ItemDatabase

const ITEM_STONE_CLUB: String = "club"
const ITEM_GRASS_TUNIC: String = "grass_tunic"


static func get_item_data(item_id: String) -> Dictionary:
    match item_id:
        ITEM_STONE_CLUB:
            return {
                "id": ITEM_STONE_CLUB,
                "name": "Stone Club",
                "type": "weapon",
                "attack_bonus": 1,
                "required_for_breakables": true,
                "breakable_tool_tag": "club"
            }

        ITEM_GRASS_TUNIC:
            return {
                "id": ITEM_GRASS_TUNIC,
                "name": "Grass Tunic",
                "type": "armor",
                "defense_bonus": 1
            }

        _:
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


static func item_has_breakable_tool_tag(item_id: String, required_tag: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    if not bool(item_data.get("required_for_breakables", false)):
        return false

    return item_data.get("breakable_tool_tag", "") == required_tag

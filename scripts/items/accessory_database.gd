extends RefCounted
class_name AccessoryDatabase


const AMULET_OF_MINOR_DEFENSE: String = "amulet_of_minor_defense"


static func get_item_data(item_id: String) -> Dictionary:
    match item_id:
        AMULET_OF_MINOR_DEFENSE:
            return {
                "id": AMULET_OF_MINOR_DEFENSE,
                "name": "Amulet of Minor Defense",
                "type": "accessory",
                "equipment_slot": ItemDatabase.EQUIPMENT_SLOT_ACCESSORY,
                "defense_bonus": 1,
                "description": "A simple protective charm. It grants +1 Defense.",
                "item_tags": ["accessory", "defense"]
            }

    return {}


static func is_accessory(item_id: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    return item_data.get("type", "") == "accessory"

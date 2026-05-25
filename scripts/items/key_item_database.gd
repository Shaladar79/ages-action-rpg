extends RefCounted
class_name KeyItemDatabase

const ITEM_FOREST_GUARDIAN_ESSENCE: String = "forest_guardian_essence"


static func get_item_data(item_id: String) -> Dictionary:
    match item_id:
        ITEM_FOREST_GUARDIAN_ESSENCE:
            return {
                "id": ITEM_FOREST_GUARDIAN_ESSENCE,
                "name": "Forest Guardian Essence",
                "type": "key_item",

                "icon_path": "",

                "consumed_on_use": false,
                "can_drop": false,
                "can_sell": false,
                "is_unique": true,

                "story_flag_on_acquire": "forest_guardian_essence_obtained",
                "quest_item": true,

                "description": "A concentrated essence left behind by the Forest Guardian. It pulses with old forest magic and may unlock a path forward.",
                "use_message": "The Forest Guardian Essence hums with quiet power."
            }

        _:
            return {}


static func is_key_item(item_id: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    return item_data.get("type", "") == "key_item"

extends RefCounted
class_name KeyItemDatabase

const ITEM_NATURE_GUARDIAN_ESSENCE: String = "nature_guardian_essence"
const ITEM_FIRE_GUARDIAN_ESSENCE: String = "fire_guardian_essence"
const ITEM_EARTH_GUARDIAN_ESSENCE: String = "earth_guardian_essence"


static func get_item_data(item_id: String) -> Dictionary:
    match item_id:
        ITEM_NATURE_GUARDIAN_ESSENCE:
            return {
                "id": ITEM_NATURE_GUARDIAN_ESSENCE,
                "name": "Nature Guardian Essence",
                "type": "key_item",

                "icon_path": "",

                "consumed_on_use": false,
                "can_drop": false,
                "can_sell": false,
                "is_unique": true,

                "story_flag_on_acquire": "nature_guardian_essence_obtained",
                "quest_item": true,

                "description": "A concentrated essence left behind by the Nature Guardian. It pulses with old life magic and may unlock a path forward.",
                "use_message": "The Nature Guardian Essence hums with quiet power."
            }

        ITEM_FIRE_GUARDIAN_ESSENCE:
            return {
                "id": ITEM_FIRE_GUARDIAN_ESSENCE,
                "name": "Fire Guardian Essence",
                "type": "key_item",

                "icon_path": "",

                "consumed_on_use": false,
                "can_drop": false,
                "can_sell": false,
                "is_unique": true,

                "story_flag_on_acquire": "fire_guardian_essence_obtained",
                "quest_item": true,

                "description": "A concentrated essence left behind by the Fire Guardian. Heat flickers inside it like a living coal, carrying the force needed to awaken the next seal.",
                "use_message": "The Fire Guardian Essence radiates steady heat."
            }

        ITEM_EARTH_GUARDIAN_ESSENCE:
            return {
                "id": ITEM_EARTH_GUARDIAN_ESSENCE,
                "name": "Earth Guardian Essence",
                "type": "key_item",

                "icon_path": "",

                "consumed_on_use": false,
                "can_drop": false,
                "can_sell": false,
                "is_unique": true,

                "story_flag_on_acquire": "earth_guardian_essence_obtained",
                "quest_item": true,

                "description": "A concentrated essence left behind by the Earth Guardian. It feels impossibly dense for its size, carrying the patient strength of stone and root.",
                "use_message": "The Earth Guardian Essence rests heavy with ancient power."
            }

        _:
            return {}


static func is_key_item(item_id: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    return item_data.get("type", "") == "key_item"

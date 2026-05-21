extends RefCounted
class_name ArmorDatabase

const ITEM_GRASS_TUNIC: String = "grass_tunic"


static func get_item_data(item_id: String) -> Dictionary:
    match item_id:
        ITEM_GRASS_TUNIC:
            return {
                "id": ITEM_GRASS_TUNIC,
                "name": "Grass Tunic",
                "type": "armor",

                "equipment_slot": ItemDatabase.EQUIPMENT_SLOT_ARMOR,
                "item_tags": [
					"armor"
                ],

                "defense_bonus": 1,
                "health_bonus": 0,

                "damage_resistances": DamageTypes.NONE,
                "damage_weaknesses": DamageTypes.FIRE
            }

        _:
            return {}

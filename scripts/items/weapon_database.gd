extends RefCounted
class_name WeaponDatabase

const ITEM_STONE_CLUB: String = "club"


static func get_item_data(item_id: String) -> Dictionary:
    match item_id:
        ITEM_STONE_CLUB:
            return {
                "id": ITEM_STONE_CLUB,
                "name": "Stone Club",
                "type": "weapon",

                "equipment_slot": ItemDatabase.EQUIPMENT_SLOT_MELEE_WEAPON,
                "item_tags": [
                    "weapon",
                    "melee_weapon",
					"breakable_tool"
                ],

                "attack_bonus": 1,
                "damage_types": DamageTypes.BASHING,

                "required_for_breakables": true,
                "breakable_tool_tag": "club"
            }

        _:
            return {}

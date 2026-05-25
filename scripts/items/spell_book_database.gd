extends RefCounted
class_name SpellBookDatabase

const TANGLE_FOOT_ID: String = "spell_book_tangle_foot"

const SPELL_SCHOOL_NATURE: String = "nature"


static func get_item_data(item_id: String) -> Dictionary:
    match item_id:
        TANGLE_FOOT_ID:
            return {
                "id": TANGLE_FOOT_ID,
                "name": "Spell Book: Tangle Foot",
                "type": "spell_book",
                "description": "A nature spell book that teaches Tangle Foot. The spell tangles a target and halves its movement speed.",
                "spell_id": "tangle_foot",
                "spell_name": "Tangle Foot",
                "spell_school": SPELL_SCHOOL_NATURE,
                "mana_cost": 3,
                "cooldown": 5.0,
                "spell_range": 220.0,
                "status_effect": "tangled",
                "status_duration": 4.0,
                "move_speed_multiplier": 0.5,
                "consumed_on_use": false,
                "item_tags": [
                    "spell_book",
                    "nature_spell"
                ]
            }

        _:
            return {}


static func is_spell_book(item_id: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    return item_data.get("type", "") == "spell_book"

extends RefCounted
class_name SpellBookDatabase

const TANGLE_FOOT_ID: String = "spell_book_tangle_foot"
const ITEM_SPELL_BOOK_FIRE_BOLT: String = "spell_book_fire_bolt"
const ITEM_SPELL_BOOK_STONE_SKIN: String = "spell_book_stone_skin"

const SPELL_SCHOOL_NATURE: String = "nature"
const SPELL_SCHOOL_FIRE: String = "fire"
const SPELL_SCHOOL_EARTH: String = "earth"


static func get_item_data(item_id: String) -> Dictionary:
    match item_id:
        TANGLE_FOOT_ID:
            return {
                "id": TANGLE_FOOT_ID,
                "name": "Spell Book: Tangle Foot",
                "type": "spell_book",
                "description": "A nature spell book that teaches Tangle Foot. The spell tangles a target and halves its movement speed.",

                "icon_path": "",

                "spell_id": "tangle_foot",
                "spell_name": "Tangle Foot",
                "spell_school": SPELL_SCHOOL_NATURE,

                "mana_cost": 3,
                "cooldown": 5.0,
                "spell_range": 220.0,

                "spell_damage": 0,
                "damage_types": DamageTypes.NONE,

                "cast_target": "projectile",

                "status_effect": "tangled",
                "status_duration": 4.0,
                "move_speed_multiplier": 0.5,

                "consumed_on_use": false,
                "item_tags": [
                    "spell_book",
                    "nature_spell"
                ]
            }

        ITEM_SPELL_BOOK_FIRE_BOLT:
            return {
                "id": ITEM_SPELL_BOOK_FIRE_BOLT,
                "name": "Spell Book: Fire Bolt",
                "type": "spell_book",
                "description": "Launches a bolt of fire that damages the target and can leave it burning.",

                "icon_path": "",

                "spell_id": "fire_bolt",
                "spell_name": "Fire Bolt",
                "spell_school": SPELL_SCHOOL_FIRE,

                "mana_cost": 4,
                "cooldown": 3.0,
                "spell_range": 260.0,

                "spell_damage": 3,
                "damage_types": DamageTypes.FIRE,

                "cast_target": "projectile",

                "status_effect": "burning",
                "status_duration": 4.0,
                "status_damage_per_tick": 1,
                "status_tick_interval": 1.0,

                "consumed_on_use": false,
                "item_tags": [
                    "spell_book",
                    "fire_spell"
                ]
            }

        ITEM_SPELL_BOOK_STONE_SKIN:
            return {
                "id": ITEM_SPELL_BOOK_STONE_SKIN,
                "name": "Spell Book: Stone Skin",
                "type": "spell_book",
                "description": "An earth spell book that teaches Stone Skin. The spell hardens the caster's body, granting +2 Defense for 15 seconds.",

                "icon_path": "",

                "spell_id": "stone_skin",
                "spell_name": "Stone Skin",
                "spell_school": SPELL_SCHOOL_EARTH,

                "mana_cost": 5,
                "cooldown": 15.0,
                "spell_range": 0.0,

                "spell_damage": 0,
                "damage_types": DamageTypes.NONE,

                "cast_target": "self",

                "status_effect": "rock_skin",
                "status_duration": 15.0,
                "defense_bonus": 2,

                "consumed_on_use": false,
                "item_tags": [
                    "spell_book",
                    "earth_spell",
                    "buff",
                    "self_cast"
                ]
            }

        _:
            return {}


static func is_spell_book(item_id: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    return item_data.get("type", "") == "spell_book"

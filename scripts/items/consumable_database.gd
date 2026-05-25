extends RefCounted
class_name ConsumableDatabase

const ITEM_HEALING_TONIC: String = "healing_tonic"
const ITEM_MANA_TONIC: String = "mana_tonic"


static func get_item_data(item_id: String) -> Dictionary:
    match item_id:
        ITEM_HEALING_TONIC:
            return {
                "id": ITEM_HEALING_TONIC,
                "name": "Healing Tonic",
                "type": "consumable",

                # HUD / inventory display
                "icon_path": "",

                # Consumable use rules
                "consumable_effect": "heal",
                "target_type": "self",
                "consumed_on_use": true,
                "use_cooldown": 0.0,

                # Resource gains
                "heal_amount": 20,
                "mana_gain": 0,
                "stamina_gain": 0,

                # Future hooks
                "status_effects_to_apply": [],
                "status_effects_to_remove": [],
                "damage_resistances": DamageTypes.NONE,
                "damage_weaknesses": DamageTypes.NONE,
                "duration": 0.0,

                # Feedback
                "use_message": "You drink a Healing Tonic and recover 20 health."
            }

        ITEM_MANA_TONIC:
            return {
                "id": ITEM_MANA_TONIC,
                "name": "Mana Tonic",
                "type": "consumable",

                # HUD / inventory display
                "icon_path": "",

                # Consumable use rules
                "consumable_effect": "restore_mana",
                "target_type": "self",
                "consumed_on_use": true,
                "use_cooldown": 0.0,

                # Resource gains
                "heal_amount": 0,
                "mana_gain": 10,
                "stamina_gain": 0,

                # Future hooks
                "status_effects_to_apply": [],
                "status_effects_to_remove": [],
                "damage_resistances": DamageTypes.NONE,
                "damage_weaknesses": DamageTypes.NONE,
                "duration": 0.0,

                # Feedback
                "use_message": "You drink a Mana Tonic and recover 10 mana."
            }

        _:
            return {}


static func is_consumable(item_id: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    return item_data.get("type", "") == "consumable"

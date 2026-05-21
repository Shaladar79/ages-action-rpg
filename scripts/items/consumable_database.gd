extends RefCounted
class_name ConsumableDatabase

const ITEM_TEST_HEALING_HERB: String = "test_healing_herb"


static func get_item_data(item_id: String) -> Dictionary:
    match item_id:
        ITEM_TEST_HEALING_HERB:
            return {
                "id": ITEM_TEST_HEALING_HERB,
                "name": "Test Healing Herb",
                "type": "consumable",
                "consumable_effect": "heal",
                "heal_amount": 10,
                "consumed_on_use": true
            }

        _:
            return {}


static func is_consumable(item_id: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    return item_data.get("type", "") == "consumable"

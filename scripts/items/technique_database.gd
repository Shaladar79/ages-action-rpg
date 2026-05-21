extends RefCounted
class_name TechniqueDatabase


static func get_item_data(_item_id: String) -> Dictionary:
    return {}


static func is_technique_manual(item_id: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    return item_data.get("type", "") == "technique_manual"

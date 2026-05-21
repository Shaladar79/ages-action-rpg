extends RefCounted
class_name SpellBookDatabase


static func get_item_data(_item_id: String) -> Dictionary:
    return {}


static func is_spell_book(item_id: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    return item_data.get("type", "") == "spell_book"

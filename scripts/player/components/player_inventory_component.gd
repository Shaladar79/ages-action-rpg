extends RefCounted
class_name PlayerInventoryComponent

var player: Node = null


func setup(owner_player: Node) -> void:
    player = owner_player


func add_inventory_item(item_id: String, item_name: String, quantity: int = 1) -> void:
    if player == null:
        return

    if bool(player.get("is_defeated")):
        return

    var clean_item_id := item_id.strip_edges()

    if clean_item_id == "":
        return

    var safe_quantity: int = maxi(1, quantity)
    var clean_item_name := item_name.strip_edges()

    if clean_item_name == "":
        clean_item_name = ItemDatabase.get_item_name(clean_item_id)

    var inventory: Array = player.get("inventory")

    if _is_stackable_inventory_item(clean_item_id):
        for index in range(inventory.size()):
            var item: Dictionary = inventory[index]
            var current_item_id: String = str(item.get("id", ""))

            if current_item_id == clean_item_id:
                var current_quantity: int = int(item.get("quantity", 1))
                item["quantity"] = current_quantity + safe_quantity
                item["name"] = clean_item_name
                inventory[index] = item
                player.set("inventory", inventory)

                print("Stacked inventory item: ", clean_item_name, " x", item["quantity"])
                _show_reward_notification("Received: " + clean_item_name + " x" + str(safe_quantity))
                _handle_spell_book_acquisition(clean_item_id)
                _handle_key_item_acquisition(clean_item_id)
                _notify_ui_stats_changed()
                return

        inventory.append({
            "id": clean_item_id,
            "name": clean_item_name,
            "quantity": safe_quantity
        })
        player.set("inventory", inventory)

        print("Added stackable inventory item: ", clean_item_name, " x", safe_quantity)
        _show_reward_notification("Received: " + clean_item_name + " x" + str(safe_quantity))
        _handle_spell_book_acquisition(clean_item_id)
        _handle_key_item_acquisition(clean_item_id)
        _notify_ui_stats_changed()
        return

    if has_inventory_item(clean_item_id):
        print("Inventory already has item: ", clean_item_name)
        _handle_spell_book_acquisition(clean_item_id)
        _handle_key_item_acquisition(clean_item_id)
        _notify_ui_stats_changed()
        return

    inventory.append({
        "id": clean_item_id,
        "name": clean_item_name,
        "quantity": 1
    })
    player.set("inventory", inventory)

    print("Added to inventory: ", clean_item_name)
    _show_reward_notification("Received: " + clean_item_name)
    _handle_spell_book_acquisition(clean_item_id)
    _handle_key_item_acquisition(clean_item_id)
    _notify_ui_stats_changed()


func remove_inventory_item(item_id: String, quantity: int = 1) -> bool:
    if player == null:
        return false

    var clean_item_id := item_id.strip_edges()

    if clean_item_id == "":
        return false

    var safe_quantity: int = maxi(1, quantity)
    var inventory: Array = player.get("inventory")

    for index in range(inventory.size()):
        var item: Dictionary = inventory[index]
        var current_item_id: String = str(item.get("id", ""))

        if current_item_id != clean_item_id:
            continue

        if _is_stackable_inventory_item(clean_item_id):
            var current_quantity: int = int(item.get("quantity", 1))
            var new_quantity: int = current_quantity - safe_quantity

            if new_quantity > 0:
                item["quantity"] = new_quantity
                inventory[index] = item
                player.set("inventory", inventory)

                print("Removed from stack: ", clean_item_id, " remaining: ", new_quantity)
                _notify_ui_stats_changed()
                return true

        inventory.remove_at(index)
        player.set("inventory", inventory)

        print("Removed from inventory: ", clean_item_id)

        if player.has_method("_clear_hotbar_slots_for_missing_item"):
            player._clear_hotbar_slots_for_missing_item(clean_item_id)

        if player.has_method("_unequip_missing_item_if_needed"):
            player._unequip_missing_item_if_needed(clean_item_id)

        _notify_ui_stats_changed()
        return true

    return false


func has_inventory_item(item_id: String) -> bool:
    if player == null:
        return false

    var clean_item_id := item_id.strip_edges()

    if clean_item_id == "":
        return false

    var inventory: Array = player.get("inventory")

    for item in inventory:
        if str(item.get("id", "")) != clean_item_id:
            continue

        var quantity: int = int(item.get("quantity", 1))

        if quantity > 0:
            return true

    return false


func has_inventory_quantity(item_id: String, required_quantity: int) -> bool:
    if player == null:
        return false

    var clean_item_id := item_id.strip_edges()

    if clean_item_id == "":
        return false

    var safe_required_quantity: int = maxi(1, required_quantity)
    var inventory: Array = player.get("inventory")

    for item in inventory:
        if str(item.get("id", "")) != clean_item_id:
            continue

        var quantity: int = int(item.get("quantity", 1))
        return quantity >= safe_required_quantity

    return false


func get_inventory_item_name(item_id: String) -> String:
    if player == null:
        return item_id

    var inventory: Array = player.get("inventory")

    for item in inventory:
        if item.get("id", "") == item_id:
            return item.get("name", item_id)

    return item_id


func get_inventory_items() -> Array[Dictionary]:
    if player == null:
        return []

    return player.get("inventory")


func set_inventory_items(saved_inventory: Array) -> void:
    if player == null:
        return

    var inventory: Array[Dictionary] = []

    player.set("inventory", inventory)

    for item in saved_inventory:
        if typeof(item) != TYPE_DICTIONARY:
            continue

        var item_id: String = str(item.get("id", ""))
        var item_name: String = str(item.get("name", item_id))
        var quantity: int = int(item.get("quantity", 1))

        if item_id.strip_edges() == "":
            continue

        quantity = maxi(1, quantity)

        if _is_stackable_inventory_item(item_id):
            _add_loaded_stackable_inventory_item(item_id, item_name, quantity)
        else:
            inventory = player.get("inventory")
            inventory.append({
                "id": item_id,
                "name": item_name,
                "quantity": 1
            })
            player.set("inventory", inventory)

    if player.has_method("_ensure_starting_equipment"):
        player._ensure_starting_equipment()

    if player.has_method("_validate_equipment_after_inventory_load"):
        player._validate_equipment_after_inventory_load()

    var final_inventory: Array = player.get("inventory")
    print("Inventory loaded. Item count: ", final_inventory.size())

    _notify_ui_stats_changed()


func _add_loaded_stackable_inventory_item(item_id: String, item_name: String, quantity: int) -> void:
    if player == null:
        return

    var clean_item_id := item_id.strip_edges()

    if clean_item_id == "":
        return

    var safe_quantity: int = maxi(1, quantity)
    var inventory: Array = player.get("inventory")

    for index in range(inventory.size()):
        var item: Dictionary = inventory[index]
        var current_item_id: String = str(item.get("id", ""))

        if current_item_id == clean_item_id:
            var current_quantity: int = int(item.get("quantity", 1))
            item["quantity"] = current_quantity + safe_quantity
            item["name"] = item_name
            inventory[index] = item
            player.set("inventory", inventory)
            return

    inventory.append({
        "id": clean_item_id,
        "name": item_name,
        "quantity": safe_quantity
    })
    player.set("inventory", inventory)


func _is_stackable_inventory_item(item_id: String) -> bool:
    var clean_item_id := item_id.strip_edges()

    if clean_item_id == "":
        return false

    return ItemDatabase.is_stackable_item(clean_item_id)


func _show_reward_notification(message: String) -> void:
    if player != null and player.has_method("_show_reward_notification"):
        player._show_reward_notification(message)


func _handle_spell_book_acquisition(item_id: String) -> void:
    if player != null and player.has_method("_handle_spell_book_acquisition"):
        player._handle_spell_book_acquisition(item_id)


func _handle_key_item_acquisition(item_id: String) -> void:
    if player != null and player.has_method("_handle_key_item_acquisition"):
        player._handle_key_item_acquisition(item_id)


func _notify_ui_stats_changed() -> void:
    if player != null and player.has_method("_notify_ui_stats_changed"):
        player._notify_ui_stats_changed()

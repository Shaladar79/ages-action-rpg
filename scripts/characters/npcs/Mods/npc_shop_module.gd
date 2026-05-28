extends NPCBehaviorModule
class_name NPCShopModule

@export_group("Shop Identity")
@export var shop_name: String = "Village Supplies"

@export_group("Shop Stock")
@export var stock: Array[ShopStockEntry] = []

@export_group("Behavior")
@export var enabled: bool = true
@export var interaction_priority: int = 90

@export_group("Debug")
@export var debug_prints: bool = true


func can_handle_interact(_player: Node) -> bool:
    if not enabled:
        return false

    return true


func handle_interact(player: Node) -> bool:
    if not can_handle_interact(player):
        return false

    if player == null:
        return false

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_shop"):
        game_ui.show_shop(self, get_shop_data())

        if npc_actor != null and npc_actor.has_method("_hide_interaction_prompt"):
            npc_actor._hide_interaction_prompt()

        return true

    _show_shop_message("Shop UI is not ready yet.")
    return true


func set_behavior_enabled(new_enabled: bool) -> void:
    enabled = new_enabled


func get_interaction_priority() -> int:
    return interaction_priority


func get_shop_data() -> Dictionary:
    return {
        "shop_name": shop_name,
        "slots": get_available_stock_rows()
    }


func get_available_stock_rows() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []

    for stock_index in range(stock.size()):
        var entry: ShopStockEntry = stock[stock_index]

        if entry == null:
            continue

        var item_id := entry.item_id.strip_edges()

        if item_id == "":
            continue

        if not _entry_is_unlocked(entry):
            if debug_prints:
                print("Shop item hidden by missing flag: ", item_id, " required flag: ", entry.required_flag)

            continue

        var bundle_quantity: int = maxi(1, entry.quantity)
        var buy_price: int = maxi(0, entry.buy_price)

        rows.append({
            "stock_index": stock_index,
            "item_id": item_id,
            "item_name": ItemDatabase.get_item_name(item_id),
            "quantity": bundle_quantity,
            "buy_price": buy_price,
            "required_flag": entry.required_flag.strip_edges()
        })

    return rows


func get_sell_rows(player: Node) -> Array[Dictionary]:
    var rows: Array[Dictionary] = []

    if player == null:
        return rows

    if not player.has_method("get_inventory_items"):
        return rows

    var inventory_items: Array = player.get_inventory_items()

    for item in inventory_items:
        if typeof(item) != TYPE_DICTIONARY:
            continue

        var item_id: String = str(item.get("id", "")).strip_edges()

        if item_id == "":
            continue

        var sell_entry := _get_sell_entry_for_item(item_id)

        if sell_entry == null:
            continue

        var inventory_quantity: int = int(item.get("quantity", 1))
        inventory_quantity = maxi(1, inventory_quantity)

        var sell_price: int = maxi(0, sell_entry.sell_price)

        if sell_price <= 0:
            continue

        rows.append({
            "item_id": item_id,
            "item_name": str(item.get("name", ItemDatabase.get_item_name(item_id))),
            "inventory_quantity": inventory_quantity,
            "sell_price": sell_price
        })

    return rows


func buy_stock_index(stock_index: int, player: Node, purchase_count: int = 1) -> bool:
    if player == null:
        return false

    if stock_index < 0 or stock_index >= stock.size():
        return false

    var entry: ShopStockEntry = stock[stock_index]

    if entry == null:
        return false

    if not _entry_is_unlocked(entry):
        _show_shop_message("That item is not available yet.")
        return false

    var item_id := entry.item_id.strip_edges()

    if item_id == "":
        return false

    var safe_purchase_count: int = maxi(1, purchase_count)
    var bundle_quantity: int = maxi(1, entry.quantity)
    var total_item_quantity: int = bundle_quantity * safe_purchase_count
    var total_price: int = maxi(0, entry.buy_price) * safe_purchase_count

    if total_price > 0:
        if not _player_spend_marks(player, total_price):
            _show_shop_message("You do not have enough Marks.")
            return false

    if not player.has_method("add_inventory_item"):
        _show_shop_message("You cannot receive items yet.")
        return false

    var item_name := ItemDatabase.get_item_name(item_id)
    player.add_inventory_item(item_id, item_name, total_item_quantity)

    _show_shop_message("Bought " + item_name + " x" + str(total_item_quantity) + ".")

    if debug_prints:
        print("Shop purchase: ", item_name, " x", total_item_quantity, " for ", total_price, " Marks")

    return true


func buy_available_slot(available_slot_index: int, player: Node, purchase_count: int = 1) -> bool:
    var rows := get_available_stock_rows()

    if available_slot_index < 0 or available_slot_index >= rows.size():
        return false

    var row: Dictionary = rows[available_slot_index]
    var stock_index: int = int(row.get("stock_index", -1))

    return buy_stock_index(stock_index, player, purchase_count)


func sell_item_id(item_id: String, player: Node, sell_quantity: int = 1) -> bool:
    if player == null:
        return false

    var clean_item_id := item_id.strip_edges()

    if clean_item_id == "":
        return false

    var sell_entry := _get_sell_entry_for_item(clean_item_id)

    if sell_entry == null:
        _show_shop_message("This shop will not buy that item.")
        return false

    var safe_sell_quantity: int = maxi(1, sell_quantity)

    if not _player_has_item_quantity(player, clean_item_id, safe_sell_quantity):
        _show_shop_message("You do not have enough to sell.")
        return false

    if not player.has_method("remove_inventory_item"):
        _show_shop_message("You cannot sell items yet.")
        return false

    var removed: bool = player.remove_inventory_item(clean_item_id, safe_sell_quantity)

    if not removed:
        _show_shop_message("Could not remove item from inventory.")
        return false

    var total_marks: int = maxi(0, sell_entry.sell_price) * safe_sell_quantity

    if total_marks > 0:
        _player_add_marks(player, total_marks)

    var item_name := ItemDatabase.get_item_name(clean_item_id)
    _show_shop_message("Sold " + item_name + " x" + str(safe_sell_quantity) + " for " + str(total_marks) + " Marks.")

    if debug_prints:
        print("Shop sale: ", item_name, " x", safe_sell_quantity, " for ", total_marks, " Marks")

    return true


func sell_row_index(sell_row_index: int, player: Node, sell_quantity: int = 1) -> bool:
    var rows := get_sell_rows(player)

    if sell_row_index < 0 or sell_row_index >= rows.size():
        return false

    var row: Dictionary = rows[sell_row_index]
    var item_id: String = str(row.get("item_id", ""))

    return sell_item_id(item_id, player, sell_quantity)


func _get_sell_entry_for_item(item_id: String) -> ShopStockEntry:
    var clean_item_id := item_id.strip_edges()

    if clean_item_id == "":
        return null

    for entry in stock:
        if entry == null:
            continue

        if not entry.shop_will_buy_item:
            continue

        if not _entry_is_unlocked(entry):
            continue

        if entry.item_id.strip_edges() != clean_item_id:
            continue

        return entry

    return null


func _player_has_item_quantity(player: Node, item_id: String, required_quantity: int) -> bool:
    if player == null:
        return false

    if not player.has_method("get_inventory_items"):
        return false

    var safe_required_quantity: int = maxi(1, required_quantity)
    var inventory_items: Array = player.get_inventory_items()

    for item in inventory_items:
        if typeof(item) != TYPE_DICTIONARY:
            continue

        if str(item.get("id", "")).strip_edges() != item_id:
            continue

        var quantity: int = int(item.get("quantity", 1))
        return quantity >= safe_required_quantity

    return false


func _player_spend_marks(player: Node, amount: int) -> bool:
    if player == null:
        return false

    if amount <= 0:
        return true

    if player.has_method("spend_marks"):
        return player.spend_marks(amount)

    if player.has_method("spend_currency"):
        return player.spend_currency("marks", amount)

    return false


func _player_add_marks(player: Node, amount: int) -> bool:
    if player == null:
        return false

    if amount <= 0:
        return false

    if player.has_method("add_marks"):
        return player.add_marks(amount)

    if player.has_method("add_currency"):
        return player.add_currency("marks", amount)

    return false


func _entry_is_unlocked(entry: ShopStockEntry) -> bool:
    if entry == null:
        return false

    var required_flag := entry.required_flag.strip_edges()

    if required_flag == "":
        return true

    return SaveManager.is_flag_set(required_flag)


func _show_shop_message(message: String) -> void:
    var clean_message := message.strip_edges()

    if clean_message == "":
        return

    var game_ui := _get_game_ui()

    if game_ui != null:
        if game_ui.has_method("show_reward_notification"):
            game_ui.show_reward_notification(clean_message)
            return

        if game_ui.has_method("show_notification"):
            game_ui.show_notification(clean_message)
            return

    if debug_prints:
        print("Shop message: ", clean_message)


func _get_game_ui() -> Node:
    if npc_actor != null and npc_actor.has_method("get_game_ui"):
        return npc_actor.get_game_ui()

    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("show_shop"):
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null and autoload_ui.has_method("show_shop"):
        return autoload_ui

    return null

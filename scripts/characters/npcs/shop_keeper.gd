extends Area2D
class_name ShopKeeper

@export_group("Shop Identity")
@export var shop_name: String = "Village Supplies"
@export var interaction_prompt_text: String = "E"

@export_group("Shop Stock")
@export var stock: Array[ShopStockEntry] = []

@export_group("Debug")
@export var debug_prints: bool = true

var nearby_player: Node = null


func _ready() -> void:
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)

    if not body_exited.is_connected(_on_body_exited):
        body_exited.connect(_on_body_exited)


func interact(player: Node) -> void:
    if player == null:
        return

    nearby_player = player

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_shop"):
        game_ui.show_shop(self, get_shop_data())
        _hide_interaction_prompt()
        return

    _show_player_message(player, "Shop UI is not ready yet.")


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

        var quantity: int = maxi(1, entry.quantity)
        var price_amount: int = maxi(0, entry.price_amount)
        var price_currency := entry.price_currency.strip_edges()

        if price_currency == "":
            price_currency = "shines"

        rows.append({
            "stock_index": stock_index,
            "item_id": item_id,
            "item_name": ItemDatabase.get_item_name(item_id),
            "quantity": quantity,
            "price_currency": price_currency,
            "price_currency_name": _format_currency_name(price_currency),
            "price_amount": price_amount,
            "required_flag": entry.required_flag.strip_edges()
        })

    return rows


func buy_stock_index(stock_index: int, player: Node) -> bool:
    if player == null:
        return false

    if stock_index < 0 or stock_index >= stock.size():
        return false

    var entry: ShopStockEntry = stock[stock_index]

    if entry == null:
        return false

    if not _entry_is_unlocked(entry):
        _show_player_message(player, "That item is not available yet.")
        return false

    var item_id := entry.item_id.strip_edges()

    if item_id == "":
        return false

    var quantity: int = maxi(1, entry.quantity)
    var price_currency := entry.price_currency.strip_edges()

    if price_currency == "":
        price_currency = "shines"

    var price_amount: int = maxi(0, entry.price_amount)

    if price_amount > 0:
        if not player.has_method("spend_currency"):
            _show_player_message(player, "You cannot spend currency yet.")
            return false

        var paid: bool = player.spend_currency(price_currency, price_amount)

        if not paid:
            _show_player_message(player, "You do not have enough " + _format_currency_name(price_currency) + ".")
            return false

    if not player.has_method("add_inventory_item"):
        _show_player_message(player, "You cannot receive items yet.")
        return false

    var item_name := ItemDatabase.get_item_name(item_id)
    player.add_inventory_item(item_id, item_name, quantity)

    _show_player_message(player, "Bought " + item_name + " x" + str(quantity) + ".")

    if debug_prints:
        print("Shop purchase: ", item_name, " x", quantity, " for ", price_amount, " ", price_currency)

    return true


func buy_available_slot(available_slot_index: int, player: Node) -> bool:
    var rows := get_available_stock_rows()

    if available_slot_index < 0 or available_slot_index >= rows.size():
        return false

    var row: Dictionary = rows[available_slot_index]
    var stock_index: int = int(row.get("stock_index", -1))

    return buy_stock_index(stock_index, player)


func _entry_is_unlocked(entry: ShopStockEntry) -> bool:
    if entry == null:
        return false

    var required_flag := entry.required_flag.strip_edges()

    if required_flag == "":
        return true

    return SaveManager.is_flag_set(required_flag)


func _format_currency_name(currency_id: String) -> String:
    var clean_currency_id := currency_id.strip_edges()

    if clean_currency_id == "":
        return "Currency"

    if nearby_player != null and nearby_player.has_method("get_currency_display_name"):
        return nearby_player.get_currency_display_name(clean_currency_id)

    return clean_currency_id.replace("_", " ").capitalize()


func _show_player_message(player: Node, message: String) -> void:
    if player == null:
        return

    if player.has_method("show_dialogue"):
        player.show_dialogue(message)


func _get_game_ui() -> Node:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("show_shop"):
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null and autoload_ui.has_method("show_shop"):
        return autoload_ui

    return null


func _show_interaction_prompt() -> void:
    var game_ui := get_tree().get_first_node_in_group("interaction_ui")

    if game_ui == null:
        return

    if game_ui.has_method("show_prompt"):
        game_ui.show_prompt(interaction_prompt_text)


func _hide_interaction_prompt() -> void:
    var game_ui := get_tree().get_first_node_in_group("interaction_ui")

    if game_ui == null:
        return

    if game_ui.has_method("hide_prompt"):
        game_ui.hide_prompt()


func _on_body_entered(body: Node) -> void:
    if body == null:
        return

    if not body.is_in_group("player"):
        return

    nearby_player = body

    if body.has_method("set_nearby_interactable"):
        body.set_nearby_interactable(self)

    _show_interaction_prompt()

    if debug_prints:
        print("Player entered shop interaction range: ", shop_name)


func _on_body_exited(body: Node) -> void:
    if body != nearby_player:
        return

    if body.has_method("clear_nearby_interactable"):
        body.clear_nearby_interactable(self)

    nearby_player = null
    _hide_interaction_prompt()

    if debug_prints:
        print("Player left shop interaction range: ", shop_name)

extends RefCounted
class_name ShopUiController

enum ShopMode {
    BUY,
    SELL
}

var root_ui: CanvasLayer = null
var player_getter: Callable = Callable()

var shop_layer: Control = null
var shop_panel: Panel = null
var shop_title_label: Label = null
var shop_mode_label: Label = null
var shop_rows_container: VBoxContainer = null
var shop_status_label: Label = null
var shop_close_button: Button = null
var shop_buy_mode_button: Button = null
var shop_sell_mode_button: Button = null
var quantity_label: Label = null
var quantity_minus_button: Button = null
var quantity_plus_button: Button = null

var active_shop_keeper: Node = null
var active_shop_data: Dictionary = {}
var shop_action_buttons: Array[Button] = []

var current_mode: ShopMode = ShopMode.BUY
var selected_quantity: int = 1


func setup(ui_root: CanvasLayer, get_player_callable: Callable) -> void:
    root_ui = ui_root
    player_getter = get_player_callable
    _create_shop_panel()


func show_shop(shop_keeper: Node, shop_data: Dictionary) -> void:
    if shop_layer == null:
        _create_shop_panel()

    if root_ui != null:
        if root_ui.has_method("is_save_prompt_visible"):
            if root_ui.is_save_prompt_visible():
                return

        if root_ui.has_method("close_character_screen"):
            root_ui.close_character_screen()

        if root_ui.has_method("is_story_dialogue_active"):
            if root_ui.is_story_dialogue_active() and root_ui.has_method("hide_story_dialogue"):
                root_ui.hide_story_dialogue()

        if root_ui.has_method("hide_prompt"):
            root_ui.hide_prompt()

    active_shop_keeper = shop_keeper
    active_shop_data = shop_data.duplicate(true)
    current_mode = ShopMode.BUY
    selected_quantity = 1

    if shop_layer != null:
        shop_layer.visible = true

    if root_ui != null and root_ui.has_method("_set_shop_pause"):
        root_ui._set_shop_pause(true)

    _refresh_mode_buttons()
    _refresh_quantity_label()
    _rebuild_shop_rows()

    print("Shop opened: ", str(active_shop_data.get("shop_name", "Shop")))


func hide_shop() -> void:
    active_shop_keeper = null
    active_shop_data.clear()
    shop_action_buttons.clear()
    selected_quantity = 1
    current_mode = ShopMode.BUY

    if shop_rows_container != null:
        for child in shop_rows_container.get_children():
            child.queue_free()

    if shop_status_label != null:
        shop_status_label.text = ""

    if shop_layer != null:
        shop_layer.visible = false

    if root_ui != null and root_ui.has_method("_set_shop_pause"):
        root_ui._set_shop_pause(false)

    print("Shop closed.")


func is_visible() -> bool:
    if shop_layer == null:
        return false

    return shop_layer.visible


func _create_shop_panel() -> void:
    if shop_layer != null:
        return

    if root_ui == null:
        push_warning("Cannot create shop panel. Root UI is null.")
        return

    shop_layer = Control.new()
    shop_layer.name = "ShopLayer"
    shop_layer.anchor_left = 0.0
    shop_layer.anchor_right = 1.0
    shop_layer.anchor_top = 0.0
    shop_layer.anchor_bottom = 1.0
    shop_layer.offset_left = 0.0
    shop_layer.offset_right = 0.0
    shop_layer.offset_top = 0.0
    shop_layer.offset_bottom = 0.0
    shop_layer.mouse_filter = Control.MOUSE_FILTER_STOP
    shop_layer.visible = false

    root_ui.add_child(shop_layer)

    shop_panel = Panel.new()
    shop_panel.name = "ShopPanel"
    shop_panel.anchor_left = 0.5
    shop_panel.anchor_right = 0.5
    shop_panel.anchor_top = 0.5
    shop_panel.anchor_bottom = 0.5
    shop_panel.offset_left = -340.0
    shop_panel.offset_right = 340.0
    shop_panel.offset_top = -250.0
    shop_panel.offset_bottom = 250.0
    shop_panel.custom_minimum_size = Vector2(680.0, 500.0)
    shop_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    shop_layer.add_child(shop_panel)

    var margin := MarginContainer.new()
    margin.name = "ShopMargin"
    margin.anchor_left = 0.0
    margin.anchor_right = 1.0
    margin.anchor_top = 0.0
    margin.anchor_bottom = 1.0
    margin.offset_left = 14.0
    margin.offset_right = -14.0
    margin.offset_top = 14.0
    margin.offset_bottom = -14.0
    shop_panel.add_child(margin)

    var main_vbox := VBoxContainer.new()
    main_vbox.name = "ShopVBox"
    margin.add_child(main_vbox)

    shop_title_label = Label.new()
    shop_title_label.name = "ShopTitleLabel"
    shop_title_label.text = "Shop"
    shop_title_label.add_theme_font_size_override("font_size", 20)
    main_vbox.add_child(shop_title_label)

    var mode_row := HBoxContainer.new()
    mode_row.name = "ShopModeRow"
    mode_row.custom_minimum_size = Vector2(640.0, 36.0)
    main_vbox.add_child(mode_row)

    shop_buy_mode_button = Button.new()
    shop_buy_mode_button.name = "BuyModeButton"
    shop_buy_mode_button.text = "Buy"
    shop_buy_mode_button.custom_minimum_size = Vector2(90.0, 30.0)
    shop_buy_mode_button.focus_mode = Control.FOCUS_NONE
    shop_buy_mode_button.pressed.connect(_on_buy_mode_pressed)
    mode_row.add_child(shop_buy_mode_button)

    shop_sell_mode_button = Button.new()
    shop_sell_mode_button.name = "SellModeButton"
    shop_sell_mode_button.text = "Sell"
    shop_sell_mode_button.custom_minimum_size = Vector2(90.0, 30.0)
    shop_sell_mode_button.focus_mode = Control.FOCUS_NONE
    shop_sell_mode_button.pressed.connect(_on_sell_mode_pressed)
    mode_row.add_child(shop_sell_mode_button)

    shop_mode_label = Label.new()
    shop_mode_label.name = "ShopModeLabel"
    shop_mode_label.text = "Mode: Buy"
    shop_mode_label.custom_minimum_size = Vector2(180.0, 30.0)
    mode_row.add_child(shop_mode_label)

    var quantity_row := HBoxContainer.new()
    quantity_row.name = "ShopQuantityRow"
    quantity_row.custom_minimum_size = Vector2(640.0, 36.0)
    main_vbox.add_child(quantity_row)

    var quantity_title := Label.new()
    quantity_title.name = "QuantityTitle"
    quantity_title.text = "Quantity:"
    quantity_title.custom_minimum_size = Vector2(80.0, 30.0)
    quantity_row.add_child(quantity_title)

    quantity_minus_button = Button.new()
    quantity_minus_button.name = "QuantityMinusButton"
    quantity_minus_button.text = "-"
    quantity_minus_button.custom_minimum_size = Vector2(42.0, 30.0)
    quantity_minus_button.focus_mode = Control.FOCUS_NONE
    quantity_minus_button.pressed.connect(_on_quantity_minus_pressed)
    quantity_row.add_child(quantity_minus_button)

    quantity_label = Label.new()
    quantity_label.name = "QuantityLabel"
    quantity_label.text = "1"
    quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    quantity_label.custom_minimum_size = Vector2(60.0, 30.0)
    quantity_row.add_child(quantity_label)

    quantity_plus_button = Button.new()
    quantity_plus_button.name = "QuantityPlusButton"
    quantity_plus_button.text = "+"
    quantity_plus_button.custom_minimum_size = Vector2(42.0, 30.0)
    quantity_plus_button.focus_mode = Control.FOCUS_NONE
    quantity_plus_button.pressed.connect(_on_quantity_plus_pressed)
    quantity_row.add_child(quantity_plus_button)

    var scroll := ScrollContainer.new()
    scroll.name = "ShopScroll"
    scroll.custom_minimum_size = Vector2(640.0, 330.0)
    main_vbox.add_child(scroll)

    shop_rows_container = VBoxContainer.new()
    shop_rows_container.name = "ShopRows"
    scroll.add_child(shop_rows_container)

    shop_status_label = Label.new()
    shop_status_label.name = "ShopStatusLabel"
    shop_status_label.text = ""
    shop_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    shop_status_label.custom_minimum_size = Vector2(640.0, 36.0)
    main_vbox.add_child(shop_status_label)

    shop_close_button = Button.new()
    shop_close_button.name = "ShopCloseButton"
    shop_close_button.text = "Close"
    shop_close_button.focus_mode = Control.FOCUS_NONE
    shop_close_button.pressed.connect(hide_shop)
    main_vbox.add_child(shop_close_button)


func _on_buy_mode_pressed() -> void:
    current_mode = ShopMode.BUY
    selected_quantity = 1
    _refresh_mode_buttons()
    _refresh_quantity_label()
    _rebuild_shop_rows()


func _on_sell_mode_pressed() -> void:
    current_mode = ShopMode.SELL
    selected_quantity = 1
    _refresh_mode_buttons()
    _refresh_quantity_label()
    _rebuild_shop_rows()


func _on_quantity_minus_pressed() -> void:
    selected_quantity = maxi(1, selected_quantity - 1)
    _refresh_quantity_label()
    _rebuild_shop_rows()


func _on_quantity_plus_pressed() -> void:
    selected_quantity = mini(99, selected_quantity + 1)
    _refresh_quantity_label()
    _rebuild_shop_rows()


func _refresh_mode_buttons() -> void:
    if shop_buy_mode_button != null:
        shop_buy_mode_button.disabled = current_mode == ShopMode.BUY

    if shop_sell_mode_button != null:
        shop_sell_mode_button.disabled = current_mode == ShopMode.SELL

    if shop_mode_label != null:
        if current_mode == ShopMode.BUY:
            shop_mode_label.text = "Mode: Buy"
        else:
            shop_mode_label.text = "Mode: Sell"


func _refresh_quantity_label() -> void:
    if quantity_label != null:
        quantity_label.text = str(selected_quantity)


func _rebuild_shop_rows() -> void:
    if shop_rows_container == null:
        return

    for child in shop_rows_container.get_children():
        child.queue_free()

    shop_action_buttons.clear()

    if active_shop_keeper != null and active_shop_keeper.has_method("get_shop_data"):
        active_shop_data = active_shop_keeper.get_shop_data()

    var shop_name: String = str(active_shop_data.get("shop_name", "Shop"))

    if shop_title_label != null:
        shop_title_label.text = shop_name

    if current_mode == ShopMode.BUY:
        _rebuild_buy_rows()
    else:
        _rebuild_sell_rows()


func _rebuild_buy_rows() -> void:
    var slots: Array = active_shop_data.get("slots", [])

    if slots.is_empty():
        var empty_label := Label.new()
        empty_label.text = "This shop has nothing for sale right now."
        shop_rows_container.add_child(empty_label)
        return

    for available_index in range(slots.size()):
        var row_data: Dictionary = slots[available_index]

        var item_name: String = str(row_data.get("item_name", "Unknown Item"))
        var bundle_quantity: int = int(row_data.get("quantity", 1))
        var buy_price: int = int(row_data.get("buy_price", 0))
        var stock_index: int = int(row_data.get("stock_index", available_index))

        bundle_quantity = maxi(1, bundle_quantity)
        buy_price = maxi(0, buy_price)

        var total_quantity: int = bundle_quantity * selected_quantity
        var total_price: int = buy_price * selected_quantity

        var row := HBoxContainer.new()
        row.name = "BuyShopRow" + str(available_index)
        row.custom_minimum_size = Vector2(620.0, 36.0)

        var item_label := Label.new()
        item_label.name = "ItemLabel"
        item_label.custom_minimum_size = Vector2(280.0, 30.0)

        if total_quantity > 1:
            item_label.text = item_name + " x" + str(total_quantity)
        else:
            item_label.text = item_name

        row.add_child(item_label)

        var price_label := Label.new()
        price_label.name = "PriceLabel"
        price_label.custom_minimum_size = Vector2(170.0, 30.0)

        if total_price <= 0:
            price_label.text = "Free"
        else:
            price_label.text = str(total_price) + " Marks"

        row.add_child(price_label)

        var buy_button := Button.new()
        buy_button.name = "BuyButton" + str(available_index)
        buy_button.text = "Buy"
        buy_button.custom_minimum_size = Vector2(80.0, 30.0)
        buy_button.focus_mode = Control.FOCUS_NONE
        buy_button.pressed.connect(_on_shop_buy_button_pressed.bind(stock_index))
        row.add_child(buy_button)

        shop_rows_container.add_child(row)
        shop_action_buttons.append(buy_button)


func _rebuild_sell_rows() -> void:
    if active_shop_keeper == null:
        return

    if not active_shop_keeper.has_method("get_sell_rows"):
        var missing_label := Label.new()
        missing_label.text = "This shop cannot buy items yet."
        shop_rows_container.add_child(missing_label)
        return

    var player := _get_player()

    if player == null:
        var no_player_label := Label.new()
        no_player_label.text = "No player found."
        shop_rows_container.add_child(no_player_label)
        return

    var sell_rows: Array = active_shop_keeper.get_sell_rows(player)

    if sell_rows.is_empty():
        var empty_label := Label.new()
        empty_label.text = "You have nothing this shop wants to buy."
        shop_rows_container.add_child(empty_label)
        return

    for sell_index in range(sell_rows.size()):
        var row_data: Dictionary = sell_rows[sell_index]

        var item_name: String = str(row_data.get("item_name", "Unknown Item"))
        var inventory_quantity: int = int(row_data.get("inventory_quantity", 1))
        var sell_price: int = int(row_data.get("sell_price", 0))
        var item_id: String = str(row_data.get("item_id", ""))

        inventory_quantity = maxi(1, inventory_quantity)
        sell_price = maxi(0, sell_price)

        var sell_quantity: int = mini(selected_quantity, inventory_quantity)
        var total_price: int = sell_price * sell_quantity

        var row := HBoxContainer.new()
        row.name = "SellShopRow" + str(sell_index)
        row.custom_minimum_size = Vector2(620.0, 36.0)

        var item_label := Label.new()
        item_label.name = "ItemLabel"
        item_label.custom_minimum_size = Vector2(280.0, 30.0)
        item_label.text = item_name + " x" + str(sell_quantity) + " / " + str(inventory_quantity)
        row.add_child(item_label)

        var price_label := Label.new()
        price_label.name = "PriceLabel"
        price_label.custom_minimum_size = Vector2(170.0, 30.0)
        price_label.text = str(total_price) + " Marks"
        row.add_child(price_label)

        var sell_button := Button.new()
        sell_button.name = "SellButton" + str(sell_index)
        sell_button.text = "Sell"
        sell_button.custom_minimum_size = Vector2(80.0, 30.0)
        sell_button.focus_mode = Control.FOCUS_NONE
        sell_button.disabled = item_id.strip_edges() == "" or total_price <= 0
        sell_button.pressed.connect(_on_shop_sell_button_pressed.bind(sell_index, sell_quantity))
        row.add_child(sell_button)

        shop_rows_container.add_child(row)
        shop_action_buttons.append(sell_button)


func _on_shop_buy_button_pressed(stock_index: int) -> void:
    if active_shop_keeper == null:
        return

    var player := _get_player()

    if player == null:
        return

    if not active_shop_keeper.has_method("buy_stock_index"):
        if shop_status_label != null:
            shop_status_label.text = "This shop cannot sell items yet."

        return

    var bought: bool = active_shop_keeper.buy_stock_index(stock_index, player, selected_quantity)

    if bought:
        if shop_status_label != null:
            shop_status_label.text = "Purchase complete."

        if root_ui != null and root_ui.has_method("refresh_character_display"):
            root_ui.refresh_character_display()

        _rebuild_shop_rows()
    else:
        if shop_status_label != null:
            shop_status_label.text = "Could not buy that item."


func _on_shop_sell_button_pressed(sell_row_index: int, sell_quantity: int) -> void:
    if active_shop_keeper == null:
        return

    var player := _get_player()

    if player == null:
        return

    if not active_shop_keeper.has_method("sell_row_index"):
        if shop_status_label != null:
            shop_status_label.text = "This shop cannot buy items yet."

        return

    var sold: bool = active_shop_keeper.sell_row_index(sell_row_index, player, sell_quantity)

    if sold:
        if shop_status_label != null:
            shop_status_label.text = "Sale complete."

        if root_ui != null and root_ui.has_method("refresh_character_display"):
            root_ui.refresh_character_display()

        _rebuild_shop_rows()
    else:
        if shop_status_label != null:
            shop_status_label.text = "Could not sell that item."


func _get_player() -> Node:
    var player: Node = null

    if player_getter.is_valid():
        player = player_getter.call()

    return player

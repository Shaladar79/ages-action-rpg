extends RefCounted
class_name ShopUiController

var root_ui: CanvasLayer = null
var player_getter: Callable = Callable()

var shop_layer: Control = null
var shop_panel: Panel = null
var shop_title_label: Label = null
var shop_rows_container: VBoxContainer = null
var shop_status_label: Label = null
var shop_close_button: Button = null

var active_shop_keeper: Node = null
var active_shop_data: Dictionary = {}
var shop_buy_buttons: Array[Button] = []


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

    if shop_layer != null:
        shop_layer.visible = true

    if root_ui != null and root_ui.has_method("_set_shop_pause"):
        root_ui._set_shop_pause(true)

    _rebuild_shop_rows()

    print("Shop opened: ", str(active_shop_data.get("shop_name", "Shop")))


func hide_shop() -> void:
    active_shop_keeper = null
    active_shop_data.clear()
    shop_buy_buttons.clear()

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
    shop_panel.offset_left = -310.0
    shop_panel.offset_right = 310.0
    shop_panel.offset_top = -230.0
    shop_panel.offset_bottom = 230.0
    shop_panel.custom_minimum_size = Vector2(620.0, 460.0)
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

    var scroll := ScrollContainer.new()
    scroll.name = "ShopScroll"
    scroll.custom_minimum_size = Vector2(580.0, 330.0)
    main_vbox.add_child(scroll)

    shop_rows_container = VBoxContainer.new()
    shop_rows_container.name = "ShopRows"
    scroll.add_child(shop_rows_container)

    shop_status_label = Label.new()
    shop_status_label.name = "ShopStatusLabel"
    shop_status_label.text = ""
    shop_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    shop_status_label.custom_minimum_size = Vector2(580.0, 36.0)
    main_vbox.add_child(shop_status_label)

    shop_close_button = Button.new()
    shop_close_button.name = "ShopCloseButton"
    shop_close_button.text = "Close"
    shop_close_button.focus_mode = Control.FOCUS_NONE
    shop_close_button.pressed.connect(hide_shop)
    main_vbox.add_child(shop_close_button)


func _rebuild_shop_rows() -> void:
    if shop_rows_container == null:
        return

    for child in shop_rows_container.get_children():
        child.queue_free()

    shop_buy_buttons.clear()

    if active_shop_keeper != null and active_shop_keeper.has_method("get_shop_data"):
        active_shop_data = active_shop_keeper.get_shop_data()

    var shop_name: String = str(active_shop_data.get("shop_name", "Shop"))

    if shop_title_label != null:
        shop_title_label.text = shop_name

    var slots: Array = active_shop_data.get("slots", [])

    if slots.is_empty():
        var empty_label := Label.new()
        empty_label.text = "This shop has nothing for sale right now."
        shop_rows_container.add_child(empty_label)
        return

    for available_index in range(slots.size()):
        var row_data: Dictionary = slots[available_index]

        var item_name: String = str(row_data.get("item_name", "Unknown Item"))
        var quantity: int = int(row_data.get("quantity", 1))
        var price_amount: int = int(row_data.get("price_amount", 0))
        var price_currency_name: String = str(row_data.get("price_currency_name", "Currency"))
        var stock_index: int = int(row_data.get("stock_index", available_index))

        var row := HBoxContainer.new()
        row.name = "ShopRow" + str(available_index)
        row.custom_minimum_size = Vector2(560.0, 36.0)

        var item_label := Label.new()
        item_label.name = "ItemLabel"
        item_label.custom_minimum_size = Vector2(300.0, 30.0)

        if quantity > 1:
            item_label.text = item_name + " x" + str(quantity)
        else:
            item_label.text = item_name

        row.add_child(item_label)

        var price_label := Label.new()
        price_label.name = "PriceLabel"
        price_label.custom_minimum_size = Vector2(150.0, 30.0)

        if price_amount <= 0:
            price_label.text = "Free"
        else:
            price_label.text = str(price_amount) + " " + price_currency_name

        row.add_child(price_label)

        var buy_button := Button.new()
        buy_button.name = "BuyButton" + str(available_index)
        buy_button.text = "Buy"
        buy_button.custom_minimum_size = Vector2(80.0, 30.0)
        buy_button.focus_mode = Control.FOCUS_NONE
        buy_button.pressed.connect(_on_shop_buy_button_pressed.bind(stock_index))
        row.add_child(buy_button)

        shop_rows_container.add_child(row)
        shop_buy_buttons.append(buy_button)


func _on_shop_buy_button_pressed(stock_index: int) -> void:
    if active_shop_keeper == null:
        return

    var player: Node = null

    if player_getter.is_valid():
        player = player_getter.call()

    if player == null:
        return

    if not active_shop_keeper.has_method("buy_stock_index"):
        if shop_status_label != null:
            shop_status_label.text = "This shop cannot sell items yet."

        return

    var bought: bool = active_shop_keeper.buy_stock_index(stock_index, player)

    if bought:
        if shop_status_label != null:
            shop_status_label.text = "Purchase complete."

        if root_ui != null and root_ui.has_method("refresh_character_display"):
            root_ui.refresh_character_display()

        _rebuild_shop_rows()
    else:
        if shop_status_label != null:
            shop_status_label.text = "Could not buy that item."

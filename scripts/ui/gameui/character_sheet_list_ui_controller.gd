extends RefCounted
class_name CharacterSheetListUiController

var root_ui: CanvasLayer = null
var character_panel: Panel = null
var player_getter: Callable = Callable()

var sheet_list_button_container: HBoxContainer = null
var inventory_list_button: Button = null
var currency_list_button: Button = null
var faction_list_button: Button = null
var active_sheet_list_title: String = ""

var sheet_list_panel: Panel = null
var sheet_list_title_label: Label = null
var sheet_list_content_label: Label = null
var sheet_list_close_button: Button = null


func setup(ui_root: CanvasLayer, panel_node: Panel, get_player_callable: Callable) -> void:
    root_ui = ui_root
    character_panel = panel_node
    player_getter = get_player_callable

    _create_character_sheet_list_buttons()
    _create_character_sheet_list_panel()


func hide_sheet_list() -> void:
    active_sheet_list_title = ""

    if sheet_list_panel != null:
        sheet_list_panel.visible = false


func is_visible() -> bool:
    if sheet_list_panel == null:
        return false

    return sheet_list_panel.visible


func _create_character_sheet_list_buttons() -> void:
    if sheet_list_button_container != null:
        return

    if character_panel == null:
        return

    sheet_list_button_container = HBoxContainer.new()
    sheet_list_button_container.name = "SheetListButtonPanel"

    sheet_list_button_container.anchor_left = 1.0
    sheet_list_button_container.anchor_right = 1.0
    sheet_list_button_container.anchor_top = 0.0
    sheet_list_button_container.anchor_bottom = 0.0

    sheet_list_button_container.offset_left = -360.0
    sheet_list_button_container.offset_right = -40.0
    sheet_list_button_container.offset_top = 72.0
    sheet_list_button_container.offset_bottom = 112.0

    sheet_list_button_container.custom_minimum_size = Vector2(320.0, 36.0)

    inventory_list_button = Button.new()
    inventory_list_button.name = "InventoryListButton"
    inventory_list_button.text = "Inventory"
    inventory_list_button.custom_minimum_size = Vector2(100.0, 32.0)
    inventory_list_button.focus_mode = Control.FOCUS_NONE
    inventory_list_button.pressed.connect(_on_inventory_list_button_pressed)
    sheet_list_button_container.add_child(inventory_list_button)

    currency_list_button = Button.new()
    currency_list_button.name = "CurrencyListButton"
    currency_list_button.text = "Currency"
    currency_list_button.custom_minimum_size = Vector2(100.0, 32.0)
    currency_list_button.focus_mode = Control.FOCUS_NONE
    currency_list_button.pressed.connect(_on_currency_list_button_pressed)
    sheet_list_button_container.add_child(currency_list_button)

    faction_list_button = Button.new()
    faction_list_button.name = "FactionListButton"
    faction_list_button.text = "Faction"
    faction_list_button.custom_minimum_size = Vector2(100.0, 32.0)
    faction_list_button.focus_mode = Control.FOCUS_NONE
    faction_list_button.visible = false
    faction_list_button.disabled = true
    sheet_list_button_container.add_child(faction_list_button)

    character_panel.add_child(sheet_list_button_container)


func _create_character_sheet_list_panel() -> void:
    if sheet_list_panel != null:
        return

    if character_panel == null:
        return

    sheet_list_panel = Panel.new()
    sheet_list_panel.name = "SheetListPanel"

    sheet_list_panel.anchor_left = 1.0
    sheet_list_panel.anchor_right = 1.0
    sheet_list_panel.anchor_top = 0.0
    sheet_list_panel.anchor_bottom = 0.0

    sheet_list_panel.offset_left = -360.0
    sheet_list_panel.offset_right = -40.0
    sheet_list_panel.offset_top = 116.0
    sheet_list_panel.offset_bottom = 455.0

    sheet_list_panel.visible = false
    sheet_list_panel.custom_minimum_size = Vector2(320.0, 330.0)

    character_panel.add_child(sheet_list_panel)

    var margin := MarginContainer.new()
    margin.name = "SheetListMargin"
    margin.anchor_left = 0.0
    margin.anchor_right = 1.0
    margin.anchor_top = 0.0
    margin.anchor_bottom = 1.0
    margin.offset_left = 10.0
    margin.offset_right = -10.0
    margin.offset_top = 10.0
    margin.offset_bottom = -10.0
    sheet_list_panel.add_child(margin)

    var vbox := VBoxContainer.new()
    vbox.name = "SheetListVBox"
    margin.add_child(vbox)

    sheet_list_title_label = Label.new()
    sheet_list_title_label.name = "SheetListTitleLabel"
    sheet_list_title_label.text = "List"
    sheet_list_title_label.add_theme_font_size_override("font_size", 16)
    vbox.add_child(sheet_list_title_label)

    var scroll := ScrollContainer.new()
    scroll.name = "SheetListScroll"
    scroll.custom_minimum_size = Vector2(290.0, 255.0)
    vbox.add_child(scroll)

    sheet_list_content_label = Label.new()
    sheet_list_content_label.name = "SheetListContentLabel"
    sheet_list_content_label.text = ""
    sheet_list_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    sheet_list_content_label.custom_minimum_size = Vector2(270.0, 245.0)
    scroll.add_child(sheet_list_content_label)

    sheet_list_close_button = Button.new()
    sheet_list_close_button.name = "SheetListCloseButton"
    sheet_list_close_button.text = "Close"
    sheet_list_close_button.focus_mode = Control.FOCUS_NONE
    sheet_list_close_button.pressed.connect(_on_sheet_list_close_button_pressed)
    vbox.add_child(sheet_list_close_button)


func _show_sheet_list(title: String, content: String) -> void:
    if sheet_list_panel == null:
        return

    active_sheet_list_title = title

    if sheet_list_title_label != null:
        sheet_list_title_label.text = title

    if sheet_list_content_label != null:
        sheet_list_content_label.text = content

    sheet_list_panel.visible = true


func _get_inventory_list_text() -> String:
    var player := _get_player()

    if player == null:
        return "No inventory items."

    if not player.has_method("get_inventory_items"):
        return "No inventory items."

    var items: Array = player.get_inventory_items()

    if items.is_empty():
        return "No inventory items."

    var text := ""

    for item in items:
        if typeof(item) != TYPE_DICTIONARY:
            continue

        var item_name: String = str(item.get("name", "Unknown Item"))
        var quantity: int = int(item.get("quantity", 1))

        if quantity > 1:
            text += "- " + item_name + " x" + str(quantity) + "\n"
        else:
            text += "- " + item_name + "\n"

    return text.strip_edges()


func _get_currency_list_text() -> String:
    var player := _get_player()

    if player == null:
        return "No currencies discovered."

    if not player.has_method("get_discovered_currency_rows"):
        return "No currencies discovered."

    var currency_rows: Array = player.get_discovered_currency_rows()

    if currency_rows.is_empty():
        return "No currencies discovered."

    var text := ""

    for row in currency_rows:
        if typeof(row) != TYPE_DICTIONARY:
            continue

        var currency_name: String = str(row.get("name", "Unknown Currency"))
        var currency_amount: int = int(row.get("amount", 0))

        text += "- " + currency_name + ": " + str(currency_amount) + "\n"

    return text.strip_edges()


func _on_inventory_list_button_pressed() -> void:
    if sheet_list_panel != null and sheet_list_panel.visible and active_sheet_list_title == "Inventory":
        hide_sheet_list()
        return

    _show_sheet_list("Inventory", _get_inventory_list_text())


func _on_currency_list_button_pressed() -> void:
    if sheet_list_panel != null and sheet_list_panel.visible and active_sheet_list_title == "Currency":
        hide_sheet_list()
        return

    _show_sheet_list("Currency", _get_currency_list_text())


func _on_sheet_list_close_button_pressed() -> void:
    hide_sheet_list()


func _get_player() -> Node:
    if player_getter.is_valid():
        return player_getter.call()

    return null

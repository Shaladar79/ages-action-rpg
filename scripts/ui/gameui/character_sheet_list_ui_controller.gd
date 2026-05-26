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
var sheet_list_close_button: Button = null
var sheet_list_back_button: Button = null
var sheet_list_rows_container: VBoxContainer = null

var selected_faction_id: String = ""


func setup(ui_root: CanvasLayer, panel_node: Panel, get_player_callable: Callable) -> void:
    root_ui = ui_root
    character_panel = panel_node
    player_getter = get_player_callable

    _create_character_sheet_list_buttons()
    _create_character_sheet_list_panel()


func hide_sheet_list() -> void:
    active_sheet_list_title = ""
    selected_faction_id = ""

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

    # Panel starts at -360, so Inventory now lines up with the panel's left edge.
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
    faction_list_button.text = "Factions"
    faction_list_button.custom_minimum_size = Vector2(100.0, 32.0)
    faction_list_button.focus_mode = Control.FOCUS_NONE
    faction_list_button.visible = _is_factions_unlocked()
    faction_list_button.disabled = not _is_factions_unlocked()
    faction_list_button.pressed.connect(_on_faction_list_button_pressed)
    sheet_list_button_container.add_child(faction_list_button)

    character_panel.add_child(sheet_list_button_container)

func _is_factions_unlocked() -> bool:
    if SaveManager == null:
        return false

    return SaveManager.is_flag_set("factions_unlocked")
 
func refresh_unlock_visibility() -> void:
    if faction_list_button == null:
        return

    var unlocked := _is_factions_unlocked()
    faction_list_button.visible = unlocked
    faction_list_button.disabled = not unlocked

    if not unlocked and active_sheet_list_title == "Factions":
        hide_sheet_list()
           
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

    var title_row := HBoxContainer.new()
    title_row.name = "SheetListTitleRow"
    title_row.custom_minimum_size = Vector2(290.0, 32.0)
    vbox.add_child(title_row)

    sheet_list_title_label = Label.new()
    sheet_list_title_label.name = "SheetListTitleLabel"
    sheet_list_title_label.text = "List"
    sheet_list_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sheet_list_title_label.add_theme_font_size_override("font_size", 16)
    title_row.add_child(sheet_list_title_label)

    sheet_list_back_button = Button.new()
    sheet_list_back_button.name = "SheetListBackButton"
    sheet_list_back_button.text = "Back"
    sheet_list_back_button.focus_mode = Control.FOCUS_NONE
    sheet_list_back_button.visible = false
    sheet_list_back_button.custom_minimum_size = Vector2(70.0, 28.0)
    sheet_list_back_button.pressed.connect(_on_sheet_list_back_button_pressed)
    title_row.add_child(sheet_list_back_button)

    var scroll := ScrollContainer.new()
    scroll.name = "SheetListScroll"
    scroll.custom_minimum_size = Vector2(290.0, 255.0)
    vbox.add_child(scroll)

    sheet_list_rows_container = VBoxContainer.new()
    sheet_list_rows_container.name = "SheetListRowsContainer"
    sheet_list_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(sheet_list_rows_container)

    sheet_list_close_button = Button.new()
    sheet_list_close_button.name = "SheetListCloseButton"
    sheet_list_close_button.text = "Close"
    sheet_list_close_button.focus_mode = Control.FOCUS_NONE
    sheet_list_close_button.pressed.connect(_on_sheet_list_close_button_pressed)
    vbox.add_child(sheet_list_close_button)


func _show_sheet_list(title: String) -> void:
    if sheet_list_panel == null:
        return

    active_sheet_list_title = title

    if sheet_list_title_label != null:
        sheet_list_title_label.text = title

    sheet_list_panel.visible = true


func _clear_sheet_rows() -> void:
    if sheet_list_rows_container == null:
        return

    for child in sheet_list_rows_container.get_children():
        child.queue_free()


func _add_text_row(row_text: String, minimum_height: float = 24.0) -> void:
    if sheet_list_rows_container == null:
        return

    var label := Label.new()
    label.text = row_text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.custom_minimum_size = Vector2(270.0, minimum_height)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sheet_list_rows_container.add_child(label)


func _show_inventory_list() -> void:
    selected_faction_id = ""

    if sheet_list_back_button != null:
        sheet_list_back_button.visible = false

    _show_sheet_list("Inventory")
    _clear_sheet_rows()

    var player := _get_player()

    if player == null:
        _add_text_row("No inventory items.")
        return

    if not player.has_method("get_inventory_items"):
        _add_text_row("No inventory items.")
        return

    var items: Array = player.get_inventory_items()

    if items.is_empty():
        _add_text_row("No inventory items.")
        return

    for item in items:
        if typeof(item) != TYPE_DICTIONARY:
            continue

        var item_name: String = str(item.get("name", "Unknown Item"))
        var quantity: int = int(item.get("quantity", 1))

        if quantity > 1:
            _add_text_row("- " + item_name + " x" + str(quantity))
        else:
            _add_text_row("- " + item_name)


func _show_currency_list() -> void:
    selected_faction_id = ""

    if sheet_list_back_button != null:
        sheet_list_back_button.visible = false

    _show_sheet_list("Currency")
    _clear_sheet_rows()

    var player := _get_player()

    if player == null:
        _add_text_row("No currencies discovered.")
        return

    if not player.has_method("get_discovered_currency_rows"):
        _add_text_row("No currencies discovered.")
        return

    var currency_rows: Array = player.get_discovered_currency_rows()

    if currency_rows.is_empty():
        _add_text_row("No currencies discovered.")
        return

    for row in currency_rows:
        if typeof(row) != TYPE_DICTIONARY:
            continue

        var currency_name: String = str(row.get("name", "Unknown Currency"))
        var currency_amount: int = int(row.get("amount", 0))

        _add_text_row("- " + currency_name + ": " + str(currency_amount))


func _show_faction_list() -> void:
    selected_faction_id = ""

    if sheet_list_back_button != null:
        sheet_list_back_button.visible = false

    _show_sheet_list("Factions")
    _clear_sheet_rows()

    if FactionManager == null:
        _add_text_row("FactionManager is not available.")
        return

    var faction_rows: Array[Dictionary] = FactionManager.get_all_faction_rows()

    if faction_rows.is_empty():
        _add_text_row("No factions discovered.")
        return

    _add_text_row("Choose a faction:", 32.0)

    for faction_row in faction_rows:
        _add_faction_button_row(faction_row)


func _add_faction_button_row(faction_row: Dictionary) -> void:
    if sheet_list_rows_container == null:
        return

    var faction_id: String = str(faction_row.get("id", "")).strip_edges()
    var faction_name: String = str(faction_row.get("name", "Unknown Faction"))
    var points: int = int(faction_row.get("points", 0))
    var current_tier: Dictionary = faction_row.get("current_tier", {})
    var current_tier_number: int = int(current_tier.get("tier", 0))
    var current_tier_title: String = str(current_tier.get("title", "Unknown"))

    var faction_button := Button.new()
    faction_button.name = "FactionButton_" + faction_id
    faction_button.text = "%s\nTier %s - %s\n%s points" % [
        faction_name,
        current_tier_number,
        current_tier_title,
        points
    ]
    faction_button.focus_mode = Control.FOCUS_NONE
    faction_button.custom_minimum_size = Vector2(270.0, 72.0)
    faction_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    faction_button.pressed.connect(_on_faction_button_pressed.bind(faction_id))

    sheet_list_rows_container.add_child(faction_button)


func _show_faction_detail(faction_id: String) -> void:
    selected_faction_id = faction_id

    _show_sheet_list("Factions")
    _clear_sheet_rows()

    if sheet_list_back_button != null:
        sheet_list_back_button.visible = true

    if FactionManager == null:
        _add_text_row("FactionManager is not available.")
        return

    var faction_row := FactionManager.get_faction_row(faction_id)

    if faction_row.is_empty():
        _add_text_row("Faction not found.")
        return

    var faction_name: String = str(faction_row.get("name", "Unknown Faction"))
    var description: String = str(faction_row.get("description", ""))
    var points: int = int(faction_row.get("points", 0))
    var current_tier: Dictionary = faction_row.get("current_tier", {})
    var next_tier: Dictionary = faction_row.get("next_tier", {})

    var current_tier_number: int = int(current_tier.get("tier", 0))
    var current_tier_title: String = str(current_tier.get("title", "Unknown"))

    var next_text := "Next: Max Tier"

    if not next_tier.is_empty():
        var next_tier_number: int = int(next_tier.get("tier", current_tier_number + 1))
        var next_tier_title: String = str(next_tier.get("title", "Next"))
        var next_points: int = int(next_tier.get("points_required", points))

        next_text = "Next: Tier %s - %s at %s" % [
            next_tier_number,
            next_tier_title,
            next_points
        ]

    _add_text_row(faction_name, 28.0)
    _add_text_row("Points: " + str(points), 24.0)
    _add_text_row("Current: Tier %s - %s" % [current_tier_number, current_tier_title], 24.0)
    _add_text_row(next_text, 36.0)
    _add_text_row(description, 120.0)


func refresh_faction_display() -> void:
    refresh_unlock_visibility()

    if active_sheet_list_title != "Factions":
        return

    if selected_faction_id.strip_edges() != "":
        _show_faction_detail(selected_faction_id)
    else:
        _show_faction_list()


func _on_inventory_list_button_pressed() -> void:
    if sheet_list_panel != null and sheet_list_panel.visible and active_sheet_list_title == "Inventory":
        hide_sheet_list()
        return

    _show_inventory_list()


func _on_currency_list_button_pressed() -> void:
    if sheet_list_panel != null and sheet_list_panel.visible and active_sheet_list_title == "Currency":
        hide_sheet_list()
        return

    _show_currency_list()


func _on_faction_list_button_pressed() -> void:
    if not _is_factions_unlocked():
        return

    if sheet_list_panel != null and sheet_list_panel.visible and active_sheet_list_title == "Factions" and selected_faction_id == "":
        hide_sheet_list()
        return

    _show_faction_list()

func _on_faction_button_pressed(faction_id: String) -> void:
    _show_faction_detail(faction_id)


func _on_sheet_list_back_button_pressed() -> void:
    _show_faction_list()


func _on_sheet_list_close_button_pressed() -> void:
    hide_sheet_list()


func _get_player() -> Node:
    if player_getter.is_valid():
        return player_getter.call()

    return null

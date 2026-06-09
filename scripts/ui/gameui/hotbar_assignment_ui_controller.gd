extends RefCounted
class_name HotbarAssignmentUiController

const HOTBAR_SLOT_COUNT: int = 8
const HOTBAR_ROWS_PER_COLUMN: int = 4

var root_ui: CanvasLayer = null
var character_panel: Panel = null
var player_getter: Callable = Callable()

var sheet_hotbar_container: VBoxContainer = null
var sheet_hotbar_option_buttons: Array[OptionButton] = []
var sheet_hotbar_clear_buttons: Array[Button] = []


func setup(ui_root: CanvasLayer, panel_node: Panel, get_player_callable: Callable) -> void:
    root_ui = ui_root
    character_panel = panel_node
    player_getter = get_player_callable

    _create_hotbar_assignment_panel()
    update_hotbar_assignment_panel()


func update_hotbar_assignment_panel() -> void:
    if sheet_hotbar_option_buttons.is_empty():
        return

    var player := _get_player()
    var owned_hotbar_items: Array[Dictionary] = _get_owned_hotbar_usable_items()
    var slots: Array = []

    if player != null and player.has_method("get_hotbar_slots"):
        slots = player.get_hotbar_slots()

    for index in range(HOTBAR_SLOT_COUNT):
        var option_button: OptionButton = sheet_hotbar_option_buttons[index]
        option_button.clear()
        option_button.add_item("Empty")
        option_button.set_item_metadata(0, "")

        for item in owned_hotbar_items:
            var item_id: String = str(item.get("id", ""))
            var item_name: String = str(item.get("name", item_id))

            option_button.add_item(item_name)
            option_button.set_item_metadata(option_button.item_count - 1, item_id)

        var selected_item_id: String = ""

        if index < slots.size():
            var slot: Dictionary = slots[index]
            selected_item_id = str(slot.get("item_id", ""))

        var selected_index: int = 0

        if selected_item_id.strip_edges() != "":
            for option_index in range(option_button.item_count):
                var metadata: Variant = option_button.get_item_metadata(option_index)

                if str(metadata) == selected_item_id:
                    selected_index = option_index
                    break

        option_button.select(selected_index)


func _create_hotbar_assignment_panel() -> void:
    if sheet_hotbar_container != null:
        return

    if character_panel == null:
        return

    sheet_hotbar_container = VBoxContainer.new()
    sheet_hotbar_container.name = "HotbarAssignmentPanel"

    sheet_hotbar_container.anchor_left = 1.0
    sheet_hotbar_container.anchor_right = 1.0
    sheet_hotbar_container.anchor_top = 1.0
    sheet_hotbar_container.anchor_bottom = 1.0

    sheet_hotbar_container.offset_left = -520.0
    sheet_hotbar_container.offset_right = -16.0
    sheet_hotbar_container.offset_top = -190.0
    sheet_hotbar_container.offset_bottom = -16.0

    sheet_hotbar_container.custom_minimum_size = Vector2(500.0, 210.0)

    var title := Label.new()
    title.name = "HotbarAssignmentTitle"
    title.text = "Hotbar Assignment"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.custom_minimum_size = Vector2(500.0, 24.0)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 16)
    sheet_hotbar_container.add_child(title)

    var columns_row := HBoxContainer.new()
    columns_row.name = "HotbarAssignmentColumns"
    columns_row.add_theme_constant_override("separation", 18)
    sheet_hotbar_container.add_child(columns_row)

    var left_column := VBoxContainer.new()
    left_column.name = "HotbarAssignmentLeftColumn"
    columns_row.add_child(left_column)

    var right_column := VBoxContainer.new()
    right_column.name = "HotbarAssignmentRightColumn"
    columns_row.add_child(right_column)

    sheet_hotbar_option_buttons.clear()
    sheet_hotbar_clear_buttons.clear()

    for slot_number in range(1, HOTBAR_SLOT_COUNT + 1):
        var row := HBoxContainer.new()
        row.name = "HotbarAssignRow" + str(slot_number)

        var slot_label := Label.new()
        slot_label.text = str(slot_number) + ":"
        slot_label.custom_minimum_size = Vector2(24.0, 24.0)
        row.add_child(slot_label)

        var option_button := OptionButton.new()
        option_button.name = "HotbarAssignOption" + str(slot_number)
        option_button.custom_minimum_size = Vector2(150.0, 24.0)
        option_button.item_selected.connect(_on_hotbar_assignment_selected.bind(slot_number))
        row.add_child(option_button)

        var clear_button := Button.new()
        clear_button.name = "HotbarClearButton" + str(slot_number)
        clear_button.text = "Clear"
        clear_button.focus_mode = Control.FOCUS_NONE
        clear_button.pressed.connect(_on_hotbar_clear_button_pressed.bind(slot_number))
        row.add_child(clear_button)

        if slot_number <= HOTBAR_ROWS_PER_COLUMN:
            left_column.add_child(row)
        else:
            right_column.add_child(row)

        sheet_hotbar_option_buttons.append(option_button)
        sheet_hotbar_clear_buttons.append(clear_button)

    character_panel.add_child(sheet_hotbar_container)


func _get_owned_hotbar_usable_items() -> Array[Dictionary]:
    var usable_items: Array[Dictionary] = []
    var player := _get_player()

    if player == null:
        return usable_items

    if not player.has_method("get_inventory_items"):
        return usable_items

    var items: Array = player.get_inventory_items()

    for item in items:
        if typeof(item) != TYPE_DICTIONARY:
            continue

        var item_id: String = str(item.get("id", ""))
        var item_name: String = str(item.get("name", item_id))

        if item_id.strip_edges() == "":
            continue

        if not ItemDatabase.is_hotbar_usable(item_id):
            continue

        usable_items.append({
            "id": item_id,
            "name": item_name
        })

    return usable_items


func _on_hotbar_assignment_selected(selected_index: int, slot_number: int) -> void:
    var player := _get_player()

    if player == null:
        return

    if slot_number < 1 or slot_number > HOTBAR_SLOT_COUNT:
        return

    var option_button: OptionButton = sheet_hotbar_option_buttons[slot_number - 1]
    var metadata: Variant = option_button.get_item_metadata(selected_index)
    var item_id: String = str(metadata)

    if item_id.strip_edges() == "":
        if player.has_method("clear_hotbar_slot"):
            player.clear_hotbar_slot(slot_number)
    else:
        if player.has_method("assign_hotbar_slot"):
            player.assign_hotbar_slot(slot_number, item_id)

    if root_ui != null:
        if root_ui.has_method("refresh_character_display"):
            root_ui.refresh_character_display()


func _on_hotbar_clear_button_pressed(slot_number: int) -> void:
    var player := _get_player()

    if player == null:
        return

    if player.has_method("clear_hotbar_slot"):
        player.clear_hotbar_slot(slot_number)

    if root_ui != null:
        if root_ui.has_method("refresh_character_display"):
            root_ui.refresh_character_display()


func _get_player() -> Node:
    if player_getter.is_valid():
        return player_getter.call()

    return null

extends RefCounted
class_name CharacterSheetButtonsUiController

var root_ui: CanvasLayer = null
var character_panel: Panel = null
var player_getter: Callable = Callable()

var buttons_root: Control = null

var add_might_button: Button = null
var add_agility_button: Button = null
var add_toughness_button: Button = null
var add_speed_button: Button = null
var add_endurance_button: Button = null
var add_focus_button: Button = null
var close_button: Button = null


func setup(ui_root: CanvasLayer, panel_node: Panel, get_player_callable: Callable) -> void:
    root_ui = ui_root
    character_panel = panel_node
    player_getter = get_player_callable

    if character_panel == null:
        push_warning("CharacterSheetButtonsUiController setup failed. Character panel is null.")
        return

    _hide_legacy_editor_buttons()
    _create_character_sheet_buttons()
    _connect_buttons()
    update_stat_buttons(null)


func update_stat_buttons(stats: CharacterStats) -> void:
    if stats == null:
        _set_stat_buttons_disabled(true)
        return

    _update_button_for_stat(add_might_button, stats, "might", true)
    _update_button_for_stat(add_agility_button, stats, "agility", true)
    _update_button_for_stat(add_toughness_button, stats, "toughness", true)
    _update_button_for_stat(add_speed_button, stats, "speed", true)

    if add_endurance_button != null:
        add_endurance_button.visible = false
        add_endurance_button.disabled = true
        add_endurance_button.tooltip_text = "Endurance is not available yet."

    _update_button_for_stat(add_focus_button, stats, "focus", stats.has_mana_resource)


func _update_button_for_stat(button: Button, stats: CharacterStats, stat_id: String, should_be_visible: bool) -> void:
    if button == null:
        return

    button.visible = should_be_visible

    if not should_be_visible:
        button.disabled = true
        button.tooltip_text = ""
        return

    var cost := 1

    if stats.has_method("get_stat_point_cost"):
        cost = stats.get_stat_point_cost(stat_id)
    else:
        cost = _get_fallback_stat_cost(stats, stat_id)

    var can_afford := stats.stat_points >= cost

    button.disabled = not can_afford
    button.text = "+"

    if can_afford:
        button.tooltip_text = "Increase %s. Cost: %s stat point%s." % [
            stat_id.capitalize(),
            cost,
            _get_plural_suffix(cost)
        ]
    else:
        button.tooltip_text = "Need %s stat point%s to increase %s. Available: %s." % [
            cost,
            _get_plural_suffix(cost),
            stat_id.capitalize(),
            stats.stat_points
        ]


func _get_fallback_stat_cost(stats: CharacterStats, stat_id: String) -> int:
    match stat_id:
        "might":
            return maxi(1, stats.might)
        "agility":
            return maxi(1, stats.agility)
        "toughness":
            return maxi(1, stats.toughness)
        "speed":
            return maxi(1, stats.speed)
        "endurance":
            return maxi(1, stats.endurance)
        "focus":
            return maxi(1, stats.focus)
        _:
            return 1


func _get_plural_suffix(value: int) -> String:
    if value == 1:
        return ""

    return "s"


func _create_character_sheet_buttons() -> void:
    if buttons_root != null:
        return

    buttons_root = Control.new()
    buttons_root.name = "CodeBuiltCharacterSheetButtons"
    buttons_root.anchor_left = 0.0
    buttons_root.anchor_right = 1.0
    buttons_root.anchor_top = 0.0
    buttons_root.anchor_bottom = 1.0
    buttons_root.offset_left = 0.0
    buttons_root.offset_right = 0.0
    buttons_root.offset_top = 0.0
    buttons_root.offset_bottom = 0.0
    buttons_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    character_panel.add_child(buttons_root)

    close_button = _create_button("CloseButton", "Close", Vector2(-100.0, 16.0), Vector2(84.0, 32.0), true)

    add_might_button = _create_button("AddMightButton", "+", Vector2(102.0, 260.0), Vector2(28.0, 24.0))
    add_agility_button = _create_button("AddAgilityButton", "+", Vector2(102.0, 290.0), Vector2(28.0, 24.0))
    add_toughness_button = _create_button("AddToughnessButton", "+", Vector2(118.0, 320.0), Vector2(28.0, 24.0))
    add_speed_button = _create_button("AddSpeedButton", "+", Vector2(102.0, 350.0), Vector2(28.0, 24.0))

    add_endurance_button = _create_button("AddEnduranceButton", "+", Vector2(130.0, 380.0), Vector2(28.0, 24.0))
    add_endurance_button.visible = false
    add_endurance_button.disabled = true

    add_focus_button = _create_button("AddFocusButton", "+", Vector2(102.0, 410.0), Vector2(28.0, 24.0))
    add_focus_button.visible = false
    add_focus_button.disabled = true


func _create_button(button_name: String, button_text: String, position: Vector2, size: Vector2, anchor_to_right: bool = false) -> Button:
    var button := Button.new()
    button.name = button_name
    button.text = button_text
    button.custom_minimum_size = size
    button.focus_mode = Control.FOCUS_NONE

    if anchor_to_right:
        button.anchor_left = 1.0
        button.anchor_right = 1.0
        button.anchor_top = 0.0
        button.anchor_bottom = 0.0
        button.offset_left = position.x
        button.offset_right = position.x + size.x
        button.offset_top = position.y
        button.offset_bottom = position.y + size.y
    else:
        button.anchor_left = 0.0
        button.anchor_right = 0.0
        button.anchor_top = 0.0
        button.anchor_bottom = 0.0
        button.offset_left = position.x
        button.offset_right = position.x + size.x
        button.offset_top = position.y
        button.offset_bottom = position.y + size.y

    buttons_root.add_child(button)
    return button


func _hide_legacy_editor_buttons() -> void:
    _hide_legacy_node("CloseButton")
    _hide_legacy_node("AttributesPanel_base/Attribute_panel_att/AddMightButton")
    _hide_legacy_node("AttributesPanel_base/Attribute_panel_att/AddAgilityButton")
    _hide_legacy_node("AttributesPanel_base/Attribute_panel_att/AddToughnessButton")
    _hide_legacy_node("AttributesPanel_base/Attribute_panel_att/AddSpeedButton")
    _hide_legacy_node("AttributesPanel_base/Attribute_panel_att/AddEnduranceButton")
    _hide_legacy_node("AttributesPanel_base/Attribute_panel_att/AddFocusButton")


func _hide_legacy_node(node_path: String) -> void:
    if character_panel == null:
        return

    var node := character_panel.get_node_or_null(node_path)

    if node == null:
        return

    if node is CanvasItem:
        var canvas_item := node as CanvasItem
        canvas_item.visible = false

    if node is Button:
        var button := node as Button
        button.disabled = true


func _connect_buttons() -> void:
    if close_button != null and not close_button.pressed.is_connected(_on_close_button_pressed):
        close_button.pressed.connect(_on_close_button_pressed)

    if add_might_button != null and not add_might_button.pressed.is_connected(_on_add_might_button_pressed):
        add_might_button.pressed.connect(_on_add_might_button_pressed)

    if add_agility_button != null and not add_agility_button.pressed.is_connected(_on_add_agility_button_pressed):
        add_agility_button.pressed.connect(_on_add_agility_button_pressed)

    if add_toughness_button != null and not add_toughness_button.pressed.is_connected(_on_add_toughness_button_pressed):
        add_toughness_button.pressed.connect(_on_add_toughness_button_pressed)

    if add_speed_button != null and not add_speed_button.pressed.is_connected(_on_add_speed_button_pressed):
        add_speed_button.pressed.connect(_on_add_speed_button_pressed)

    if add_focus_button != null and not add_focus_button.pressed.is_connected(_on_add_focus_button_pressed):
        add_focus_button.pressed.connect(_on_add_focus_button_pressed)


func _set_stat_buttons_disabled(disabled: bool) -> void:
    if add_might_button != null:
        add_might_button.disabled = disabled

    if add_agility_button != null:
        add_agility_button.disabled = disabled

    if add_toughness_button != null:
        add_toughness_button.disabled = disabled

    if add_speed_button != null:
        add_speed_button.disabled = disabled

    if add_endurance_button != null:
        add_endurance_button.disabled = true
        add_endurance_button.visible = false

    if add_focus_button != null:
        add_focus_button.disabled = true
        add_focus_button.visible = false


func _spend_stat_point(stat_id: String) -> void:
    var player := _get_player()

    if player == null:
        return

    if not player.has_method("spend_stat_point"):
        return

    var spent: bool = player.spend_stat_point(stat_id)

    if not spent:
        return

    if root_ui != null and root_ui.has_method("refresh_character_display"):
        root_ui.refresh_character_display()


func _on_add_might_button_pressed() -> void:
    _spend_stat_point("might")


func _on_add_agility_button_pressed() -> void:
    _spend_stat_point("agility")


func _on_add_toughness_button_pressed() -> void:
    _spend_stat_point("toughness")


func _on_add_speed_button_pressed() -> void:
    _spend_stat_point("speed")


func _on_add_focus_button_pressed() -> void:
    _spend_stat_point("focus")


func _on_close_button_pressed() -> void:
    if root_ui != null and root_ui.has_method("close_character_screen"):
        root_ui.close_character_screen()


func _get_player() -> Node:
    if player_getter.is_valid():
        return player_getter.call()

    return null

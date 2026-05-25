extends RefCounted
class_name CharacterSheetButtonsUiController

var root_ui: CanvasLayer = null
var character_panel: Panel = null
var player_getter: Callable = Callable()

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

    _bind_existing_editor_buttons()
    _hide_locked_stat_buttons()
    _connect_buttons()
    update_stat_buttons(null)


func update_stat_buttons(stats: CharacterStats) -> void:
    if stats == null:
        _set_stat_buttons_disabled(true)
        return

    _set_stat_buttons_disabled(stats.stat_points <= 0)


func _bind_existing_editor_buttons() -> void:
    add_might_button = character_panel.get_node_or_null("AttributesPanel_base/Attribute_panel_att/AddMightButton") as Button
    add_agility_button = character_panel.get_node_or_null("AttributesPanel_base/Attribute_panel_att/AddAgilityButton") as Button
    add_toughness_button = character_panel.get_node_or_null("AttributesPanel_base/Attribute_panel_att/AddToughnessButton") as Button
    add_speed_button = character_panel.get_node_or_null("AttributesPanel_base/Attribute_panel_att/AddSpeedButton") as Button
    add_endurance_button = character_panel.get_node_or_null("AttributesPanel_base/Attribute_panel_att/AddEnduranceButton") as Button
    add_focus_button = character_panel.get_node_or_null("AttributesPanel_base/Attribute_panel_att/AddFocusButton") as Button

    close_button = character_panel.get_node_or_null("CloseButton") as Button


func _hide_locked_stat_buttons() -> void:
    if add_endurance_button != null:
        add_endurance_button.visible = false
        add_endurance_button.disabled = true

    if add_focus_button != null:
        add_focus_button.visible = false
        add_focus_button.disabled = true


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


func _on_close_button_pressed() -> void:
    if root_ui != null and root_ui.has_method("close_character_screen"):
        root_ui.close_character_screen()


func _get_player() -> Node:
    if player_getter.is_valid():
        return player_getter.call()

    return null

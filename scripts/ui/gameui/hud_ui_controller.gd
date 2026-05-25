extends RefCounted
class_name HudUiController

const HOTBAR_SLOT_COUNT: int = 5

var root_ui: CanvasLayer = null
var player_getter: Callable = Callable()

var hud_health_label: Label = null
var hud_mana_label: Label = null
var hud_stamina_label: Label = null

var hud_hotbar_layer: Control = null
var hud_hotbar_container: HBoxContainer = null
var hud_hotbar_buttons: Array[Button] = []

var hud_info_panel: VBoxContainer = null
var hud_name_label: Label = null
var hud_level_label: Label = null
var hud_resource_row: HBoxContainer = null


func setup(
        ui_root: CanvasLayer,
        get_player_callable: Callable,
        health_label: Label,
        mana_label: Label,
        stamina_label: Label
) -> void:
    root_ui = ui_root
    player_getter = get_player_callable
    hud_health_label = health_label
    hud_mana_label = mana_label
    hud_stamina_label = stamina_label

    _create_hotbar_hud()
    _create_hud_info_panel()
    update_hud()


func update_hud() -> void:
    var player := _get_player()
    var stats: CharacterStats = null

    if player != null and player.has_method("get_character_stats"):
        stats = player.get_character_stats()

    if stats == null:
        if hud_name_label != null:
            hud_name_label.text = "No Character"

        if hud_level_label != null:
            hud_level_label.text = "Level --"

        if hud_health_label != null:
            hud_health_label.text = "Health: -- / --"

        if hud_mana_label != null:
            hud_mana_label.visible = false
            hud_mana_label.text = ""

        if hud_stamina_label != null:
            hud_stamina_label.visible = false
            hud_stamina_label.text = ""

        _update_hotbar_hud()
        return

    if hud_name_label != null:
        hud_name_label.text = stats.character_name

    if hud_level_label != null:
        hud_level_label.text = "Level " + str(stats.level)

    if hud_health_label != null:
        hud_health_label.visible = true
        hud_health_label.text = "Health: %s / %s" % [stats.current_health, stats.max_health]

    if hud_mana_label != null:
        hud_mana_label.visible = stats.has_mana_resource

        if stats.has_mana_resource:
            hud_mana_label.text = "Mana: %s / %s" % [stats.current_mana, stats.max_mana]
        else:
            hud_mana_label.text = ""

    if hud_stamina_label != null:
        hud_stamina_label.visible = stats.has_stamina_resource

        if stats.has_stamina_resource:
            hud_stamina_label.text = "Stamina: %s / %s" % [stats.current_stamina, stats.max_stamina]
        else:
            hud_stamina_label.text = ""

    _update_hotbar_hud()


func _create_hotbar_hud() -> void:
    if hud_hotbar_container != null:
        return

    if root_ui == null:
        push_warning("Cannot create hotbar HUD. Root UI is null.")
        return

    hud_hotbar_layer = Control.new()
    hud_hotbar_layer.name = "HotbarHudLayer"
    hud_hotbar_layer.anchor_left = 0.0
    hud_hotbar_layer.anchor_right = 1.0
    hud_hotbar_layer.anchor_top = 0.0
    hud_hotbar_layer.anchor_bottom = 1.0
    hud_hotbar_layer.offset_left = 0.0
    hud_hotbar_layer.offset_right = 0.0
    hud_hotbar_layer.offset_top = 0.0
    hud_hotbar_layer.offset_bottom = 0.0
    hud_hotbar_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

    root_ui.add_child(hud_hotbar_layer)

    hud_hotbar_container = HBoxContainer.new()
    hud_hotbar_container.name = "HotbarPanel"
    hud_hotbar_container.anchor_left = 0.0
    hud_hotbar_container.anchor_right = 0.0
    hud_hotbar_container.anchor_top = 1.0
    hud_hotbar_container.anchor_bottom = 1.0
    hud_hotbar_container.offset_left = 16.0
    hud_hotbar_container.offset_right = 396.0
    hud_hotbar_container.offset_top = -72.0
    hud_hotbar_container.offset_bottom = -16.0
    hud_hotbar_container.alignment = BoxContainer.ALIGNMENT_BEGIN
    hud_hotbar_container.mouse_filter = Control.MOUSE_FILTER_STOP

    hud_hotbar_layer.add_child(hud_hotbar_container)

    hud_hotbar_buttons.clear()

    for slot_number in range(1, HOTBAR_SLOT_COUNT + 1):
        var button := Button.new()
        button.name = "HotbarSlot" + str(slot_number)
        button.custom_minimum_size = Vector2(68.0, 52.0)
        button.text = str(slot_number) + "\nEmpty"
        button.focus_mode = Control.FOCUS_NONE
        button.pressed.connect(_on_hud_hotbar_button_pressed.bind(slot_number))

        hud_hotbar_container.add_child(button)
        hud_hotbar_buttons.append(button)


func _create_hud_info_panel() -> void:
    if hud_info_panel != null:
        return

    if root_ui == null:
        push_warning("Cannot create HUD info panel. Root UI is null.")
        return

    var hud_parent := root_ui.get_node_or_null("HUD") as Control

    if hud_parent == null:
        push_warning("Cannot create HUD info panel. HUD node is missing.")
        return

    hud_info_panel = VBoxContainer.new()
    hud_info_panel.name = "HudInfoPanel"
    hud_info_panel.anchor_left = 0.0
    hud_info_panel.anchor_right = 0.0
    hud_info_panel.anchor_top = 0.0
    hud_info_panel.anchor_bottom = 0.0
    hud_info_panel.offset_left = 16.0
    hud_info_panel.offset_top = 12.0
    hud_info_panel.offset_right = 520.0
    hud_info_panel.offset_bottom = 120.0
    hud_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

    hud_parent.add_child(hud_info_panel)

    hud_name_label = Label.new()
    hud_name_label.name = "HudNameLabel"
    hud_name_label.text = "Gene Ambrose"
    hud_name_label.add_theme_font_size_override("font_size", 18)
    hud_info_panel.add_child(hud_name_label)

    hud_level_label = Label.new()
    hud_level_label.name = "HudLevelLabel"
    hud_level_label.text = "Level 0"
    hud_level_label.add_theme_font_size_override("font_size", 14)
    hud_info_panel.add_child(hud_level_label)

    hud_resource_row = HBoxContainer.new()
    hud_resource_row.name = "HudResourceRow"
    hud_resource_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_info_panel.add_child(hud_resource_row)

    _move_existing_resource_label_to_hud_row(hud_health_label)
    _move_existing_resource_label_to_hud_row(hud_mana_label)
    _move_existing_resource_label_to_hud_row(hud_stamina_label)


func _move_existing_resource_label_to_hud_row(label: Label) -> void:
    if label == null:
        return

    if hud_resource_row == null:
        return

    var current_parent := label.get_parent()

    if current_parent != null:
        current_parent.remove_child(label)

    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.custom_minimum_size = Vector2(130.0, 24.0)

    hud_resource_row.add_child(label)


func _update_hotbar_hud() -> void:
    if hud_hotbar_buttons.is_empty():
        return

    var player := _get_player()
    var slots: Array = []

    if player != null and player.has_method("get_hotbar_slots"):
        slots = player.get_hotbar_slots()

    for index in range(HOTBAR_SLOT_COUNT):
        var button: Button = hud_hotbar_buttons[index]

        if index >= slots.size():
            button.text = str(index + 1) + "\nEmpty"
            button.disabled = true
            continue

        var slot: Dictionary = slots[index]
        var item_id: String = str(slot.get("item_id", ""))
        var cooldown_remaining: float = float(slot.get("cooldown_remaining", 0.0))

        if item_id.strip_edges() == "":
            button.text = str(index + 1) + "\nEmpty"
            button.disabled = true
            continue

        var item_name: String = ItemDatabase.get_item_name(item_id)

        if cooldown_remaining > 0.0:
            button.text = str(index + 1) + "\n" + item_name + "\n" + str(snappedf(cooldown_remaining, 0.1)) + "s"
            button.disabled = true
        else:
            button.text = str(index + 1) + "\n" + item_name
            button.disabled = false


func _on_hud_hotbar_button_pressed(slot_number: int) -> void:
    var player := _get_player()

    if player == null:
        return

    if not player.has_method("use_hotbar_slot"):
        return

    player.use_hotbar_slot(slot_number)
    update_hud()

    if root_ui != null and root_ui.has_method("refresh_character_display"):
        root_ui.refresh_character_display()


func _get_player() -> Node:
    if player_getter.is_valid():
        return player_getter.call()

    return null

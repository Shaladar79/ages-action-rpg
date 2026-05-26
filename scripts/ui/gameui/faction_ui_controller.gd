extends RefCounted
class_name FactionUiController

var root_ui: CanvasLayer = null

var panel: Panel = null
var title_label: Label = null
var close_button: Button = null
var back_button: Button = null
var rows_container: VBoxContainer = null

var selected_faction_id: String = ""


func setup(ui_root: CanvasLayer) -> void:
    root_ui = ui_root
    _create_panel()
    hide_panel()


func show_panel() -> void:
    if panel == null:
        _create_panel()

    selected_faction_id = ""
    refresh_faction_display()
    panel.visible = true


func hide_panel() -> void:
    selected_faction_id = ""

    if panel == null:
        return

    panel.visible = false


func is_visible() -> bool:
    if panel == null:
        return false

    return panel.visible


func refresh_faction_display() -> void:
    if rows_container == null:
        return

    _clear_rows()

    if FactionManager == null:
        _add_text_row("FactionManager is not available.")
        return

    if selected_faction_id.strip_edges() != "":
        _show_faction_detail(selected_faction_id)
    else:
        _show_faction_button_list()


func _create_panel() -> void:
    if panel != null:
        return

    if root_ui == null:
        return

    panel = Panel.new()
    panel.name = "FactionPanel"
    panel.visible = false
    panel.process_mode = Node.PROCESS_MODE_ALWAYS

    panel.anchor_left = 0.5
    panel.anchor_top = 0.5
    panel.anchor_right = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -260.0
    panel.offset_top = -180.0
    panel.offset_right = 260.0
    panel.offset_bottom = 180.0

    root_ui.add_child(panel)

    title_label = Label.new()
    title_label.name = "FactionTitleLabel"
    title_label.text = "Factions"
    title_label.anchor_left = 0.0
    title_label.anchor_top = 0.0
    title_label.anchor_right = 1.0
    title_label.anchor_bottom = 0.0
    title_label.offset_left = 16.0
    title_label.offset_top = 12.0
    title_label.offset_right = -190.0
    title_label.offset_bottom = 42.0
    title_label.add_theme_font_size_override("font_size", 20)
    panel.add_child(title_label)

    back_button = Button.new()
    back_button.name = "FactionBackButton"
    back_button.text = "Back"
    back_button.focus_mode = Control.FOCUS_NONE
    back_button.anchor_left = 1.0
    back_button.anchor_right = 1.0
    back_button.anchor_top = 0.0
    back_button.anchor_bottom = 0.0
    back_button.offset_left = -184.0
    back_button.offset_top = 12.0
    back_button.offset_right = -104.0
    back_button.offset_bottom = 42.0
    back_button.visible = false
    panel.add_child(back_button)

    if not back_button.pressed.is_connected(_on_back_button_pressed):
        back_button.pressed.connect(_on_back_button_pressed)

    close_button = Button.new()
    close_button.name = "FactionCloseButton"
    close_button.text = "Close"
    close_button.focus_mode = Control.FOCUS_NONE
    close_button.anchor_left = 1.0
    close_button.anchor_right = 1.0
    close_button.anchor_top = 0.0
    close_button.anchor_bottom = 0.0
    close_button.offset_left = -96.0
    close_button.offset_top = 12.0
    close_button.offset_right = -16.0
    close_button.offset_bottom = 42.0
    panel.add_child(close_button)

    if not close_button.pressed.is_connected(_on_close_button_pressed):
        close_button.pressed.connect(_on_close_button_pressed)

    var scroll_container := ScrollContainer.new()
    scroll_container.name = "FactionScrollContainer"
    scroll_container.anchor_left = 0.0
    scroll_container.anchor_top = 0.0
    scroll_container.anchor_right = 1.0
    scroll_container.anchor_bottom = 1.0
    scroll_container.offset_left = 16.0
    scroll_container.offset_top = 56.0
    scroll_container.offset_right = -16.0
    scroll_container.offset_bottom = -16.0
    panel.add_child(scroll_container)

    rows_container = VBoxContainer.new()
    rows_container.name = "FactionRowsContainer"
    rows_container.anchor_left = 0.0
    rows_container.anchor_top = 0.0
    rows_container.anchor_right = 1.0
    rows_container.anchor_bottom = 0.0
    rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll_container.add_child(rows_container)


func _clear_rows() -> void:
    if rows_container == null:
        return

    for child in rows_container.get_children():
        child.queue_free()


func _show_faction_button_list() -> void:
    if title_label != null:
        title_label.text = "Factions"

    if back_button != null:
        back_button.visible = false

    var faction_rows: Array[Dictionary] = FactionManager.get_all_faction_rows()

    if faction_rows.is_empty():
        _add_text_row("No factions discovered.")
        return

    _add_text_row("Choose a faction to view its standing.")

    for faction_row in faction_rows:
        _add_faction_button(faction_row)


func _add_faction_button(faction_row: Dictionary) -> void:
    if rows_container == null:
        return

    var faction_id: String = str(faction_row.get("id", "")).strip_edges()
    var faction_name: String = str(faction_row.get("name", "Unknown Faction"))
    var points: int = int(faction_row.get("points", 0))
    var current_tier: Dictionary = faction_row.get("current_tier", {})
    var current_tier_number: int = int(current_tier.get("tier", 0))
    var current_tier_title: String = str(current_tier.get("title", "Unknown"))

    var button := Button.new()
    button.name = "FactionButton_" + faction_id
    button.text = "%s - Tier %s: %s (%s points)" % [
        faction_name,
        current_tier_number,
        current_tier_title,
        points
    ]
    button.focus_mode = Control.FOCUS_NONE
    button.custom_minimum_size = Vector2(460.0, 36.0)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(_on_faction_button_pressed.bind(faction_id))

    rows_container.add_child(button)


func _show_faction_detail(faction_id: String) -> void:
    var faction_row := FactionManager.get_faction_row(faction_id)

    if faction_row.is_empty():
        selected_faction_id = ""
        _show_faction_button_list()
        return

    if back_button != null:
        back_button.visible = true

    var faction_name: String = str(faction_row.get("name", "Unknown Faction"))

    if title_label != null:
        title_label.text = faction_name

    _add_faction_detail_row(faction_row)


func _add_faction_detail_row(faction_row: Dictionary) -> void:
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

    var row_text := "%s\nPoints: %s\nCurrent: Tier %s - %s\n%s\n\n%s" % [
        faction_name,
        points,
        current_tier_number,
        current_tier_title,
        next_text,
        description
    ]

    _add_text_row(row_text)


func _add_text_row(row_text: String) -> void:
    if rows_container == null:
        return

    var label := Label.new()
    label.text = row_text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.custom_minimum_size = Vector2(460.0, 72.0)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override("font_size", 14)
    rows_container.add_child(label)


func _on_faction_button_pressed(faction_id: String) -> void:
    selected_faction_id = faction_id
    refresh_faction_display()


func _on_back_button_pressed() -> void:
    selected_faction_id = ""
    refresh_faction_display()


func _on_close_button_pressed() -> void:
    if root_ui != null and root_ui.has_method("hide_factions"):
        root_ui.hide_factions()
        return

    hide_panel()

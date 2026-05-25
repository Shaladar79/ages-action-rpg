extends RefCounted
class_name QuestTrackerUiController

var root_ui: CanvasLayer = null

var hud_quest_panel: Panel = null
var hud_quest_title_label: Label = null
var hud_quest_rows_container: VBoxContainer = null


func setup(ui_root: CanvasLayer) -> void:
    root_ui = ui_root
    _create_hud_quest_panel()
    refresh_quest_display()


func refresh_quest_display() -> void:
    if hud_quest_panel == null:
        return

    if hud_quest_rows_container == null:
        return

    for child in hud_quest_rows_container.get_children():
        child.queue_free()

    if QuestManager == null:
        hud_quest_panel.visible = false
        return

    if not QuestManager.has_method("get_tracked_quests"):
        hud_quest_panel.visible = false
        return

    var tracked_quests: Array = QuestManager.get_tracked_quests()

    if tracked_quests.is_empty():
        hud_quest_panel.visible = false
        return

    hud_quest_panel.visible = true

    for quest_data in tracked_quests:
        if typeof(quest_data) != TYPE_DICTIONARY:
            continue

        _add_hud_quest_row(quest_data)


func _create_hud_quest_panel() -> void:
    if hud_quest_panel != null:
        return

    if root_ui == null:
        push_warning("Cannot create HUD quest panel. Root UI is null.")
        return

    hud_quest_panel = Panel.new()
    hud_quest_panel.name = "HudQuestPanel"

    # Add directly to the CanvasLayer so right-side anchoring uses the full game window.
    root_ui.add_child(hud_quest_panel)

    hud_quest_panel.anchor_left = 1.0
    hud_quest_panel.anchor_right = 1.0
    hud_quest_panel.anchor_top = 0.0
    hud_quest_panel.anchor_bottom = 0.0

    hud_quest_panel.offset_left = -360.0
    hud_quest_panel.offset_right = -20.0
    hud_quest_panel.offset_top = 16.0
    hud_quest_panel.offset_bottom = 270.0

    hud_quest_panel.custom_minimum_size = Vector2(340.0, 254.0)
    hud_quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_quest_panel.visible = false

    var margin := MarginContainer.new()
    margin.name = "HudQuestMargin"
    margin.anchor_left = 0.0
    margin.anchor_right = 1.0
    margin.anchor_top = 0.0
    margin.anchor_bottom = 1.0
    margin.offset_left = 10.0
    margin.offset_right = -10.0
    margin.offset_top = 8.0
    margin.offset_bottom = -8.0
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_quest_panel.add_child(margin)

    var main_vbox := VBoxContainer.new()
    main_vbox.name = "HudQuestVBox"
    main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_child(main_vbox)

    hud_quest_title_label = Label.new()
    hud_quest_title_label.name = "HudQuestTitleLabel"
    hud_quest_title_label.text = "Tracked Quests"
    hud_quest_title_label.add_theme_font_size_override("font_size", 16)
    hud_quest_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    main_vbox.add_child(hud_quest_title_label)

    hud_quest_rows_container = VBoxContainer.new()
    hud_quest_rows_container.name = "HudQuestRows"
    hud_quest_rows_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    main_vbox.add_child(hud_quest_rows_container)


func _add_hud_quest_row(quest_data: Dictionary) -> void:
    if hud_quest_rows_container == null:
        return

    var quest_title := str(quest_data.get("title", "Quest")).strip_edges()

    if quest_title == "":
        quest_title = "Quest"

    var quest_label := Label.new()
    quest_label.name = "QuestTitleLabel"
    quest_label.text = quest_title
    quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    quest_label.add_theme_font_size_override("font_size", 14)
    quest_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_quest_rows_container.add_child(quest_label)

    var objectives: Dictionary = quest_data.get("objectives", {})

    if objectives.is_empty():
        var objective_text := str(quest_data.get("objective_text", "")).strip_edges()

        if objective_text != "":
            _add_hud_objective_label(objective_text, false, 0, 0)

        return

    for objective_id in objectives.keys():
        var objective_data = objectives.get(objective_id, {})

        if typeof(objective_data) != TYPE_DICTIONARY:
            continue

        var objective_dict: Dictionary = objective_data
        var text := str(objective_dict.get("text", "")).strip_edges()
        var current_amount := int(objective_dict.get("current", 0))
        var required_amount := int(objective_dict.get("required", 1))
        var completed := bool(objective_dict.get("completed", false))

        if text == "":
            text = str(objective_id)

        _add_hud_objective_label(text, completed, current_amount, required_amount)


func _add_hud_objective_label(objective_text: String, completed: bool, current_amount: int, required_amount: int) -> void:
    if hud_quest_rows_container == null:
        return

    var line := "- " + objective_text

    if required_amount > 1:
        line += " " + str(current_amount) + " / " + str(required_amount)

    if completed:
        line = "✓ " + objective_text

        if required_amount > 1:
            line += " " + str(current_amount) + " / " + str(required_amount)

    var label := Label.new()
    label.name = "QuestObjectiveLabel"
    label.text = line
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", 12)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_quest_rows_container.add_child(label)

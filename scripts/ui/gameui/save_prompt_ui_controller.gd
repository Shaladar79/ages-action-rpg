extends RefCounted
class_name SavePromptUiController

var root_ui: CanvasLayer = null

var save_prompt: Control = null
var save_prompt_panel: Panel = null
var save_prompt_message_label: Label = null
var save_yes_button: Button = null
var save_no_button: Button = null

var pending_save_player: Node = null


func setup(ui_root: CanvasLayer) -> void:
    root_ui = ui_root
    _create_save_prompt()
    hide_save_prompt()


func show_save_prompt(save_player: Node, message: String = "Do you want to save your game?") -> void:
    pending_save_player = save_player

    if save_prompt == null:
        _create_save_prompt()

    if save_prompt == null:
        print("Save prompt UI is missing.")
        return

    if save_prompt_message_label != null:
        save_prompt_message_label.text = message

    if root_ui != null:
        if root_ui.has_method("close_character_screen"):
            root_ui.close_character_screen()

        if root_ui.has_method("hide_shop"):
            root_ui.hide_shop()

        if root_ui.has_method("hide_prompt"):
            root_ui.hide_prompt()

        if root_ui.has_method("_set_save_prompt_pause"):
            root_ui._set_save_prompt_pause(true)

    save_prompt.visible = true


func hide_save_prompt() -> void:
    pending_save_player = null

    if save_prompt != null:
        save_prompt.visible = false

    if root_ui != null and root_ui.has_method("_set_save_prompt_pause"):
        root_ui._set_save_prompt_pause(false)


func is_visible() -> bool:
    if save_prompt == null:
        return false

    return save_prompt.visible


func _create_save_prompt() -> void:
    if save_prompt != null:
        return

    if root_ui == null:
        push_warning("Cannot create save prompt. Root UI is null.")
        return

    _hide_legacy_save_prompt()

    save_prompt = Control.new()
    save_prompt.name = "CodeBuiltSavePrompt"
    save_prompt.anchor_left = 0.0
    save_prompt.anchor_right = 1.0
    save_prompt.anchor_top = 0.0
    save_prompt.anchor_bottom = 1.0
    save_prompt.offset_left = 0.0
    save_prompt.offset_right = 0.0
    save_prompt.offset_top = 0.0
    save_prompt.offset_bottom = 0.0
    save_prompt.mouse_filter = Control.MOUSE_FILTER_STOP
    save_prompt.visible = false

    root_ui.add_child(save_prompt)

    save_prompt_panel = Panel.new()
    save_prompt_panel.name = "SavePromptPanel"
    save_prompt_panel.anchor_left = 0.5
    save_prompt_panel.anchor_right = 0.5
    save_prompt_panel.anchor_top = 0.5
    save_prompt_panel.anchor_bottom = 0.5
    save_prompt_panel.offset_left = -190.0
    save_prompt_panel.offset_right = 190.0
    save_prompt_panel.offset_top = -90.0
    save_prompt_panel.offset_bottom = 90.0
    save_prompt_panel.custom_minimum_size = Vector2(380.0, 180.0)
    save_prompt_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    save_prompt.add_child(save_prompt_panel)

    var margin := MarginContainer.new()
    margin.name = "SavePromptMargin"
    margin.anchor_left = 0.0
    margin.anchor_right = 1.0
    margin.anchor_top = 0.0
    margin.anchor_bottom = 1.0
    margin.offset_left = 16.0
    margin.offset_right = -16.0
    margin.offset_top = 16.0
    margin.offset_bottom = -16.0
    save_prompt_panel.add_child(margin)

    var vbox := VBoxContainer.new()
    vbox.name = "SavePromptVBox"
    margin.add_child(vbox)

    save_prompt_message_label = Label.new()
    save_prompt_message_label.name = "MessageLabel"
    save_prompt_message_label.text = "Do you want to save your game?"
    save_prompt_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    save_prompt_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    save_prompt_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    save_prompt_message_label.custom_minimum_size = Vector2(340.0, 70.0)
    save_prompt_message_label.add_theme_font_size_override("font_size", 16)
    vbox.add_child(save_prompt_message_label)

    var button_row := HBoxContainer.new()
    button_row.name = "SavePromptButtonRow"
    button_row.alignment = BoxContainer.ALIGNMENT_CENTER
    button_row.custom_minimum_size = Vector2(340.0, 44.0)
    vbox.add_child(button_row)

    save_yes_button = Button.new()
    save_yes_button.name = "YesButton"
    save_yes_button.text = "Yes"
    save_yes_button.custom_minimum_size = Vector2(120.0, 36.0)
    save_yes_button.focus_mode = Control.FOCUS_NONE
    save_yes_button.pressed.connect(_on_save_yes_button_pressed)
    button_row.add_child(save_yes_button)

    save_no_button = Button.new()
    save_no_button.name = "NoButton"
    save_no_button.text = "No"
    save_no_button.custom_minimum_size = Vector2(120.0, 36.0)
    save_no_button.focus_mode = Control.FOCUS_NONE
    save_no_button.pressed.connect(_on_save_no_button_pressed)
    button_row.add_child(save_no_button)


func _hide_legacy_save_prompt() -> void:
    if root_ui == null:
        return

    var legacy_prompt := root_ui.get_node_or_null("SavePrompt") as CanvasItem

    if legacy_prompt != null:
        legacy_prompt.visible = false


func _on_save_yes_button_pressed() -> void:
    if pending_save_player == null:
        hide_save_prompt()
        return

    var saved := SaveManager.save_game(pending_save_player)

    if saved:
        if pending_save_player.has_method("show_dialogue"):
            pending_save_player.show_dialogue("Game saved.")
    else:
        if pending_save_player.has_method("show_dialogue"):
            pending_save_player.show_dialogue("Save failed.")

    hide_save_prompt()


func _on_save_no_button_pressed() -> void:
    hide_save_prompt()

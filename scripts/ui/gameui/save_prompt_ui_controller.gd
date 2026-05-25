extends RefCounted
class_name SavePromptUiController

var root_ui: CanvasLayer = null
var save_prompt: Control = null
var save_prompt_message_label: Label = null
var save_yes_button: Button = null
var save_no_button: Button = null
var pending_save_player: Node = null


func setup(
        ui_root: CanvasLayer,
        prompt_node: Control,
        message_label: Label,
        yes_button: Button,
        no_button: Button
) -> void:
    root_ui = ui_root
    save_prompt = prompt_node
    save_prompt_message_label = message_label
    save_yes_button = yes_button
    save_no_button = no_button

    if save_prompt != null:
        save_prompt.visible = false

    _connect_buttons()


func show_save_prompt(save_player: Node, message: String = "Do you want to save your game?") -> void:
    pending_save_player = save_player

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


func _connect_buttons() -> void:
    if save_yes_button != null and not save_yes_button.pressed.is_connected(_on_save_yes_button_pressed):
        save_yes_button.pressed.connect(_on_save_yes_button_pressed)

    if save_no_button != null and not save_no_button.pressed.is_connected(_on_save_no_button_pressed):
        save_no_button.pressed.connect(_on_save_no_button_pressed)


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

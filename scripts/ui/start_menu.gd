extends Control

@export_file("*.tscn") var new_game_scene_path: String = ""

@onready var new_game_button: Button = $MenuPanel/NewGameButton
@onready var load_game_button: Button = $MenuPanel/LoadGameButton

var load_saves_panel: Panel = null
var load_saves_list: VBoxContainer = null
var close_load_saves_button: Button = null

var delete_save_confirm_dialog: ConfirmationDialog = null
var pending_delete_save_file_id: String = ""
var pending_delete_save_display_name: String = ""


func _ready() -> void:
    _hide_game_ui_autoload()
    _create_load_saves_panel()
    _create_delete_save_confirm_dialog()

    if not new_game_button.pressed.is_connected(_on_new_game_button_pressed):
        new_game_button.pressed.connect(_on_new_game_button_pressed)

    if not load_game_button.pressed.is_connected(_on_load_game_button_pressed):
        load_game_button.pressed.connect(_on_load_game_button_pressed)

    _update_load_button()


func _hide_game_ui_autoload() -> void:
    var game_ui := get_node_or_null("/root/GameUi")

    if game_ui != null:
        game_ui.visible = false


func _show_game_ui_autoload() -> void:
    var game_ui := get_node_or_null("/root/GameUi")

    if game_ui != null:
        game_ui.visible = true


func _update_load_button() -> void:
    if not SaveManager.has_save_file():
        load_game_button.disabled = true
        load_game_button.text = "Load Game"
        return

    load_game_button.disabled = false
    load_game_button.text = "Load Game"


func _on_new_game_button_pressed() -> void:
    print("New Game pressed.")
    print("New Game Scene Path: ", new_game_scene_path)

    if new_game_scene_path.strip_edges() == "":
        push_warning("No new game scene path set on StartMenu.")
        return

    if not ResourceLoader.exists(new_game_scene_path):
        push_warning("New game scene path does not exist: " + new_game_scene_path)
        return

    RespawnManager.clear_respawn_point()
    SaveManager.clear_pending_loaded_data()
    SaveManager.clear_runtime_world_state()
    SceneTransitionManager.clear_all_transition_data()

    _show_game_ui_autoload()
    get_tree().change_scene_to_file(new_game_scene_path)


func _on_load_game_button_pressed() -> void:
    if not SaveManager.has_save_file():
        print("No save file found.")
        return

    _refresh_load_saves_panel()
    load_saves_panel.visible = true


func _create_load_saves_panel() -> void:
    if load_saves_panel != null:
        return

    load_saves_panel = Panel.new()
    load_saves_panel.name = "CodeBuiltLoadSavesPanel"
    load_saves_panel.anchor_left = 0.5
    load_saves_panel.anchor_right = 0.5
    load_saves_panel.anchor_top = 0.5
    load_saves_panel.anchor_bottom = 0.5
    load_saves_panel.offset_left = -300.0
    load_saves_panel.offset_right = 300.0
    load_saves_panel.offset_top = -220.0
    load_saves_panel.offset_bottom = 220.0
    load_saves_panel.custom_minimum_size = Vector2(600.0, 440.0)
    load_saves_panel.visible = false
    load_saves_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(load_saves_panel)

    var margin := MarginContainer.new()
    margin.name = "LoadSavesMargin"
    margin.anchor_left = 0.0
    margin.anchor_right = 1.0
    margin.anchor_top = 0.0
    margin.anchor_bottom = 1.0
    margin.offset_left = 16.0
    margin.offset_right = -16.0
    margin.offset_top = 16.0
    margin.offset_bottom = -16.0
    load_saves_panel.add_child(margin)

    var vbox := VBoxContainer.new()
    vbox.name = "LoadSavesVBox"
    vbox.add_theme_constant_override("separation", 10)
    margin.add_child(vbox)

    var title := Label.new()
    title.name = "LoadSavesTitle"
    title.text = "Load Game"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 20)
    vbox.add_child(title)

    load_saves_list = VBoxContainer.new()
    load_saves_list.name = "LoadSavesList"
    load_saves_list.custom_minimum_size = Vector2(560.0, 320.0)
    load_saves_list.add_theme_constant_override("separation", 6)
    vbox.add_child(load_saves_list)

    close_load_saves_button = Button.new()
    close_load_saves_button.name = "CloseLoadSavesButton"
    close_load_saves_button.text = "Close"
    close_load_saves_button.custom_minimum_size = Vector2(140.0, 36.0)
    close_load_saves_button.focus_mode = Control.FOCUS_NONE
    close_load_saves_button.pressed.connect(_on_close_load_saves_pressed)
    vbox.add_child(close_load_saves_button)


func _create_delete_save_confirm_dialog() -> void:
    if delete_save_confirm_dialog != null:
        return

    delete_save_confirm_dialog = ConfirmationDialog.new()
    delete_save_confirm_dialog.name = "DeleteSaveConfirmDialog"
    delete_save_confirm_dialog.title = "Delete Save File"
    delete_save_confirm_dialog.dialog_text = "Are you sure you wish to delete this save file?"
    delete_save_confirm_dialog.exclusive = true
    add_child(delete_save_confirm_dialog)

    delete_save_confirm_dialog.confirmed.connect(_on_delete_save_confirmed)

    var ok_button := delete_save_confirm_dialog.get_ok_button()
    var cancel_button := delete_save_confirm_dialog.get_cancel_button()

    if ok_button != null:
        ok_button.text = "Yes, Delete"

    if cancel_button != null:
        cancel_button.text = "No"


func _refresh_load_saves_panel() -> void:
    if load_saves_list == null:
        return

    for child in load_saves_list.get_children():
        child.queue_free()

    var save_rows := SaveManager.get_save_slot_rows()

    if save_rows.is_empty():
        var no_saves_label := Label.new()
        no_saves_label.text = "No save files found."
        no_saves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        load_saves_list.add_child(no_saves_label)
        return

    for save_row in save_rows:
        if typeof(save_row) != TYPE_DICTIONARY:
            continue

        var file_id := str(save_row.get("file_id", ""))
        var display_name := str(save_row.get("display_name", "Saved Game"))
        var map_name := str(save_row.get("map_name", ""))
        var level := int(save_row.get("level", 0))
        var saved_at := str(save_row.get("saved_at", ""))

        var row := HBoxContainer.new()
        row.name = "LoadSaveRow_" + file_id
        row.custom_minimum_size = Vector2(560.0, 54.0)
        row.add_theme_constant_override("separation", 8)

        var button := Button.new()
        button.name = "LoadSaveButton_" + file_id
        button.focus_mode = Control.FOCUS_NONE
        button.custom_minimum_size = Vector2(500.0, 54.0)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

        var button_text := display_name

        if map_name != "":
            button_text += "\n" + map_name

        if level > 0:
            button_text += " | Lv" + str(level)

        if saved_at != "":
            button_text += " | " + saved_at

        button.text = button_text
        button.pressed.connect(_on_save_slot_pressed.bind(file_id))

        var delete_button := Button.new()
        delete_button.name = "DeleteSaveButton_" + file_id
        delete_button.text = "🗑"
        delete_button.tooltip_text = "Delete save file"
        delete_button.focus_mode = Control.FOCUS_NONE
        delete_button.custom_minimum_size = Vector2(48.0, 54.0)
        delete_button.pressed.connect(_on_delete_save_button_pressed.bind(file_id, display_name))

        row.add_child(button)
        row.add_child(delete_button)

        load_saves_list.add_child(row)


func _on_save_slot_pressed(save_file_id: String) -> void:
    print("Loading save file id: ", save_file_id)
    _show_game_ui_autoload()
    SaveManager.load_game_from_menu(save_file_id)


func _on_delete_save_button_pressed(save_file_id: String, save_display_name: String) -> void:
    pending_delete_save_file_id = save_file_id
    pending_delete_save_display_name = save_display_name

    if delete_save_confirm_dialog == null:
        return

    delete_save_confirm_dialog.dialog_text = "Are you sure you wish to delete this save file?\n\n" + save_display_name
    delete_save_confirm_dialog.popup_centered()


func _on_delete_save_confirmed() -> void:
    if pending_delete_save_file_id.strip_edges() == "":
        return

    var deleted := SaveManager.delete_save_file(pending_delete_save_file_id)

    if deleted:
        print("Deleted save from load menu: ", pending_delete_save_file_id)
    else:
        push_warning("Failed to delete save from load menu: " + pending_delete_save_file_id)

    pending_delete_save_file_id = ""
    pending_delete_save_display_name = ""

    _refresh_load_saves_panel()
    _update_load_button()

    if not SaveManager.has_save_file():
        load_saves_panel.visible = false


func _on_close_load_saves_pressed() -> void:
    load_saves_panel.visible = false

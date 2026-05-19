extends Control

@export_file("*.tscn") var new_game_scene_path: String = ""

@onready var new_game_button: Button = $MenuPanel/NewGameButton
@onready var load_game_button: Button = $MenuPanel/LoadGameButton


func _ready() -> void:
    _hide_game_ui_autoload()

    if not new_game_button.pressed.is_connected(_on_new_game_button_pressed):
        new_game_button.pressed.connect(_on_new_game_button_pressed)

    if not load_game_button.pressed.is_connected(_on_load_game_button_pressed):
        load_game_button.pressed.connect(_on_load_game_button_pressed)

    load_game_button.disabled = true


func _hide_game_ui_autoload() -> void:
    var game_ui := get_node_or_null("/root/GameUi")

    if game_ui != null:
        game_ui.visible = false


func _show_game_ui_autoload() -> void:
    var game_ui := get_node_or_null("/root/GameUi")

    if game_ui != null:
        game_ui.visible = true


func _on_new_game_button_pressed() -> void:
    print("New Game pressed.")
    print("New Game Scene Path: ", new_game_scene_path)

    if new_game_scene_path.strip_edges() == "":
        push_warning("No new game scene path set on StartMenu.")
        return

    if not ResourceLoader.exists(new_game_scene_path):
        push_warning("New game scene path does not exist: " + new_game_scene_path)
        return

    _show_game_ui_autoload()
    get_tree().change_scene_to_file(new_game_scene_path)


func _on_load_game_button_pressed() -> void:
    print("Load Game is not active yet.")

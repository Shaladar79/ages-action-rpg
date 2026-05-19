extends Interactable
class_name SavePointInteractable

@export var respawn_id: String = "start_cavern_totem"
@export var activated_message: String = "Respawn point activated."
@export var already_active_message: String = "This respawn point is already active."
@export var save_prompt_message: String = "Do you want to save your game?"

@export var respawn_marker_path: NodePath = NodePath("RespawnMarker")

var is_activated: bool = false


func _ready() -> void:
    interaction_id = respawn_id
    interaction_prompt = "Press E to activate."
    one_shot = false

    super._ready()


func _on_interact(player: Node2D) -> void:
    var respawn_position := _get_respawn_position()
    var scene_path := _get_current_scene_path()

    RespawnManager.set_respawn_point(respawn_id, scene_path, respawn_position)

    print("Save point using respawn position: ", respawn_position)

    if is_activated:
        _show_or_print_message(player, already_active_message)
    else:
        is_activated = true
        _show_or_print_message(player, activated_message)

    _show_save_prompt(player)


func _show_save_prompt(player: Node2D) -> void:
    print("Trying to show save prompt...")

    var game_ui := get_node_or_null("/root/GameUi")

    if game_ui == null:
        print("No /root/GameUi found. Trying interaction_ui group.")
        game_ui = get_tree().get_first_node_in_group("interaction_ui")

    if game_ui == null:
        push_warning("No GameUi found. Cannot show save prompt.")
        return

    print("Found UI node: ", game_ui.name)

    if not game_ui.has_method("show_save_prompt"):
        push_warning("Found UI node does not have show_save_prompt(): " + game_ui.name)
        return

    print("Calling GameUi.show_save_prompt().")
    game_ui.show_save_prompt(player, save_prompt_message)


func _get_respawn_position() -> Vector2:
    var marker := get_node_or_null(respawn_marker_path) as Node2D

    if marker != null:
        return marker.global_position

    marker = find_child("RespawnMarker", true, false) as Node2D

    if marker != null:
        return marker.global_position

    push_warning("No RespawnMarker found for save point: " + name + ". Using save point position.")
    return global_position


func _get_current_scene_path() -> String:
    var current_scene := get_tree().current_scene

    if current_scene == null:
        return ""

    return current_scene.scene_file_path


func _show_or_print_message(player: Node2D, message: String) -> void:
    if message.strip_edges() == "":
        return

    if player != null and player.has_method("show_dialogue"):
        player.show_dialogue(message)
    else:
        print(message)

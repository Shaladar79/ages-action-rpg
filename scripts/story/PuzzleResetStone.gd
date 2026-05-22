extends Area2D
class_name PuzzleResetStone

@export var reset_id: String = ""
@export var push_object_paths: Array[NodePath] = []

@export var interaction_prompt_text: String = "E"
@export var reset_message: String = "The puzzle stones return to their starting places."

var player_in_range: Node = null


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

    if reset_id.strip_edges() == "":
        reset_id = name


func _process(_delta: float) -> void:
    if player_in_range == null:
        return

    if Input.is_action_just_pressed("interact"):
        reset_puzzle()


func reset_puzzle() -> void:
    var reset_count := 0

    for push_object_path in push_object_paths:
        var push_object := get_node_or_null(push_object_path)

        if push_object == null:
            push_warning("PuzzleResetStone could not find push object path: " + str(push_object_path))
            continue

        if not push_object.has_method("reset_to_starting_position"):
            push_warning("PuzzleResetStone target cannot reset: " + push_object.name)
            continue

        push_object.reset_to_starting_position()
        reset_count += 1

    print("Puzzle reset stone used: ", reset_id, " reset count: ", reset_count)

    _show_reset_message()


func _show_reset_message() -> void:
    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_story_message"):
        game_ui.show_story_message(reset_message, "Reset Stone")
        return

    if player_in_range != null and player_in_range.has_method("show_dialogue"):
        player_in_range.show_dialogue(reset_message)


func _show_prompt() -> void:
    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_prompt"):
        game_ui.show_prompt(interaction_prompt_text)


func _hide_prompt() -> void:
    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("hide_prompt"):
        game_ui.hide_prompt()


func _get_game_ui() -> Node:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null:
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null:
        return autoload_ui

    return null


func _is_player(body: Node) -> bool:
    if body == null:
        return false

    return body.is_in_group("player")


func _on_body_entered(body: Node) -> void:
    if not _is_player(body):
        return

    player_in_range = body
    _show_prompt()


func _on_body_exited(body: Node) -> void:
    if body != player_in_range:
        return

    player_in_range = null
    _hide_prompt()

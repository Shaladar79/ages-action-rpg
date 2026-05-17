extends Interactable

@export var show_first_push_tutorial: bool = true
@export_multiline var first_push_dialogue: String = "This rock is blocking my path. I wonder if I can push it out of the way?"

var first_push_tutorial_started: bool = false
var first_push_tutorial_ready_for_interact: bool = false
var first_push_tutorial_completed: bool = false


func _on_body_entered(body: Node2D) -> void:
    super._on_body_entered(body)

    if not show_first_push_tutorial:
        return

    if first_push_tutorial_completed:
        return

    if first_push_tutorial_started:
        return

    if not body.is_in_group("player"):
        return

    first_push_tutorial_started = true
    first_push_tutorial_ready_for_interact = false

    if body.has_method("show_dialogue"):
        body.show_dialogue(first_push_dialogue)

    var tutorial_ui := get_tree().get_first_node_in_group("tutorial_ui")

    if tutorial_ui != null and tutorial_ui.has_method("show_dialogue_continue_tutorial"):
        tutorial_ui.show_dialogue_continue_tutorial()


func on_player_dialogue_closed(player: Node2D) -> void:
    if not show_first_push_tutorial:
        return

    if first_push_tutorial_completed:
        return

    if not first_push_tutorial_started:
        return

    first_push_tutorial_ready_for_interact = true

    var tutorial_ui := get_tree().get_first_node_in_group("tutorial_ui")

    if tutorial_ui != null and tutorial_ui.has_method("show_push_object_tutorial"):
        tutorial_ui.show_push_object_tutorial()


func _on_interact(player: Node2D) -> void:
    if show_first_push_tutorial and first_push_tutorial_started and not first_push_tutorial_ready_for_interact:
        print("Finish the dialogue first.")
        return

    var push_object := get_parent()

    if push_object == null:
        return

    if push_object.has_method("push_from_player"):
        push_object.push_from_player(player)
    else:
        print("Push object parent does not have push_from_player().")

    if show_first_push_tutorial and first_push_tutorial_started and not first_push_tutorial_completed:
        first_push_tutorial_completed = true
        first_push_tutorial_ready_for_interact = false

        var tutorial_ui := get_tree().get_first_node_in_group("tutorial_ui")

        if tutorial_ui != null and tutorial_ui.has_method("finish_push_object_tutorial"):
            tutorial_ui.finish_push_object_tutorial()

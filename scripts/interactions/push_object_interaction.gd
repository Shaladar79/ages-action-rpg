extends Interactable

@export var show_first_push_tutorial: bool = false
@export_multiline var first_push_dialogue: String = "This rock is blocking my path. I wonder if I can push it out of the way?"


func _on_body_entered(body: Node2D) -> void:
    super._on_body_entered(body)


func on_player_dialogue_closed(_player: Node2D) -> void:
    pass


func _on_interact(player: Node2D) -> void:
    var push_object := get_parent()

    if push_object == null:
        return

    if push_object.has_method("push_from_player"):
        push_object.push_from_player(player)
    else:
        print("Push object parent does not have push_from_player().")

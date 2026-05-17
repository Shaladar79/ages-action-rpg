extends Interactable

@export_multiline var blocked_message: String = "This rock is cracked, but I need something heavy to break it."


func _on_interact(player: Node2D) -> void:
    var breakable_object := get_parent()

    if breakable_object == null:
        return

    if not breakable_object.has_method("try_break"):
        print("Breakable object parent does not have try_break().")
        return

    if breakable_object.has_method("can_break") and not breakable_object.can_break(player):
        if player.has_method("show_dialogue"):
            player.show_dialogue(blocked_message)
        else:
            print(blocked_message)
        return

    breakable_object.try_break(player)

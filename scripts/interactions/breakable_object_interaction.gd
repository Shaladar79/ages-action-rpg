extends Interactable

@export_multiline var blocked_message: String = "This rock is cracked, but I need something heavy to break it."
@export_multiline var ready_message: String = "This rock looks breakable. I should attack it with the right tool."


func _on_interact(player: Node2D) -> void:
    var breakable_object := get_parent()

    if breakable_object == null:
        return

    if not breakable_object.has_method("can_be_damaged_by"):
        print("Breakable object parent does not have can_be_damaged_by().")
        return

    if not breakable_object.can_be_damaged_by(player):
        _show_or_print_message(player, blocked_message)
        return

    _show_or_print_message(player, ready_message)


func _show_or_print_message(player: Node2D, message: String) -> void:
    if message.strip_edges() == "":
        return

    if player != null and player.has_method("show_dialogue"):
        player.show_dialogue(message)
    else:
        print(message)

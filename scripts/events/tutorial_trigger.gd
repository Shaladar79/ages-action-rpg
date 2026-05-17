extends Area2D

@export var tutorial_id: String = ""
@export_multiline var message: String = ""
@export var one_shot: bool = true

var has_triggered: bool = false


func _ready() -> void:
    body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
    if one_shot and has_triggered:
        return

    if not body.is_in_group("player"):
        return

    has_triggered = true

    var tutorial_ui := get_tree().get_first_node_in_group("tutorial_ui")

    if tutorial_ui == null:
        print("Tutorial Triggered: ", tutorial_id)
        print(message)
        return

    if tutorial_id == "movement_intro" and tutorial_ui.has_method("start_movement_tutorial"):
        tutorial_ui.start_movement_tutorial()
        return

    if tutorial_ui.has_method("show_message"):
        tutorial_ui.show_message(message)
    else:
        print("Tutorial Triggered: ", tutorial_id)
        print(message)

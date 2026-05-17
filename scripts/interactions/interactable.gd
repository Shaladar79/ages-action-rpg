extends Area2D
class_name Interactable

@export var interaction_id: String = ""
@export var interaction_prompt: String = "Press E to interact."
@export var one_shot: bool = false

var player_in_range: Node2D = null
var has_interacted: bool = false


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group("player"):
        return

    player_in_range = body

    if body.has_method("set_nearby_interactable"):
        body.set_nearby_interactable(self)


func _on_body_exited(body: Node2D) -> void:
    if body != player_in_range:
        return

    if body.has_method("clear_nearby_interactable"):
        body.clear_nearby_interactable(self)

    player_in_range = null


func interact(player: Node2D) -> void:
    if one_shot and has_interacted:
        return

    has_interacted = true
    _on_interact(player)


func _on_interact(player: Node2D) -> void:
    print("Interacted with: ", interaction_id)

extends Node
class_name NPCBehaviorModule

var npc_actor: Node = null


func setup(actor: Node) -> void:
    npc_actor = actor


func can_handle_interact(_player: Node) -> bool:
    return false


func handle_interact(_player: Node) -> bool:
    return false


func on_player_entered(_player: Node) -> void:
    pass


func on_player_exited(_player: Node) -> void:
    pass


func set_behavior_enabled(_enabled: bool) -> void:
    pass


func get_interaction_priority() -> int:
    return 0

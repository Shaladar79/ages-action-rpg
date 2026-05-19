extends Node

var has_active_respawn_point: bool = false
var active_respawn_id: String = ""
var active_scene_path: String = ""
var active_respawn_position: Vector2 = Vector2.ZERO


func set_respawn_point(respawn_id: String, scene_path: String, respawn_position: Vector2) -> void:
    has_active_respawn_point = true
    active_respawn_id = respawn_id
    active_scene_path = scene_path
    active_respawn_position = respawn_position

    print("Respawn point activated: ", active_respawn_id)
    print("Respawn scene: ", active_scene_path)
    print("Respawn position: ", active_respawn_position)


func clear_respawn_point() -> void:
    has_active_respawn_point = false
    active_respawn_id = ""
    active_scene_path = ""
    active_respawn_position = Vector2.ZERO


func get_respawn_position() -> Vector2:
    return active_respawn_position


func get_respawn_scene_path() -> String:
    return active_scene_path


func can_respawn() -> bool:
    return has_active_respawn_point

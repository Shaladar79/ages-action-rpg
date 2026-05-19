extends CharacterBody2D
class_name PushObject

@export var persistent_id: String = ""

@export var push_distance: float = 32.0
@export var push_duration: float = 0.18

var is_being_pushed: bool = false


func _ready() -> void:
    _apply_saved_position_if_needed()


func _apply_saved_position_if_needed() -> void:
    if persistent_id.strip_edges() == "":
        return

    if not SaveManager.has_persistent_object_position(persistent_id):
        return

    global_position = SaveManager.get_persistent_object_position(persistent_id, global_position)
    print("Push object loaded at saved position: ", persistent_id, " ", global_position)


func push_from_player(player: Node2D) -> void:
    if is_being_pushed:
        return

    var push_direction := _get_push_direction_from_player(player)

    if push_direction == Vector2.ZERO:
        print("Push object has no valid push direction.")
        return

    var movement := push_direction * push_distance

    if test_move(global_transform, movement):
        print("Push object blocked.")
        return

    is_being_pushed = true

    var target_position := global_position + movement
    var tween := create_tween()
    tween.tween_property(self, "global_position", target_position, push_duration)
    tween.finished.connect(_on_push_finished)

    print("Push object moved: ", push_direction)


func _get_push_direction_from_player(player: Node2D) -> Vector2:
    var difference := global_position - player.global_position

    if abs(difference.x) > abs(difference.y):
        if difference.x > 0:
            return Vector2.RIGHT
        else:
            return Vector2.LEFT
    else:
        if difference.y > 0:
            return Vector2.DOWN
        else:
            return Vector2.UP


func _on_push_finished() -> void:
    is_being_pushed = false

    if persistent_id.strip_edges() != "":
        SaveManager.set_persistent_object_position(persistent_id, global_position)
        print("Saved push object position: ", persistent_id, " ", global_position)

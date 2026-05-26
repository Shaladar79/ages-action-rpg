extends Node2D
class_name NPCQuestFlagMover

enum TriggerType {
    FLAG,
    QUEST_COMPLETED
}

@export var trigger_type: TriggerType = TriggerType.FLAG

@export var required_flag: String = ""
@export var required_quest_id: String = ""

@export var completion_save_flag: String = ""

@export var movement_speed: float = 60.0
@export var path_marker_paths: Array[NodePath] = []

@export var disable_interaction_while_moving: bool = true
@export var fade_out_at_end: bool = true
@export var fade_duration: float = 0.75
@export var hide_at_end: bool = true
@export var remove_after_fade: bool = false

var _is_running: bool = false
var _path_index: int = 0
var _path_points: Array[Vector2] = []


func _ready() -> void:
    if completion_save_flag.strip_edges() != "" and SaveManager.is_flag_set(completion_save_flag):
        _apply_already_completed_state()
        return

    _cache_path_points()


func _process(delta: float) -> void:
    if _is_running:
        _move_along_path(delta)
        return

    if _should_start_movement():
        start_movement_event()


func start_movement_event() -> void:
    if _is_running:
        return

    if path_marker_paths.is_empty():
        push_warning("NPCQuestFlagMover has no path markers.")
        return

    _cache_path_points()

    if _path_points.is_empty():
        push_warning("NPCQuestFlagMover found no valid path marker positions.")
        return

    _is_running = true
    _path_index = 0

    if disable_interaction_while_moving:
        _set_interaction_enabled(false)


func _should_start_movement() -> bool:
    match trigger_type:
        TriggerType.FLAG:
            var clean_flag := required_flag.strip_edges()

            if clean_flag == "":
                return false

            return SaveManager.is_flag_set(clean_flag)

        TriggerType.QUEST_COMPLETED:
            var clean_quest_id := required_quest_id.strip_edges()

            if clean_quest_id == "":
                return false

            return QuestManager.is_quest_completed(clean_quest_id)

    return false


func _cache_path_points() -> void:
    _path_points.clear()

    for marker_path in path_marker_paths:
        if marker_path.is_empty():
            continue

        var marker_node := get_node_or_null(marker_path)

        if marker_node == null:
            continue

        if marker_node is Node2D:
            _path_points.append(marker_node.global_position)


func _move_along_path(delta: float) -> void:
    if _path_index >= _path_points.size():
        _finish_movement_event()
        return

    var target_position := _path_points[_path_index]
    var move_amount := movement_speed * delta

    global_position = global_position.move_toward(target_position, move_amount)

    if global_position.distance_to(target_position) <= 1.0:
        global_position = target_position
        _path_index += 1

        if _path_index >= _path_points.size():
            _finish_movement_event()


func _finish_movement_event() -> void:
    if not _is_running:
        return

    _is_running = false

    var clean_completion_flag := completion_save_flag.strip_edges()

    if clean_completion_flag != "":
        SaveManager.set_flag(clean_completion_flag, true)

    if fade_out_at_end:
        await _fade_out()
    else:
        _apply_finished_visibility()

    if remove_after_fade:
        queue_free()


func _fade_out() -> void:
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, fade_duration)
    await tween.finished

    _apply_finished_visibility()


func _apply_finished_visibility() -> void:
    if hide_at_end:
        visible = false
        process_mode = Node.PROCESS_MODE_DISABLED


func _apply_already_completed_state() -> void:
    visible = false
    process_mode = Node.PROCESS_MODE_DISABLED


func _set_interaction_enabled(enabled: bool) -> void:
    if has_method("set_interaction_enabled"):
        call("set_interaction_enabled", enabled)
        return

    if "interaction_enabled" in self:
        set("interaction_enabled", enabled)
        return

    if "can_interact" in self:
        set("can_interact", enabled)
        return

    if "is_interactable" in self:
        set("is_interactable", enabled)
        return

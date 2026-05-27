extends Node2D
class_name NPCQuestFlagMover

enum TriggerType {
    FLAG,
    QUEST_COMPLETED
}

enum MovementMode {
    MOVE_THEN_FADE,
    FADE_ONLY
}

@export var trigger_type: TriggerType = TriggerType.FLAG
@export var movement_mode: MovementMode = MovementMode.MOVE_THEN_FADE

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

@export_group("Debug")
@export var debug_prints: bool = true

var _is_running: bool = false
var _has_finished: bool = false
var _path_index: int = 0
var _path_points: Array[Vector2] = []


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    if completion_save_flag.strip_edges() != "" and SaveManager.is_flag_set(completion_save_flag):
        if debug_prints:
            print("NPCQuestFlagMover already completed from save flag: ", completion_save_flag)

        _has_finished = true
        _apply_already_completed_state()
        return

    _cache_path_points()

    if debug_prints:
        print("NPCQuestFlagMover ready on: ", name)
        print("Movement mode: ", movement_mode)
        print("Cached path point count: ", _path_points.size())


func _process(delta: float) -> void:
    if _has_finished:
        return

    if _is_running:
        if movement_mode == MovementMode.MOVE_THEN_FADE:
            _move_along_path(delta)

        return

    if _should_start_movement():
        start_movement_event()


func start_movement_event() -> void:
    if _is_running:
        return

    if _has_finished:
        return

    if movement_mode == MovementMode.FADE_ONLY:
        _is_running = true
        visible = true

        if disable_interaction_while_moving:
            _set_interaction_enabled(false)

        if debug_prints:
            print("NPCQuestFlagMover started fade-only event.")

        _finish_movement_event()
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
    visible = true
    modulate.a = 1.0

    if disable_interaction_while_moving:
        _set_interaction_enabled(false)

    if debug_prints:
        print("NPCQuestFlagMover started movement.")
        print("Starting position: ", global_position)
        print("First target position: ", _path_points[0])
        print("Path point count: ", _path_points.size())


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
        if marker_path == NodePath(""):
            continue

        var marker_node := get_node_or_null(marker_path)

        if marker_node == null:
            marker_node = _get_node_from_current_scene(marker_path)

        if marker_node == null:
            if debug_prints:
                push_warning("NPCQuestFlagMover could not find marker path: " + str(marker_path))
            continue

        if marker_node is Node2D:
            var marker_2d := marker_node as Node2D
            _path_points.append(marker_2d.global_position)

            if debug_prints:
                print("NPCQuestFlagMover cached marker: ", marker_node.name, " at ", marker_2d.global_position)
        else:
            if debug_prints:
                push_warning("NPCQuestFlagMover marker is not Node2D: " + str(marker_path))


func _get_node_from_current_scene(marker_path: NodePath) -> Node:
    var current_scene := get_tree().current_scene

    if current_scene == null:
        return null

    return current_scene.get_node_or_null(marker_path)


func _move_along_path(delta: float) -> void:
    if _path_index >= _path_points.size():
        _finish_movement_event()
        return

    var target_position := _path_points[_path_index]
    var move_amount := movement_speed * delta

    global_position = global_position.move_toward(target_position, move_amount)

    if debug_prints:
        print("NPC moving. Position: ", global_position, " Target: ", target_position)

    if global_position.distance_to(target_position) <= 1.0:
        global_position = target_position
        _path_index += 1

        if debug_prints:
            print("NPCQuestFlagMover reached path point: ", _path_index, " / ", _path_points.size())

        if _path_index >= _path_points.size():
            _finish_movement_event()


func _finish_movement_event() -> void:
    if not _is_running:
        return

    _is_running = false
    _has_finished = true

    var clean_completion_flag := completion_save_flag.strip_edges()

    if clean_completion_flag != "":
        SaveManager.set_flag(clean_completion_flag, true)

        if debug_prints:
            print("NPCQuestFlagMover set completion flag: ", clean_completion_flag)

    if fade_out_at_end:
        await _fade_out()
    else:
        _apply_finished_visibility()

    if remove_after_fade:
        queue_free()


func _fade_out() -> void:
    var safe_duration := maxf(0.01, fade_duration)

    var tween := create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(self, "modulate:a", 0.0, safe_duration)

    await tween.finished

    _apply_finished_visibility()


func _apply_finished_visibility() -> void:
    if hide_at_end:
        visible = false
        process_mode = Node.PROCESS_MODE_DISABLED
    else:
        if disable_interaction_while_moving:
            _set_interaction_enabled(true)


func _apply_already_completed_state() -> void:
    visible = false
    process_mode = Node.PROCESS_MODE_DISABLED


func _set_interaction_enabled(enabled: bool) -> void:
    _set_interaction_enabled_on_node(self, enabled)

    for child in get_children():
        _set_interaction_enabled_recursive(child, enabled)


func _set_interaction_enabled_recursive(node: Node, enabled: bool) -> void:
    _set_interaction_enabled_on_node(node, enabled)

    for child in node.get_children():
        _set_interaction_enabled_recursive(child, enabled)


func _set_interaction_enabled_on_node(node: Node, enabled: bool) -> void:
    if node == null:
        return

    if node != self and node.has_method("set_interaction_enabled"):
        node.call("set_interaction_enabled", enabled)
        return

    if node is CollisionShape2D:
        var collision_shape := node as CollisionShape2D
        collision_shape.set_deferred("disabled", not enabled)
        return

    if node is CollisionPolygon2D:
        var collision_polygon := node as CollisionPolygon2D
        collision_polygon.set_deferred("disabled", not enabled)
        return

    if node is Area2D:
        var area := node as Area2D
        area.set_deferred("monitoring", enabled)
        area.set_deferred("monitorable", enabled)
        return

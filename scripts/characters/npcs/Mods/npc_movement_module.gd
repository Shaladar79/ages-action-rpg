extends NPCBehaviorModule
class_name NPCMovementModule

const ACTION_FADE_OUT_ONLY: int = 0
const ACTION_FADE_IN_ONLY: int = 1
const ACTION_FADE_OUT_MOVE_FADE_IN: int = 2
const ACTION_MOVE_ONLY: int = 3
const ACTION_MOVE_THEN_FADE_OUT: int = 4

@export_group("Movement Events")
@export var movement_events: Array[Resource] = []

@export_group("Fallback / Manual Event")
@export var fallback_movement_speed: float = 60.0
@export var fallback_target_marker_path: NodePath = NodePath("")
@export var fallback_fade_out_duration: float = 0.75
@export var fallback_fade_in_duration: float = 0.75

@export_group("Behavior")
@export var enabled: bool = true
@export var auto_check_events: bool = true
@export var check_interval: float = 0.15

@export_group("Debug")
@export var debug_prints: bool = true

var _is_running: bool = false
var _check_timer: float = 0.0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    if debug_prints:
        print("NPCMovementModule ready: ", name)
        print("Movement event count: ", movement_events.size())


func _process(delta: float) -> void:
    if not enabled:
        return

    if not auto_check_events:
        return

    if _is_running:
        return

    _check_timer -= delta

    if _check_timer > 0.0:
        return

    _check_timer = check_interval
    _try_run_next_available_event()


func can_handle_interact(_player: Node) -> bool:
    return false


func handle_interact(_player: Node) -> bool:
    return false


func set_behavior_enabled(new_enabled: bool) -> void:
    enabled = new_enabled


func start_movement_event() -> void:
    if _is_running:
        return

    var event := _get_next_available_event()

    if event != null:
        _run_event(event)
        return

    _run_fallback_event()


func run_event_by_id(event_id: String) -> bool:
    var clean_event_id := event_id.strip_edges()

    if clean_event_id == "":
        return false

    if _is_running:
        return false

    for event_resource in movement_events:
        if event_resource == null:
            continue

        var resource_event_id := str(event_resource.get("event_id")).strip_edges()

        if resource_event_id != clean_event_id:
            continue

        _run_event(event_resource)
        return true

    return false


func is_running() -> bool:
    return _is_running


func _try_run_next_available_event() -> void:
    var event := _get_next_available_event()

    if event == null:
        return

    _run_event(event)


func _get_next_available_event() -> Resource:
    for event_resource in movement_events:
        if event_resource == null:
            continue

        if not event_resource.has_method("can_run"):
            if debug_prints:
                push_warning("Movement event resource is missing can_run(): " + str(event_resource))
            continue

        if bool(event_resource.call("can_run")):
            return event_resource

    return null


func _run_event(event: Resource) -> void:
    if event == null:
        return

    if npc_actor == null:
        push_warning("NPCMovementModule cannot run event. npc_actor is null.")
        return

    if _is_running:
        return

    _is_running = true

    var event_id := str(event.get("event_id")).strip_edges()
    var movement_action: int = int(event.get("movement_action"))
    var disable_interaction_during_event: bool = bool(event.get("disable_interaction_during_event"))
    var enable_interaction_after_event: bool = bool(event.get("enable_interaction_after_event"))
    var fade_out_duration: float = float(event.get("fade_out_duration"))
    var fade_in_duration: float = float(event.get("fade_in_duration"))
    var hide_after_fade_out: bool = bool(event.get("hide_after_fade_out"))
    var hide_while_moving: bool = bool(event.get("hide_while_moving"))

    if disable_interaction_during_event and npc_actor.has_method("set_interaction_enabled"):
        npc_actor.set_interaction_enabled(false)

    if debug_prints:
        print("NPCMovementModule running event: ", event_id)

    match movement_action:
        ACTION_FADE_OUT_ONLY:
            await _fade_actor_to(0.0, fade_out_duration)

            if hide_after_fade_out:
                npc_actor.visible = false

        ACTION_FADE_IN_ONLY:
            npc_actor.visible = true
            await _fade_actor_to(1.0, fade_in_duration)

        ACTION_FADE_OUT_MOVE_FADE_IN:
            await _fade_actor_to(0.0, fade_out_duration)

            if hide_while_moving:
                npc_actor.visible = false

            _move_actor_to_event_target_instant(event)

            npc_actor.visible = true
            await _fade_actor_to(1.0, fade_in_duration)

        ACTION_MOVE_ONLY:
            await _move_actor_to_event_target(event)

        ACTION_MOVE_THEN_FADE_OUT:
            await _move_actor_to_event_target(event)
            await _fade_actor_to(0.0, fade_out_duration)

            if hide_after_fade_out:
                npc_actor.visible = false

        _:
            push_warning("NPCMovementModule unknown movement action for event: " + event_id)

    if event.has_method("mark_complete"):
        event.call("mark_complete")

    if enable_interaction_after_event and npc_actor != null and npc_actor.has_method("set_interaction_enabled"):
        npc_actor.set_interaction_enabled(true)

    _is_running = false

    if debug_prints:
        print("NPCMovementModule finished event: ", event_id)


func _run_fallback_event() -> void:
    if npc_actor == null:
        push_warning("NPCMovementModule cannot run fallback event. npc_actor is null.")
        return

    if _is_running:
        return

    _is_running = true

    if npc_actor.has_method("set_interaction_enabled"):
        npc_actor.set_interaction_enabled(false)

    if debug_prints:
        print("NPCMovementModule running fallback movement event.")

    await _fade_actor_to(0.0, fallback_fade_out_duration)

    var target_node := _resolve_node_path(fallback_target_marker_path)

    if target_node != null and target_node is Node2D:
        var target_2d := target_node as Node2D
        npc_actor.global_position = target_2d.global_position
    elif debug_prints:
        print("NPCMovementModule fallback has no valid target marker. Fade only.")

    npc_actor.visible = true
    await _fade_actor_to(1.0, fallback_fade_in_duration)

    if npc_actor.has_method("set_interaction_enabled"):
        npc_actor.set_interaction_enabled(true)

    _is_running = false


func _move_actor_to_event_target_instant(event: Resource) -> void:
    var target_position = _get_event_target_position(event)

    if target_position == null:
        if debug_prints:
            print("NPCMovementModule instant move skipped. No target for event: ", str(event.get("event_id")))
        return

    npc_actor.global_position = target_position


func _move_actor_to_event_target(event: Resource) -> void:
    var target_position = _get_event_target_position(event)

    if target_position == null:
        if debug_prints:
            print("NPCMovementModule move skipped. No target for event: ", str(event.get("event_id")))
        return

    var movement_speed: float = float(event.get("movement_speed"))
    var speed: float = maxf(1.0, movement_speed)

    while npc_actor != null and npc_actor.global_position.distance_to(target_position) > 1.0:
        var delta := get_process_delta_time()
        var move_amount := speed * delta

        npc_actor.global_position = npc_actor.global_position.move_toward(target_position, move_amount)

        await get_tree().process_frame

    if npc_actor != null:
        npc_actor.global_position = target_position


func _get_event_target_position(event: Resource):
    if event == null:
        return null

    var use_target_marker: bool = bool(event.get("use_target_marker"))

    if not use_target_marker:
        return null

    var target_marker_path: NodePath = event.get("target_marker_path")
    var target_node := _resolve_node_path(target_marker_path)

    if target_node == null:
        if debug_prints:
            push_warning("NPCMovementModule could not find target marker for event: " + str(event.get("event_id")))
        return null

    if not target_node is Node2D:
        if debug_prints:
            push_warning("NPCMovementModule target marker is not Node2D for event: " + str(event.get("event_id")))
        return null

    var target_2d := target_node as Node2D
    return target_2d.global_position


func _resolve_node_path(node_path: NodePath) -> Node:
    if node_path == NodePath(""):
        return null

    var found_node := get_node_or_null(node_path)

    if found_node != null:
        return found_node

    if npc_actor != null:
        found_node = npc_actor.get_node_or_null(node_path)

        if found_node != null:
            return found_node

    var current_scene := get_tree().current_scene

    if current_scene != null:
        found_node = current_scene.get_node_or_null(node_path)

        if found_node != null:
            return found_node

    return null


func _fade_actor_to(target_alpha: float, duration: float) -> void:
    if npc_actor == null:
        return

    var safe_duration := maxf(0.01, duration)

    var tween := create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(npc_actor, "modulate:a", target_alpha, safe_duration)

    await tween.finished

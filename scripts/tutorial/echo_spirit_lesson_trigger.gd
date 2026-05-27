extends Area2D
class_name EchoSpiritLessonTrigger

@export_group("Lesson Identity")
@export var lesson_id: String = ""
@export var trigger_once: bool = true

@export_group("Guide / Marker")
@export var echo_spirit_guide_path: NodePath = NodePath("")
@export var lesson_marker_id: String = ""

@export_group("Requirements")
@export var required_flag: String = ""
@export var blocked_if_flag_set: String = ""

@export_group("Persistence")
@export var persistent_id: String = ""
@export var save_triggered_state: bool = true
@export var remove_if_already_triggered: bool = true
@export var disable_after_trigger: bool = true

@export_group("Dialogue")
@export var speaker_name: String = "Echo Spirit"
@export_multiline var dialogue_text: String = ""

@export_group("Quest Start")
@export var quest_entry: QuestEntry = null

@export_group("Quest Progress")
@export var quest_id: String = ""
@export var objective_id: String = ""
@export var progress_amount: int = 0

@export_group("Flags Set After Lesson")
@export var flags_to_set: Array[String] = []

@export_group("Debug")
@export var debug_prints: bool = true

var _has_triggered: bool = false


func _ready() -> void:
    if persistent_id.strip_edges() == "":
        persistent_id = name

    if save_triggered_state and SaveManager.is_collectable_collected(persistent_id):
        _has_triggered = true

        if debug_prints:
            print("EchoSpiritLessonTrigger already triggered from save: ", persistent_id)

        if remove_if_already_triggered:
            queue_free()
            return

        if disable_after_trigger:
            _disable_area()

    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
    if _has_triggered and trigger_once:
        return

    if body == null:
        return

    if not body.is_in_group("player"):
        return

    if required_flag.strip_edges() != "":
        if not SaveManager.is_flag_set(required_flag):
            if debug_prints:
                print("EchoSpiritLessonTrigger blocked by missing required flag: ", required_flag)
            return

    if blocked_if_flag_set.strip_edges() != "":
        if SaveManager.is_flag_set(blocked_if_flag_set):
            if debug_prints:
                print("EchoSpiritLessonTrigger blocked because flag is already set: ", blocked_if_flag_set)
            return

    var guide := _get_echo_spirit_guide()

    if guide == null:
        push_warning("EchoSpiritLessonTrigger could not find EchoSpiritGuide.")
        return

    if guide.has_method("is_playing_lesson") and guide.is_playing_lesson():
        if debug_prints:
            print("EchoSpiritLessonTrigger ignored because guide is already playing a lesson.")
        return

    var marker_position := global_position

    if lesson_marker_id.strip_edges() != "":
        var marker := _find_lesson_marker(get_tree().current_scene, lesson_marker_id)

        if marker != null:
            marker_position = marker.global_position
        elif debug_prints:
            push_warning("EchoSpiritLessonTrigger could not find marker_id: " + lesson_marker_id)

    var lesson_data := {
        "lesson_id": lesson_id,
        "marker_position": marker_position,
        "speaker_name": speaker_name,
        "dialogue_lines": _split_dialogue_lines(dialogue_text),
        "quest_entry": quest_entry,
        "quest_id": quest_id,
        "objective_id": objective_id,
        "progress_amount": progress_amount,
        "flags_to_set": flags_to_set
    }

    _has_triggered = true

    if save_triggered_state:
        SaveManager.mark_collectable_collected(persistent_id)

    if disable_after_trigger:
        _disable_area()

    if debug_prints:
        print("EchoSpiritLessonTrigger playing lesson: ", lesson_id)

    guide.play_lesson(lesson_data)


func _get_echo_spirit_guide() -> EchoSpiritGuide:
    if echo_spirit_guide_path != NodePath(""):
        var guide_from_path := get_node_or_null(echo_spirit_guide_path) as EchoSpiritGuide

        if guide_from_path != null:
            return guide_from_path

    var current_scene := get_tree().current_scene

    if current_scene == null:
        return null

    return _find_echo_spirit_guide(current_scene)


func _find_echo_spirit_guide(node: Node) -> EchoSpiritGuide:
    if node == null:
        return null

    if node is EchoSpiritGuide:
        return node as EchoSpiritGuide

    for child in node.get_children():
        var found := _find_echo_spirit_guide(child)

        if found != null:
            return found

    return null


func _find_lesson_marker(node: Node, marker_id: String) -> EchoSpiritLessonMarker:
    if node == null:
        return null

    if node is EchoSpiritLessonMarker:
        var marker := node as EchoSpiritLessonMarker

        if marker.marker_id == marker_id:
            return marker

    for child in node.get_children():
        var found := _find_lesson_marker(child, marker_id)

        if found != null:
            return found

    return null


func _split_dialogue_lines(raw_dialogue: String) -> Array[String]:
    var lines: Array[String] = []
    var split_lines := raw_dialogue.split("\n", false)

    for line in split_lines:
        var clean_line := str(line).strip_edges()

        if clean_line == "":
            continue

        lines.append(clean_line)

    return lines


func _disable_area() -> void:
    monitoring = false
    set_deferred("monitorable", false)
    visible = false

    for child in get_children():
        if child is CollisionShape2D:
            child.set_deferred("disabled", true)

        if child is CollisionPolygon2D:
            child.set_deferred("disabled", true)

        if child is CanvasItem:
            child.visible = false

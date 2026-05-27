extends Node2D
class_name EchoSpiritGuide

@export_group("Identity")
@export var spirit_name: String = "Echo Spirit"

@export_group("Visuals")
@export var visual_node_path: NodePath = NodePath("AnimatedSprite2D")
@export var fade_in_duration: float = 0.35
@export var fade_out_duration: float = 0.35
@export var hide_after_lesson: bool = true

@export_group("Debug")
@export var debug_prints: bool = true

var _visual_node: CanvasItem = null
var _is_playing_lesson: bool = false


func _ready() -> void:
    _visual_node = get_node_or_null(visual_node_path) as CanvasItem

    if _visual_node == null:
        _visual_node = _find_first_canvas_item_child()

    visible = false
    modulate.a = 0.0


func play_lesson(lesson_data: Dictionary) -> bool:
    if _is_playing_lesson:
        if debug_prints:
            print("EchoSpiritGuide ignored lesson because another lesson is playing.")
        return false

    if lesson_data.is_empty():
        return false

    _is_playing_lesson = true

    var marker_position: Vector2 = lesson_data.get("marker_position", global_position)
    global_position = marker_position

    visible = true
    await _fade_to(1.0, fade_in_duration)

    _start_configured_quest(lesson_data)
    _show_configured_dialogue(lesson_data)

    await _wait_for_dialogue_to_close()

    _add_configured_quest_progress(lesson_data)
    _set_configured_flags(lesson_data)

    if hide_after_lesson:
        await _fade_to(0.0, fade_out_duration)
        visible = false

    _is_playing_lesson = false

    if debug_prints:
        print("EchoSpiritGuide finished lesson: ", str(lesson_data.get("lesson_id", "")))

    return true


func is_playing_lesson() -> bool:
    return _is_playing_lesson


func _start_configured_quest(lesson_data: Dictionary) -> void:
    var quest_entry: QuestEntry = lesson_data.get("quest_entry", null)

    if quest_entry == null:
        return

    var started := QuestManager.start_quest(quest_entry)

    if debug_prints:
        print("EchoSpiritGuide start quest result: ", started, " quest: ", quest_entry.quest_id)


func _show_configured_dialogue(lesson_data: Dictionary) -> void:
    var dialogue_lines: Array[String] = []
    var raw_lines: Array = lesson_data.get("dialogue_lines", [])

    for line in raw_lines:
        var clean_line := str(line).strip_edges()

        if clean_line == "":
            continue

        dialogue_lines.append(clean_line)

    if dialogue_lines.is_empty():
        return

    var speaker_name: String = str(lesson_data.get("speaker_name", spirit_name)).strip_edges()

    if speaker_name == "":
        speaker_name = spirit_name

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_story_dialogue"):
        game_ui.show_story_dialogue(dialogue_lines, speaker_name)
        return

    if debug_prints:
        print("EchoSpiritGuide could not find GameUi for dialogue.")


func _add_configured_quest_progress(lesson_data: Dictionary) -> void:
    var quest_id: String = str(lesson_data.get("quest_id", "")).strip_edges()
    var objective_id: String = str(lesson_data.get("objective_id", "")).strip_edges()
    var progress_amount: int = int(lesson_data.get("progress_amount", 0))

    if quest_id == "":
        return

    if objective_id == "":
        return

    if progress_amount <= 0:
        return

    if not QuestManager.is_quest_active(quest_id):
        if debug_prints:
            print("EchoSpiritGuide quest progress skipped. Quest is not active: ", quest_id)
        return

    var progress_added := QuestManager.add_objective_progress(
        quest_id,
        objective_id,
        progress_amount
    )

    if debug_prints:
        print("EchoSpiritGuide quest progress result: ", progress_added, " quest: ", quest_id, " objective: ", objective_id)


func _set_configured_flags(lesson_data: Dictionary) -> void:
    var flags_to_set: Array = lesson_data.get("flags_to_set", [])

    for flag_value in flags_to_set:
        var clean_flag := str(flag_value).strip_edges()

        if clean_flag == "":
            continue

        SaveManager.set_flag(clean_flag, true)

        if debug_prints:
            print("EchoSpiritGuide set flag: ", clean_flag)


func _wait_for_dialogue_to_close() -> void:
    var game_ui := _get_game_ui()

    if game_ui == null:
        return

    if not game_ui.has_method("is_story_dialogue_active"):
        return

    while game_ui.is_story_dialogue_active():
        await get_tree().process_frame


func _fade_to(target_alpha: float, duration: float) -> void:
    var safe_duration := maxf(0.01, duration)

    var tween := create_tween()
    tween.tween_property(self, "modulate:a", target_alpha, safe_duration)

    await tween.finished


func _get_game_ui() -> Node:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("show_story_dialogue"):
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null and autoload_ui.has_method("show_story_dialogue"):
        return autoload_ui

    return null


func _find_first_canvas_item_child() -> CanvasItem:
    for child in get_children():
        if child is CanvasItem:
            return child as CanvasItem

    return null

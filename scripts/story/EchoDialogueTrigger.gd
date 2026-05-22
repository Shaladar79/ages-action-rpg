extends Area2D
class_name EchoDialogueTrigger

@export var trigger_id: String = ""
@export var story_flag: String = ""

@export var speaker_name: String = "Echo Spirit"

@export_multiline var dialogue_text: String = ""

@export var trigger_once: bool = true
@export var auto_trigger_on_body_entered: bool = true
@export var requires_interact: bool = false

@export var required_flag: String = ""
@export var blocked_if_flag_set: String = ""

@export var mark_flag_when_started: bool = true

@export var debug_prints: bool = true

var player_in_range: Node = null
var has_triggered_this_session: bool = false


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

    if trigger_id.strip_edges() == "":
        trigger_id = name

    if story_flag.strip_edges() == "":
        story_flag = trigger_id

    if debug_prints:
        print("EchoDialogueTrigger ready: ", name)
        print("Trigger ID: ", trigger_id)
        print("Story Flag: ", story_flag)


func _process(_delta: float) -> void:
    if not requires_interact:
        return

    if player_in_range == null:
        return

    if Input.is_action_just_pressed("interact"):
        try_trigger_dialogue(player_in_range)


func try_trigger_dialogue(player: Node) -> bool:
    if debug_prints:
        print("Trying Echo dialogue trigger: ", name)

    if player == null:
        if debug_prints:
            print("Echo trigger failed: player is null.")
        return false

    if not _is_player(player):
        if debug_prints:
            print("Echo trigger failed: body is not player.")
        return false

    if not _can_trigger():
        if debug_prints:
            print("Echo trigger failed: _can_trigger returned false.")
            print("Story flag: ", story_flag, " value: ", SaveManager.is_flag_set(story_flag))
            print("Required flag: ", required_flag)
            print("Blocked if flag set: ", blocked_if_flag_set)
        return false

    var lines := _get_dialogue_lines()

    if debug_prints:
        print("Echo dialogue line count: ", lines.size())

    if lines.is_empty():
        push_warning("EchoDialogueTrigger has no dialogue text: " + name)
        return false

    var game_ui := _get_game_ui()

    if debug_prints:
        print("Game UI found: ", game_ui)

    if game_ui == null:
        push_warning("Could not find GameUi for EchoDialogueTrigger: " + name)
        return false

    if debug_prints:
        print("Game UI has show_story_dialogue: ", game_ui.has_method("show_story_dialogue"))

    if not game_ui.has_method("show_story_dialogue"):
        push_warning("GameUi is missing show_story_dialogue().")
        return false

    if mark_flag_when_started:
        _mark_story_flag()

    has_triggered_this_session = true

    if debug_prints:
        print("Showing Echo dialogue now.")

    game_ui.show_story_dialogue(lines, speaker_name)

    if debug_prints:
        print("Echo dialogue call finished.")

    return true


func _can_trigger() -> bool:
    if trigger_once and has_triggered_this_session:
        return false

    if story_flag.strip_edges() != "":
        if SaveManager.is_flag_set(story_flag):
            return false

    if required_flag.strip_edges() != "":
        if not SaveManager.is_flag_set(required_flag):
            return false

    if blocked_if_flag_set.strip_edges() != "":
        if SaveManager.is_flag_set(blocked_if_flag_set):
            return false

    return true


func _mark_story_flag() -> void:
    if story_flag.strip_edges() == "":
        return

    SaveManager.set_flag(story_flag, true)


func _get_dialogue_lines() -> Array[String]:
    var lines: Array[String] = []

    var split_lines := dialogue_text.split("\n", false)

    for raw_line in split_lines:
        var clean_line := str(raw_line).strip_edges()

        if clean_line == "":
            continue

        lines.append(clean_line)

    return lines


func _get_game_ui() -> Node:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("show_story_dialogue"):
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null and autoload_ui.has_method("show_story_dialogue"):
        return autoload_ui

    for ui_node in group_nodes:
        print("Found interaction_ui node without story dialogue method: ", ui_node.name, " script: ", ui_node.get_script())

    return null


func _is_player(body: Node) -> bool:
    if body == null:
        return false

    return body.is_in_group("player")


func _on_body_entered(body: Node) -> void:
    if debug_prints:
        print("Echo trigger body entered: ", body.name)
        print("Body groups: ", body.get_groups())

    if not _is_player(body):
        if debug_prints:
            print("Body is not player.")
        return

    if debug_prints:
        print("Player entered Echo trigger.")

    player_in_range = body

    if auto_trigger_on_body_entered and not requires_interact:
        try_trigger_dialogue(body)


func _on_body_exited(body: Node) -> void:
    if body != player_in_range:
        return

    player_in_range = null

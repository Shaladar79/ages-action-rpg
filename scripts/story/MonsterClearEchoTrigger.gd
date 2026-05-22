extends Area2D
class_name MonsterClearEchoTrigger

@export var trigger_id: String = ""
@export var story_flag: String = "pre_boss_monsters_defeated"

@export var speaker_name: String = "Echo Spirit"

@export var required_defeated_monster_ids: Array[String] = []

@export_multiline var dialogue_text: String = ""

@export var trigger_once: bool = true
@export var auto_trigger_on_body_entered: bool = true
@export var requires_interact: bool = false
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
        print("MonsterClearEchoTrigger ready: ", name)
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
        print("Trying monster-clear Echo trigger: ", name)

    if player == null:
        return false

    if not _is_player(player):
        return false

    if not _can_trigger():
        return false

    var lines := _get_dialogue_lines()

    if lines.is_empty():
        push_warning("MonsterClearEchoTrigger has no dialogue text: " + name)
        return false

    var game_ui := _get_game_ui()

    if game_ui == null:
        push_warning("Could not find GameUi for MonsterClearEchoTrigger: " + name)
        return false

    if not game_ui.has_method("show_story_dialogue"):
        push_warning("GameUi is missing show_story_dialogue().")
        return false

    if mark_flag_when_started:
        SaveManager.set_flag(story_flag, true)

    has_triggered_this_session = true

    game_ui.show_story_dialogue(lines, speaker_name)

    return true


func _can_trigger() -> bool:
    if trigger_once and has_triggered_this_session:
        return false

    if story_flag.strip_edges() != "":
        if SaveManager.is_flag_set(story_flag):
            return false

    if not _are_required_monsters_defeated():
        if debug_prints:
            print("Monster-clear Echo trigger blocked. Required monsters are not all defeated.")
        return false

    return true


func _are_required_monsters_defeated() -> bool:
    if required_defeated_monster_ids.is_empty():
        if debug_prints:
            print("MonsterClearEchoTrigger has no required defeated monster IDs.")
        return false

    for monster_id in required_defeated_monster_ids:
        var clean_id := monster_id.strip_edges()

        if clean_id == "":
            continue

        if not SaveManager.is_monster_defeated(clean_id):
            if debug_prints:
                print("Required monster not defeated yet: ", clean_id)
            return false

    return true


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

    return null


func _is_player(body: Node) -> bool:
    if body == null:
        return false

    return body.is_in_group("player")


func _on_body_entered(body: Node) -> void:
    if not _is_player(body):
        return

    player_in_range = body

    if auto_trigger_on_body_entered and not requires_interact:
        try_trigger_dialogue(body)


func _on_body_exited(body: Node) -> void:
    if body != player_in_range:
        return

    player_in_range = null

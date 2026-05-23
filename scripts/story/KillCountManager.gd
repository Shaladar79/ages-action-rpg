extends Node
class_name KillCountManager

@export var required_kills: int = 20
@export var unlocked_flag: String = "kill_count_unlocked"

@export var target_node_path: NodePath

@export var count_only_monsters_in_group: bool = false
@export var eligible_monster_group: String = "kill_count_monster"

@export var show_echo_when_unlocked: bool = true
@export var speaker_name: String = "Echo Spirit"

@export_multiline var unlocked_dialogue_text: String = "Something stirs nearby.\nA stronger presence has revealed itself."

@export var debug_prints: bool = true

var current_kills: int = 0
var target_node: Node = null
var has_unlocked_this_session: bool = false


func _ready() -> void:
    required_kills = maxi(1, required_kills)
    target_node = get_node_or_null(target_node_path)

    if debug_prints:
        print("KillCountManager ready.")
        print("Required kills: ", required_kills)
        print("Target node found: ", target_node)

    if SaveManager.is_flag_set(unlocked_flag):
        has_unlocked_this_session = true
        _activate_target_node()
    else:
        _deactivate_target_node()

    _connect_existing_monsters(get_tree().current_scene)


func _connect_existing_monsters(node: Node) -> void:
    if node == null:
        return

    if node is Monster:
        _try_connect_monster(node as Monster)

    for child in node.get_children():
        _connect_existing_monsters(child)


func _try_connect_monster(monster: Monster) -> void:
    if monster == null:
        return

    if monster == target_node:
        return

    if count_only_monsters_in_group:
        if not monster.is_in_group(eligible_monster_group):
            return

    if not monster.monster_defeated.is_connected(_on_monster_defeated):
        monster.monster_defeated.connect(_on_monster_defeated)

        if debug_prints:
            print("Connected KillCountManager to monster: ", monster.name)


func _on_monster_defeated(monster: Monster, player: Node2D) -> void:
    if has_unlocked_this_session:
        return

    if SaveManager.is_flag_set(unlocked_flag):
        has_unlocked_this_session = true
        return

    current_kills += 1

    if debug_prints:
        print("Kill count: ", current_kills, " / ", required_kills)

    if current_kills < required_kills:
        return

    _unlock_target(player)


func _unlock_target(player: Node2D) -> void:
    if has_unlocked_this_session:
        return

    has_unlocked_this_session = true
    SaveManager.set_flag(unlocked_flag, true)

    _activate_target_node()

    if show_echo_when_unlocked:
        _show_unlock_dialogue()


func _activate_target_node() -> void:
    if target_node == null:
        push_warning("KillCountManager cannot activate target. target_node_path is not set or invalid.")
        return

    _set_node_active(target_node, true)

    if debug_prints:
        print("KillCountManager activated target node: ", target_node.name)


func _deactivate_target_node() -> void:
    if target_node == null:
        return

    _set_node_active(target_node, false)

    if debug_prints:
        print("KillCountManager hid/deactivated target node: ", target_node.name)


func _set_node_active(node: Node, active: bool) -> void:
    if node == null:
        return

    if node is CanvasItem:
        var canvas_item := node as CanvasItem
        canvas_item.visible = active

    if active:
        node.process_mode = Node.PROCESS_MODE_INHERIT
    else:
        node.process_mode = Node.PROCESS_MODE_DISABLED

    _set_collision_enabled(node, active)


func _set_collision_enabled(node: Node, enabled: bool) -> void:
    for child in node.get_children():
        if child is CollisionShape2D:
            child.set_deferred("disabled", not enabled)

        if child is CollisionPolygon2D:
            child.set_deferred("disabled", not enabled)

        if child is Area2D:
            child.set_deferred("monitoring", enabled)
            child.set_deferred("monitorable", enabled)

        if child is PhysicsBody2D:
            if enabled:
                child.set_deferred("collision_layer", 1)
                child.set_deferred("collision_mask", 1)
            else:
                child.set_deferred("collision_layer", 0)
                child.set_deferred("collision_mask", 0)

        _set_collision_enabled(child, enabled)


func _show_unlock_dialogue() -> void:
    print("KillCountManager trying to show unlock dialogue.")

    var lines := _get_dialogue_lines()

    print("KillCountManager unlock dialogue line count: ", lines.size())

    if lines.is_empty():
        print("KillCountManager unlock dialogue failed: no lines.")
        return

    var game_ui := _get_game_ui()

    print("KillCountManager GameUi found: ", game_ui)

    if game_ui != null and game_ui.has_method("show_story_dialogue"):
        print("KillCountManager showing unlock dialogue now.")
        game_ui.show_story_dialogue(lines, speaker_name)
        return

    print("KillCountManager failed: no valid GameUi with show_story_dialogue found.")


func _get_dialogue_lines() -> Array[String]:
    var lines: Array[String] = []
    var split_lines := unlocked_dialogue_text.split("\n", false)

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

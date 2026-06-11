extends StaticBody2D
class_name QuestBlocker

@export_group("Quest / Flag Requirement")
@export var blocker_id: String = ""

@export var required_flag: String = ""
@export var required_quest_id: String = ""

@export_enum("none", "active", "ready_to_turn_in", "completed")
var required_quest_state: String = "none"

@export_group("Blocked Message")
@export var blocked_message: String = "Something prevents you from going this way."
@export var speaker_name: String = "Echo Spirit"
@export var show_message_on_touch: bool = true

@export_group("Collision Nodes")
@export var message_area_path: NodePath = NodePath("MessageArea")
@export var solid_collision_path: NodePath = NodePath("")

@export_group("Behavior")
@export var check_every_frame: bool = true
@export var visible_when_blocked: bool = true
@export var visible_when_unblocked: bool = false
@export var disable_message_area_when_unblocked: bool = true

@export_group("Debug")
@export var debug_prints: bool = true

@onready var message_area: Area2D = get_node_or_null(message_area_path) as Area2D

var player_in_message_area: Node = null
var is_unblocked: bool = false

var _blocked_collision_layer: int = 0
var _blocked_collision_mask: int = 0
var _message_area_collision_layer: int = 0
var _message_area_collision_mask: int = 0


func _ready() -> void:
    _blocked_collision_layer = collision_layer
    _blocked_collision_mask = collision_mask

    if message_area != null:
        _message_area_collision_layer = message_area.collision_layer
        _message_area_collision_mask = message_area.collision_mask

    if debug_prints:
        print("QuestBlocker ready: ", name)
        print("Blocker id: ", blocker_id)
        print("Required flag: ", required_flag)
        print("Required quest id: ", required_quest_id)
        print("Required quest state: ", required_quest_state)
        print("MessageArea found: ", message_area)

    _connect_message_area()
    _update_blocker_state(true)


func _process(_delta: float) -> void:
    if not check_every_frame:
        return

    _update_blocker_state(false)


func force_refresh_blocker() -> void:
    _update_blocker_state(true)


func _connect_message_area() -> void:
    if message_area == null:
        push_warning("QuestBlocker is missing MessageArea: " + str(message_area_path))
        return

    if not message_area.body_entered.is_connected(_on_message_area_body_entered):
        message_area.body_entered.connect(_on_message_area_body_entered)

    if not message_area.body_exited.is_connected(_on_message_area_body_exited):
        message_area.body_exited.connect(_on_message_area_body_exited)


func _update_blocker_state(force_update: bool = false) -> void:
    var should_be_unblocked := _is_requirement_met()

    if debug_prints and force_update:
        print("QuestBlocker force check: ", name)
        print("Requirement met: ", should_be_unblocked)

    if should_be_unblocked == is_unblocked and not force_update:
        return

    is_unblocked = should_be_unblocked

    if is_unblocked:
        _unblock()
    else:
        _block()


func _is_requirement_met() -> bool:
    var clean_flag := required_flag.strip_edges()
    var clean_quest_id := required_quest_id.strip_edges()
    var clean_quest_state := required_quest_state.strip_edges()

    var has_any_requirement := false

    if clean_flag != "":
        has_any_requirement = true

        if not SaveManager.is_flag_set(clean_flag):
            return false

    if clean_quest_id != "":
        has_any_requirement = true

        match clean_quest_state:
            "active":
                if not QuestManager.is_quest_active(clean_quest_id):
                    return false

            "ready_to_turn_in":
                if not QuestManager.is_quest_ready_to_turn_in(clean_quest_id):
                    return false

            "completed":
                if not QuestManager.is_quest_completed(clean_quest_id):
                    return false

            "none":
                if not QuestManager.is_quest_active(clean_quest_id) and not QuestManager.is_quest_completed(clean_quest_id):
                    return false

            _:
                if not QuestManager.is_quest_active(clean_quest_id) and not QuestManager.is_quest_completed(clean_quest_id):
                    return false

    if not has_any_requirement:
        return false

    return true


func _block() -> void:
    visible = visible_when_blocked

    set_deferred("collision_layer", _blocked_collision_layer)
    set_deferred("collision_mask", _blocked_collision_mask)
    _set_solid_collision_disabled(false)

    _set_message_area_enabled(true)

    if debug_prints:
        print("QuestBlocker blocked: ", name)


func _unblock() -> void:
    visible = visible_when_unblocked

    set_deferred("collision_layer", 0)
    set_deferred("collision_mask", 0)
    _set_solid_collision_disabled(true)

    if disable_message_area_when_unblocked:
        _set_message_area_enabled(false)
    else:
        _set_message_area_enabled(true)

    if debug_prints:
        print("QuestBlocker unblocked: ", name)


func _set_solid_collision_disabled(disabled: bool) -> void:
    if solid_collision_path != NodePath(""):
        var solid_collision := get_node_or_null(solid_collision_path)

        if solid_collision is CollisionShape2D:
            solid_collision.set_deferred("disabled", disabled)
            return

        if solid_collision is CollisionPolygon2D:
            solid_collision.set_deferred("disabled", disabled)
            return

    _set_collision_shapes_disabled(self, disabled)


func _set_collision_shapes_disabled(node: Node, disabled: bool) -> void:
    for child in node.get_children():
        if child == message_area:
            continue

        if child is CollisionShape2D:
            child.set_deferred("disabled", disabled)

        if child is CollisionPolygon2D:
            child.set_deferred("disabled", disabled)

        _set_collision_shapes_disabled(child, disabled)


func _set_message_area_enabled(enabled: bool) -> void:
    if message_area == null:
        return

    message_area.set_deferred("monitoring", enabled)
    message_area.set_deferred("monitorable", enabled)

    if enabled:
        message_area.set_deferred("collision_layer", _message_area_collision_layer)
        message_area.set_deferred("collision_mask", _message_area_collision_mask)
    else:
        message_area.set_deferred("collision_layer", 0)
        message_area.set_deferred("collision_mask", 0)


func _show_blocked_message() -> void:
    if not show_message_on_touch:
        return

    if is_unblocked:
        return

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_story_message"):
        game_ui.show_story_message(blocked_message, speaker_name)
        return

    if player_in_message_area != null and player_in_message_area.has_method("show_dialogue"):
        player_in_message_area.show_dialogue(blocked_message, speaker_name)


func _get_game_ui() -> Node:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("show_story_message"):
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null and autoload_ui.has_method("show_story_message"):
        return autoload_ui

    return null


func _is_player(body: Node) -> bool:
    if body == null:
        return false

    return body.is_in_group("player")


func _on_message_area_body_entered(body: Node) -> void:
    if debug_prints:
        print("QuestBlocker MessageArea body entered: ", body.name, " groups: ", body.get_groups())

    if not _is_player(body):
        return

    player_in_message_area = body
    _show_blocked_message()


func _on_message_area_body_exited(body: Node) -> void:
    if body != player_in_message_area:
        return

    player_in_message_area = null

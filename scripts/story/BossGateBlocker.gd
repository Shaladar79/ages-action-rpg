extends StaticBody2D
class_name BossGateBlocker

@export_group("Boss Flags")
@export var boss_started_flag: String = ""
@export var boss_defeated_flag: String = "intro_boss_defeated"

# If On, this gate only blocks after Boss Started Flag is set.
# Use this for boss arena exits that should stay open until the player enters the arena.
# If Off, this gate blocks immediately until Boss Defeated Flag is set.
@export var only_block_after_boss_started: bool = true

@export_group("Blocked Message")
@export var blocked_message: String = "A corrupted force seals the way forward. Defeat the guardian to leave."
@export var speaker_name: String = "Echo Spirit"
@export var show_message_on_touch: bool = true

@export_group("Behavior")
@export var check_every_frame: bool = true
@export var visible_when_closed: bool = true
@export var visible_when_open: bool = false

@export_group("Debug")
@export var debug_prints: bool = true

@onready var message_area: Area2D = get_node_or_null("MessageArea") as Area2D

var player_in_message_area: Node = null
var is_open: bool = false

var _closed_collision_layer: int = 0
var _closed_collision_mask: int = 0
var _message_area_collision_layer: int = 0
var _message_area_collision_mask: int = 0


func _ready() -> void:
    _closed_collision_layer = collision_layer
    _closed_collision_mask = collision_mask

    if message_area != null:
        _message_area_collision_layer = message_area.collision_layer
        _message_area_collision_mask = message_area.collision_mask

    if debug_prints:
        print("BossGateBlocker ready: ", name)
        print("Boss started flag: ", boss_started_flag)
        print("Boss defeated flag: ", boss_defeated_flag)
        print("Only block after boss started: ", only_block_after_boss_started)
        print("MessageArea found: ", message_area)

    _connect_message_area()
    _update_gate_state(true)


func _process(_delta: float) -> void:
    if not check_every_frame:
        return

    _update_gate_state(false)


func _connect_message_area() -> void:
    if message_area == null:
        push_warning("BossGateBlocker is missing child Area2D named MessageArea.")
        return

    if not message_area.body_entered.is_connected(_on_message_area_body_entered):
        message_area.body_entered.connect(_on_message_area_body_entered)

    if not message_area.body_exited.is_connected(_on_message_area_body_exited):
        message_area.body_exited.connect(_on_message_area_body_exited)


func _update_gate_state(force_update: bool = false) -> void:
    var should_be_open := _should_gate_be_open()

    if debug_prints and force_update:
        print("BossGateBlocker force check.")
        print("Started flag: ", boss_started_flag, " = ", _is_boss_started())
        print("Defeated flag: ", boss_defeated_flag, " = ", _is_boss_defeated())
        print("Should be open: ", should_be_open)

    if should_be_open == is_open and not force_update:
        return

    is_open = should_be_open

    if is_open:
        _open_gate()
    else:
        _close_gate()


func _should_gate_be_open() -> bool:
    if _is_boss_defeated():
        return true

    if only_block_after_boss_started:
        return not _is_boss_started()

    return false


func _is_boss_started() -> bool:
    var clean_flag := boss_started_flag.strip_edges()

    if clean_flag == "":
        return false

    return SaveManager.is_flag_set(clean_flag)


func _is_boss_defeated() -> bool:
    var clean_flag := boss_defeated_flag.strip_edges()

    if clean_flag == "":
        return false

    return SaveManager.is_flag_set(clean_flag)


func _open_gate() -> void:
    visible = visible_when_open

    set_deferred("collision_layer", 0)
    set_deferred("collision_mask", 0)
    _set_collision_shapes_disabled(self, true)

    _set_message_area_enabled(false)

    if debug_prints:
        print("Boss gate opened: ", name)


func _close_gate() -> void:
    visible = visible_when_closed

    set_deferred("collision_layer", _closed_collision_layer)
    set_deferred("collision_mask", _closed_collision_mask)
    _set_collision_shapes_disabled(self, false)

    _set_message_area_enabled(true)

    if debug_prints:
        print("Boss gate closed: ", name)


func force_refresh_gate() -> void:
    _update_gate_state(true)


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
        if debug_prints:
            print("Boss gate blocked message disabled.")
        return

    if is_open:
        if debug_prints:
            print("Boss gate is open; blocked message skipped.")
        return

    if debug_prints:
        print("Boss gate showing blocked message.")

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_story_message"):
        game_ui.show_story_message(blocked_message, speaker_name)
        return

    if debug_prints:
        print("Boss gate could not find GameUi story message method. Falling back to player dialogue.")

    if player_in_message_area != null and player_in_message_area.has_method("show_dialogue"):
        player_in_message_area.show_dialogue(blocked_message)


func _get_game_ui() -> Node:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("show_story_message"):
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null and autoload_ui.has_method("show_story_message"):
        return autoload_ui

    return null


func _set_collision_shapes_disabled(node: Node, disabled: bool) -> void:
    for child in node.get_children():
        if child == message_area:
            continue

        if child is CollisionShape2D:
            child.set_deferred("disabled", disabled)

        if child is CollisionPolygon2D:
            child.set_deferred("disabled", disabled)

        _set_collision_shapes_disabled(child, disabled)


func _is_player(body: Node) -> bool:
    if body == null:
        return false

    return body.is_in_group("player")


func _on_message_area_body_entered(body: Node) -> void:
    if debug_prints:
        print("Boss gate MessageArea body entered: ", body.name, " groups: ", body.get_groups())

    if not _is_player(body):
        if debug_prints:
            print("Boss gate MessageArea body is not player.")
        return

    player_in_message_area = body
    _show_blocked_message()


func _on_message_area_body_exited(body: Node) -> void:
    if body != player_in_message_area:
        return

    player_in_message_area = null

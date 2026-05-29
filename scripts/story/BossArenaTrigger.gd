extends Area2D
class_name BossArenaTrigger

@export_group("Boss Arena Flags")
@export var boss_started_flag: String = "starter_cavern_boss_fight_started"
@export var boss_defeated_flag: String = "starter_cavern_boss_defeated"

@export_group("Trigger Behavior")
@export var trigger_once: bool = true
@export var disable_after_trigger: bool = true
@export var remove_if_boss_defeated: bool = true

@export_group("Messages")
@export var show_message_on_trigger: bool = true
@export var speaker_name: String = "Echo Spirit"
@export_multiline var trigger_message: String = "The air tightens around you. The boss has claimed this place. Defeat it to leave."

@export_group("Debug")
@export var debug_prints: bool = true

var _has_triggered: bool = false


func _ready() -> void:
    monitoring = true
    monitorable = true

    if SaveManager.is_flag_set(boss_defeated_flag):
        if debug_prints:
            print("BossArenaTrigger found defeated boss flag: ", boss_defeated_flag)

        if remove_if_boss_defeated:
            queue_free()
            return

        _disable_trigger()
        return

    if trigger_once and SaveManager.is_flag_set(boss_started_flag):
        _has_triggered = true

        if debug_prints:
            print("BossArenaTrigger already triggered from saved flag: ", boss_started_flag)

        if disable_after_trigger:
            _disable_trigger()

    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
    if _has_triggered and trigger_once:
        return

    if body == null:
        return

    if not body.is_in_group("player"):
        return

    if SaveManager.is_flag_set(boss_defeated_flag):
        if debug_prints:
            print("BossArenaTrigger ignored because boss is defeated: ", boss_defeated_flag)

        if remove_if_boss_defeated:
            queue_free()
        else:
            _disable_trigger()

        return

    _has_triggered = true

    SaveManager.set_flag(boss_started_flag, true)

    if debug_prints:
        print("Boss arena started flag set: ", boss_started_flag)

    if show_message_on_trigger:
        _show_trigger_message()

    if disable_after_trigger:
        _disable_trigger()


func _show_trigger_message() -> void:
    var clean_message := trigger_message.strip_edges()

    if clean_message == "":
        return

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_story_message"):
        game_ui.show_story_message(clean_message, speaker_name)
        return

    if debug_prints:
        print("BossArenaTrigger could not find story message UI.")


func _get_game_ui() -> Node:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("show_story_message"):
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null and autoload_ui.has_method("show_story_message"):
        return autoload_ui

    return null


func _disable_trigger() -> void:
    monitoring = false
    monitorable = false
    visible = false

    for child in get_children():
        if child is CollisionShape2D:
            child.set_deferred("disabled", true)

        if child is CollisionPolygon2D:
            child.set_deferred("disabled", true)

        if child is CanvasItem:
            child.visible = false

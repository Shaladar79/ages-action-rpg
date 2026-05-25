extends Area2D
class_name QuestTalkTarget

@export_group("NPC Identity")
@export var npc_name: String = "Villager"
@export var interaction_prompt_text: String = "E"

@export_group("Quest Progress")
@export var quest_id: String = ""
@export var objective_id: String = ""
@export var progress_amount: int = 1

@export_group("Behavior")
@export var trigger_once: bool = true
@export var require_active_quest: bool = true
@export var disable_after_trigger: bool = false

@export_group("Dialogue")
@export_multiline var active_quest_dialogue: String = "Thank you for speaking with me."
@export_multiline var quest_not_active_dialogue: String = "I have nothing for you right now."
@export_multiline var already_triggered_dialogue: String = "We have already spoken."

@export_group("Persistence")
@export var persistent_id: String = ""
@export var save_triggered_state: bool = true

@export_group("Debug")
@export var debug_prints: bool = true

var nearby_player: Node = null
var _has_triggered: bool = false


func _ready() -> void:
    if persistent_id.strip_edges() == "":
        persistent_id = name

    if save_triggered_state and SaveManager.is_collectable_collected(persistent_id):
        _has_triggered = true

        if debug_prints:
            print("QuestTalkTarget already triggered from save: ", persistent_id)

        if disable_after_trigger:
            monitoring = false
            set_deferred("monitorable", false)

    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)

    if not body_exited.is_connected(_on_body_exited):
        body_exited.connect(_on_body_exited)


func interact(player: Node) -> void:
    if player == null:
        return

    nearby_player = player

    if _has_triggered and trigger_once:
        _show_dialogue_text(already_triggered_dialogue)
        return

    var clean_quest_id := quest_id.strip_edges()
    var clean_objective_id := objective_id.strip_edges()

    if clean_quest_id == "":
        if debug_prints:
            push_warning("QuestTalkTarget has blank quest_id.")
        _show_dialogue_text(quest_not_active_dialogue)
        return

    if clean_objective_id == "":
        if debug_prints:
            push_warning("QuestTalkTarget has blank objective_id.")
        _show_dialogue_text(quest_not_active_dialogue)
        return

    if progress_amount <= 0:
        if debug_prints:
            push_warning("QuestTalkTarget progress_amount must be greater than 0.")
        _show_dialogue_text(quest_not_active_dialogue)
        return

    if require_active_quest and not QuestManager.is_quest_active(clean_quest_id):
        if debug_prints:
            print("QuestTalkTarget ignored because quest is not active: ", clean_quest_id)
        _show_dialogue_text(quest_not_active_dialogue)
        return

    var progress_added := QuestManager.add_objective_progress(
        clean_quest_id,
        clean_objective_id,
        progress_amount
    )

    if progress_added:
        _has_triggered = true

        if save_triggered_state:
            SaveManager.mark_collectable_collected(persistent_id)

        if debug_prints:
            print("QuestTalkTarget added progress: ", clean_quest_id, " / ", clean_objective_id)

        _show_dialogue_text(active_quest_dialogue)

        if disable_after_trigger:
            monitoring = false
            set_deferred("monitorable", false)

        return

    if debug_prints:
        print("QuestTalkTarget failed to add progress: ", clean_quest_id, " / ", clean_objective_id)

    _show_dialogue_text(already_triggered_dialogue)


func _show_dialogue_text(raw_dialogue: String) -> void:
    var lines := _split_dialogue_lines(raw_dialogue)

    if lines.is_empty():
        return

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_story_dialogue"):
        game_ui.show_story_dialogue(lines, npc_name)
        _hide_interaction_prompt()
        return

    if nearby_player != null and nearby_player.has_method("show_dialogue"):
        nearby_player.show_dialogue(lines[0])


func _split_dialogue_lines(raw_dialogue: String) -> Array[String]:
    var lines: Array[String] = []
    var split_lines := raw_dialogue.split("\n", false)

    for line in split_lines:
        var clean_line := str(line).strip_edges()

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


func _show_interaction_prompt() -> void:
    var game_ui := get_tree().get_first_node_in_group("interaction_ui")

    if game_ui == null:
        return

    if game_ui.has_method("show_prompt"):
        game_ui.show_prompt(interaction_prompt_text)


func _hide_interaction_prompt() -> void:
    var game_ui := get_tree().get_first_node_in_group("interaction_ui")

    if game_ui == null:
        return

    if game_ui.has_method("hide_prompt"):
        game_ui.hide_prompt()


func _on_body_entered(body: Node) -> void:
    if body == null:
        return

    if not body.is_in_group("player"):
        return

    nearby_player = body

    if body.has_method("set_nearby_interactable"):
        body.set_nearby_interactable(self)

    _show_interaction_prompt()

    if debug_prints:
        print("Player entered QuestTalkTarget range: ", npc_name)


func _on_body_exited(body: Node) -> void:
    if body != nearby_player:
        return

    if body.has_method("clear_nearby_interactable"):
        body.clear_nearby_interactable(self)

    nearby_player = null
    _hide_interaction_prompt()

    if debug_prints:
        print("Player left QuestTalkTarget range: ", npc_name)

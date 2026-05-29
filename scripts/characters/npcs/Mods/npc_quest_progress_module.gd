extends NPCBehaviorModule
class_name NPCQuestProgressModule

@export_group("Quest Progress")
@export var quest_id: String = ""
@export var objective_id: String = ""
@export var progress_amount: int = 1

@export_group("Progress Flags")
@export var quest_progress_flag: String = ""
@export var required_flag: String = ""

@export_group("Behavior")
@export var enabled: bool = true
@export var interaction_priority: int = 120
@export var progress_only_once: bool = true
@export var allow_progress_if_quest_ready: bool = false

@export_group("Dialogue")
@export var show_dialogue_after_progress: bool = true
@export var speaker_name_override: String = ""
@export_multiline var progress_dialogue: String = ""

@export_group("Debug")
@export var debug_prints: bool = true

var _progress_recorded: bool = false


func _ready() -> void:
    _load_progress_state()


func can_handle_interact(_player: Node) -> bool:
    if not enabled:
        return false

    if quest_id.strip_edges() == "":
        return false

    if objective_id.strip_edges() == "":
        return false

    if progress_amount <= 0:
        return false

    if progress_only_once and _progress_recorded:
        return false

    var clean_progress_flag := quest_progress_flag.strip_edges()

    if progress_only_once and clean_progress_flag != "" and SaveManager.is_flag_set(clean_progress_flag):
        _progress_recorded = true
        return false

    var clean_required_flag := required_flag.strip_edges()

    if clean_required_flag != "" and not SaveManager.is_flag_set(clean_required_flag):
        return false

    var clean_quest_id := quest_id.strip_edges()

    if not QuestManager.is_quest_active(clean_quest_id):
        return false

    if QuestManager.is_quest_ready_to_turn_in(clean_quest_id) and not allow_progress_if_quest_ready:
        return false

    return true


func handle_interact(player: Node) -> bool:
    if not can_handle_interact(player):
        return false

    var clean_quest_id := quest_id.strip_edges()
    var clean_objective_id := objective_id.strip_edges()

    var progress_added := QuestManager.add_objective_progress(
        clean_quest_id,
        clean_objective_id,
        progress_amount
    )

    if not progress_added:
        if debug_prints:
            print("NPCQuestProgressModule failed to add quest progress: ", clean_quest_id, " / ", clean_objective_id)

        return false

    _progress_recorded = true

    var clean_progress_flag := quest_progress_flag.strip_edges()

    if clean_progress_flag != "":
        SaveManager.set_flag(clean_progress_flag, true)

        if debug_prints:
            print("NPCQuestProgressModule set progress flag: ", clean_progress_flag)

    if debug_prints:
        print("NPCQuestProgressModule added quest progress: ", clean_quest_id, " / ", clean_objective_id)

    if show_dialogue_after_progress:
        _show_progress_dialogue()

    return true


func set_behavior_enabled(new_enabled: bool) -> void:
    enabled = new_enabled


func get_interaction_priority() -> int:
    return interaction_priority


func _load_progress_state() -> void:
    var clean_progress_flag := quest_progress_flag.strip_edges()

    if clean_progress_flag == "":
        return

    _progress_recorded = SaveManager.is_flag_set(clean_progress_flag)

    if debug_prints and _progress_recorded:
        print("NPCQuestProgressModule loaded recorded progress flag: ", clean_progress_flag)


func _show_progress_dialogue() -> void:
    var clean_dialogue := progress_dialogue.strip_edges()

    if clean_dialogue == "":
        return

    var game_ui := _get_game_ui()
    var speaker_name := _get_speaker_name()
    var lines := _split_dialogue_lines(clean_dialogue)

    if game_ui != null and game_ui.has_method("show_story_dialogue"):
        game_ui.show_story_dialogue(lines, speaker_name)

        if npc_actor != null and npc_actor.has_method("_hide_interaction_prompt"):
            npc_actor._hide_interaction_prompt()

        return

    if debug_prints:
        print("NPCQuestProgressModule could not find GameUi for dialogue.")


func _split_dialogue_lines(raw_dialogue: String) -> Array[String]:
    var lines: Array[String] = []
    var split_lines := raw_dialogue.split("\n", false)

    for line in split_lines:
        var clean_line := str(line).strip_edges()

        if clean_line == "":
            continue

        lines.append(clean_line)

    return lines


func _get_speaker_name() -> String:
    var override_name := speaker_name_override.strip_edges()

    if override_name != "":
        return override_name

    if npc_actor != null and "npc_name" in npc_actor:
        return str(npc_actor.get("npc_name"))

    return "NPC"


func _get_game_ui() -> Node:
    if npc_actor != null and npc_actor.has_method("get_game_ui"):
        var actor_ui: Node = npc_actor.get_game_ui()

        if actor_ui != null and actor_ui.has_method("show_story_dialogue"):
            return actor_ui

    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("show_story_dialogue"):
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null and autoload_ui.has_method("show_story_dialogue"):
        return autoload_ui

    return null

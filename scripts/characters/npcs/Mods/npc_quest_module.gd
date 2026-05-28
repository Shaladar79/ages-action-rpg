extends NPCBehaviorModule
class_name NPCQuestModule

@export_group("Quest List")
@export var quests: Array[QuestEntry] = []

@export_group("Fallback Dialogue")
@export_multiline var no_available_quest_dialogue: String = "I have nothing else for you right now."

@export_group("After Quest Start Dialogue")
@export var trigger_movement_after_start_dialogue: bool = false

@export_group("Behavior")
@export var enabled: bool = true
@export var interaction_priority: int = 100

@export_group("Debug")
@export var debug_prints: bool = true


func can_handle_interact(_player: Node) -> bool:
    if not enabled:
        return false

    if not quests.is_empty():
        return true

    return no_available_quest_dialogue.strip_edges() != ""


func handle_interact(player: Node) -> bool:
    if not can_handle_interact(player):
        return false

    if player == null:
        return false

    var quest := _get_current_quest_entry()

    if quest == null:
        _show_dialogue_text(no_available_quest_dialogue)
        return true

    if _is_quest_completed_by_flag(quest):
        _show_dialogue_text(quest.completed_dialogue)
        return true

    if QuestManager.is_quest_ready_to_turn_in(quest.quest_id):
        _complete_quest(quest, player)
        _show_dialogue_text(quest.ready_to_turn_in_dialogue)
        return true

    if QuestManager.is_quest_active(quest.quest_id):
        _show_dialogue_text(quest.active_dialogue)
        return true

    if quest.start_on_interact:
        _start_quest(quest)

    _show_dialogue_text(quest.first_time_dialogue)

    if trigger_movement_after_start_dialogue:
        _trigger_movement_after_dialogue()

    return true


func set_behavior_enabled(new_enabled: bool) -> void:
    enabled = new_enabled


func get_interaction_priority() -> int:
    return interaction_priority


func _get_current_quest_entry() -> QuestEntry:
    for quest in quests:
        if quest == null:
            continue

        if quest.quest_id.strip_edges() == "":
            continue

        if not _quest_is_unlocked(quest):
            continue

        if _is_quest_completed_by_flag(quest):
            continue

        return quest

    for index in range(quests.size() - 1, -1, -1):
        var quest: QuestEntry = quests[index]

        if quest == null:
            continue

        if quest.quest_id.strip_edges() == "":
            continue

        if not _quest_is_unlocked(quest):
            continue

        if _is_quest_completed_by_flag(quest):
            return quest

    return null


func _quest_is_unlocked(quest: QuestEntry) -> bool:
    if quest == null:
        return false

    var required_flag := quest.required_flag.strip_edges()

    if required_flag == "":
        return true

    return SaveManager.is_flag_set(required_flag)


func _is_quest_completed_by_flag(quest: QuestEntry) -> bool:
    if quest == null:
        return false

    var completed_flag := quest.completed_flag.strip_edges()

    if completed_flag == "":
        return false

    return SaveManager.is_flag_set(completed_flag)


func _start_quest(quest: QuestEntry) -> void:
    if quest == null:
        return

    var started := QuestManager.start_quest(quest)

    if debug_prints:
        print("NPCQuestModule start quest result: ", started, " quest: ", quest.quest_id)


func _complete_quest(quest: QuestEntry, player: Node) -> void:
    if quest == null:
        return

    var completed := QuestManager.complete_quest(quest.quest_id, player)

    if debug_prints:
        print("NPCQuestModule complete quest result: ", completed, " quest: ", quest.quest_id)


func _show_dialogue_text(raw_dialogue: String) -> void:
    var lines := _split_dialogue_lines(raw_dialogue)

    if lines.is_empty():
        return

    var game_ui := _get_game_ui()
    var speaker_name := _get_speaker_name()

    if game_ui != null and game_ui.has_method("show_story_dialogue"):
        game_ui.show_story_dialogue(lines, speaker_name)

        if npc_actor != null and npc_actor.has_method("_hide_interaction_prompt"):
            npc_actor._hide_interaction_prompt()

        return

    if debug_prints:
        print("NPCQuestModule could not find GameUi for dialogue.")


func _trigger_movement_after_dialogue() -> void:
    call_deferred("_wait_for_dialogue_then_trigger_movement")


func _wait_for_dialogue_then_trigger_movement() -> void:
    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("is_story_dialogue_active"):
        while game_ui.is_story_dialogue_active():
            await get_tree().process_frame

    _trigger_movement_module()


func _trigger_movement_module() -> void:
    if npc_actor == null:
        if debug_prints:
            print("NPCQuestModule cannot trigger movement. npc_actor is null.")
        return

    for child in npc_actor.get_children():
        if child == null:
            continue

        if child.has_method("start_movement_event"):
            child.start_movement_event()

            if debug_prints:
                print("NPCQuestModule triggered movement module: ", child.name)

            return

    if npc_actor.has_method("start_movement_event"):
        npc_actor.start_movement_event()

        if debug_prints:
            print("NPCQuestModule triggered movement on npc_actor.")

        return

    if debug_prints:
        print("NPCQuestModule could not find movement module with start_movement_event().")


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

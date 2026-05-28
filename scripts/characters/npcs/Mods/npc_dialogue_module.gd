extends NPCBehaviorModule
class_name NPCDialogueModule

@export_group("Base Dialogue")
@export_multiline var base_dialogue_text: String = "Hello."
@export var base_speaker_name_override: String = ""

@export_group("Conditional Dialogue")
@export var dialogue_entries: Array[NPCDialogueEntry] = []

@export_group("Behavior")
@export var enabled: bool = true
@export var interaction_priority: int = 0

@export_group("Debug")
@export var debug_prints: bool = true


func can_handle_interact(_player: Node) -> bool:
    if not enabled:
        return false

    if _get_current_dialogue_text().strip_edges() != "":
        return true

    return false


func handle_interact(player: Node) -> bool:
    if not can_handle_interact(player):
        return false

    var dialogue_entry := _get_current_dialogue_entry()

    if dialogue_entry != null:
        _show_dialogue_text(
            dialogue_entry.dialogue_text,
            _get_speaker_name(dialogue_entry.speaker_name_override)
        )

        _run_after_dialogue_actions_deferred(dialogue_entry)
        return true

    _show_dialogue_text(
        base_dialogue_text,
        _get_speaker_name(base_speaker_name_override)
    )

    return true


func set_behavior_enabled(new_enabled: bool) -> void:
    enabled = new_enabled


func get_interaction_priority() -> int:
    return interaction_priority


func _get_current_dialogue_entry() -> NPCDialogueEntry:
    var matching_entries: Array[NPCDialogueEntry] = []

    for entry in dialogue_entries:
        if entry == null:
            continue

        if not entry.can_use():
            continue

        matching_entries.append(entry)

    if matching_entries.is_empty():
        return null

    matching_entries.sort_custom(_sort_dialogue_entries_by_priority)

    return matching_entries[0]


func _sort_dialogue_entries_by_priority(a: NPCDialogueEntry, b: NPCDialogueEntry) -> bool:
    if a == null:
        return false

    if b == null:
        return true

    return a.priority > b.priority


func _get_current_dialogue_text() -> String:
    var dialogue_entry := _get_current_dialogue_entry()

    if dialogue_entry != null:
        return dialogue_entry.dialogue_text

    return base_dialogue_text


func _show_dialogue_text(raw_dialogue: String, speaker_name: String) -> void:
    var lines := _split_dialogue_lines(raw_dialogue)

    if lines.is_empty():
        return

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_story_dialogue"):
        game_ui.show_story_dialogue(lines, speaker_name)
        return

    if debug_prints:
        print("NPCDialogueModule could not find GameUi for dialogue.")


func _run_after_dialogue_actions_deferred(dialogue_entry: NPCDialogueEntry) -> void:
    if dialogue_entry == null:
        return

    call_deferred("_wait_for_dialogue_then_run_actions", dialogue_entry)


func _wait_for_dialogue_then_run_actions(dialogue_entry: NPCDialogueEntry) -> void:
    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("is_story_dialogue_active"):
        while game_ui.is_story_dialogue_active():
            await get_tree().process_frame

    _run_after_dialogue_actions(dialogue_entry)


func _run_after_dialogue_actions(dialogue_entry: NPCDialogueEntry) -> void:
    if dialogue_entry == null:
        return

    if dialogue_entry.only_once:
        var clean_once_flag := dialogue_entry.once_save_flag.strip_edges()

        if clean_once_flag != "":
            SaveManager.set_flag(clean_once_flag, true)

            if debug_prints:
                print("NPCDialogueModule set once flag: ", clean_once_flag)

    for flag_value in dialogue_entry.flags_to_set_after_dialogue:
        var clean_flag := str(flag_value).strip_edges()

        if clean_flag == "":
            continue

        SaveManager.set_flag(clean_flag, true)

        if debug_prints:
            print("NPCDialogueModule set flag after dialogue: ", clean_flag)

    if dialogue_entry.quest_to_start != null:
        var started := QuestManager.start_quest(dialogue_entry.quest_to_start)

        if debug_prints:
            print("NPCDialogueModule quest start result: ", started, " quest: ", dialogue_entry.quest_to_start.quest_id)

    var progress_quest_id := dialogue_entry.progress_quest_id.strip_edges()
    var progress_objective_id := dialogue_entry.progress_objective_id.strip_edges()
    var progress_amount := dialogue_entry.progress_amount

    if progress_quest_id != "" and progress_objective_id != "" and progress_amount > 0:
        var progress_added := QuestManager.add_objective_progress(
            progress_quest_id,
            progress_objective_id,
            progress_amount
        )

        if debug_prints:
            print(
                "NPCDialogueModule quest progress result: ",
                progress_added,
                " quest: ",
                progress_quest_id,
                " objective: ",
                progress_objective_id
            )

    if dialogue_entry.trigger_npc_movement_after_dialogue:
        _trigger_npc_movement()


func _trigger_npc_movement() -> void:
    if npc_actor == null:
        return

    for child in npc_actor.get_children():
        if child == null:
            continue

        if child.has_method("start_movement_event"):
            child.start_movement_event()

            if debug_prints:
                print("NPCDialogueModule triggered movement module/node: ", child.name)

            return

    if npc_actor.has_method("start_movement_event"):
        npc_actor.start_movement_event()

        if debug_prints:
            print("NPCDialogueModule triggered movement on npc_actor.")

        return

    if debug_prints:
        print("NPCDialogueModule could not find movement node with start_movement_event().")


func _split_dialogue_lines(raw_dialogue: String) -> Array[String]:
    var lines: Array[String] = []
    var split_lines := raw_dialogue.split("\n", false)

    for line in split_lines:
        var clean_line := str(line).strip_edges()

        if clean_line == "":
            continue

        lines.append(clean_line)

    return lines


func _get_speaker_name(speaker_override: String = "") -> String:
    var clean_override := speaker_override.strip_edges()

    if clean_override != "":
        return clean_override

    if npc_actor != null and "npc_name" in npc_actor:
        return str(npc_actor.get("npc_name"))

    return "NPC"


func _get_game_ui() -> Node:
    if npc_actor != null and npc_actor.has_method("get_game_ui"):
        return npc_actor.get_game_ui()

    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("show_story_dialogue"):
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null and autoload_ui.has_method("show_story_dialogue"):
        return autoload_ui

    return null

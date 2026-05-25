extends Area2D
class_name QuestGiver

@export_group("NPC Identity")
@export var npc_name: String = "Village Elder"
@export var interaction_prompt_text: String = "E"

@export_group("Quest List")
@export var quests: Array[QuestEntry] = []

@export_group("Fallback Dialogue")
@export_multiline var no_available_quest_dialogue: String = "I have nothing else for you right now."

@export_group("Debug")
@export var debug_prints: bool = true

var nearby_player: Node = null


func _ready() -> void:
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)

    if not body_exited.is_connected(_on_body_exited):
        body_exited.connect(_on_body_exited)


func interact(player: Node) -> void:
    if player == null:
        return

    nearby_player = player

    var quest := _get_current_quest_entry()

    if quest == null:
        _show_dialogue_text(no_available_quest_dialogue)
        return

    if _is_quest_completed_by_flag(quest):
        _show_dialogue_text(quest.completed_dialogue)
        return

    if QuestManager.is_quest_ready_to_turn_in(quest.quest_id):
        _complete_quest(quest, player)
        _show_dialogue_text(quest.ready_to_turn_in_dialogue)
        return

    if QuestManager.is_quest_active(quest.quest_id):
        _show_dialogue_text(quest.active_dialogue)
        return

    if quest.start_on_interact:
        _start_quest(quest)

    _show_dialogue_text(quest.first_time_dialogue)


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
        print("Quest giver start quest result: ", started, " quest: ", quest.quest_id)


func _complete_quest(quest: QuestEntry, player: Node) -> void:
    if quest == null:
        return

    var completed := QuestManager.complete_quest(quest.quest_id, player)

    if debug_prints:
        print("Quest giver complete quest result: ", completed, " quest: ", quest.quest_id)


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
        print("Player entered quest giver range: ", npc_name)


func _on_body_exited(body: Node) -> void:
    if body != nearby_player:
        return

    if body.has_method("clear_nearby_interactable"):
        body.clear_nearby_interactable(self)

    nearby_player = null
    _hide_interaction_prompt()

    if debug_prints:
        print("Player left quest giver range: ", npc_name)

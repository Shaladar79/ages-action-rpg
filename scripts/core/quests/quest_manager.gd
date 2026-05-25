extends Node

const QUEST_TYPE_STORY: String = "story"
const QUEST_TYPE_OPTIONAL: String = "optional"

const COMPLETION_MODE_AUTO_COMPLETE: String = "auto_complete"
const COMPLETION_MODE_RETURN_TO_QUEST_GIVER: String = "return_to_quest_giver"

var active_quests: Dictionary = {}
var tracked_story_quest_id: String = ""
var tracked_optional_quest_ids: Array[String] = []


func start_quest(quest_entry: QuestEntry) -> bool:
    if quest_entry == null:
        return false

    var quest_id := quest_entry.quest_id.strip_edges()

    if quest_id == "":
        push_warning("Cannot start quest. Quest id is blank.")
        return false

    var completed_flag := quest_entry.completed_flag.strip_edges()

    if completed_flag != "" and SaveManager.is_flag_set(completed_flag):
        if OS.is_debug_build():
            print("QuestManager refused to restart completed quest by flag: ", quest_id)
        return false

    if is_quest_completed(quest_id):
        return false

    if active_quests.has(quest_id):
        return false

    if quest_entry.required_flag.strip_edges() != "" and not SaveManager.is_flag_set(quest_entry.required_flag):
        return false

    var quest_data := _build_quest_data_from_entry(quest_entry)

    active_quests[quest_id] = quest_data

    if quest_entry.started_flag.strip_edges() != "":
        SaveManager.set_flag(quest_entry.started_flag, true)

    if quest_entry.track_on_hud_when_started:
        track_quest(quest_id)

    _notify_quest_ui_changed()

    print("QuestManager started quest: ", quest_id)

    return true


func add_objective_progress(quest_id: String, objective_id: String, amount: int = 1) -> bool:
    var clean_quest_id := quest_id.strip_edges()
    var clean_objective_id := objective_id.strip_edges()

    if clean_quest_id == "":
        return false

    if clean_objective_id == "":
        return false

    if amount <= 0:
        return false

    if not active_quests.has(clean_quest_id):
        return false

    var quest_data: Dictionary = active_quests[clean_quest_id]
    var objectives: Dictionary = quest_data.get("objectives", {})

    if not objectives.has(clean_objective_id):
        return false

    var objective_data: Dictionary = objectives[clean_objective_id]

    if bool(objective_data.get("completed", false)):
        return false

    var current_amount: int = int(objective_data.get("current", 0))
    var required_amount: int = int(objective_data.get("required", 1))

    current_amount += amount
    current_amount = mini(current_amount, required_amount)

    objective_data["current"] = current_amount

    if current_amount >= required_amount:
        objective_data["completed"] = true

        var completed_flag: String = str(objective_data.get("completed_flag", "")).strip_edges()

        if completed_flag != "":
            SaveManager.set_flag(completed_flag, true)

        print("Quest objective completed: ", clean_quest_id, " / ", clean_objective_id)

    objectives[clean_objective_id] = objective_data
    quest_data["objectives"] = objectives
    active_quests[clean_quest_id] = quest_data

    print("Quest progress: ", clean_quest_id, " / ", clean_objective_id, " ", current_amount, " / ", required_amount)

    _check_quest_ready_or_complete(clean_quest_id)
    _notify_quest_ui_changed()

    return true


func complete_quest(quest_id: String, reward_player: Node = null) -> bool:
    var clean_quest_id := quest_id.strip_edges()

    if clean_quest_id == "":
        return false

    if not active_quests.has(clean_quest_id):
        return false

    var quest_data: Dictionary = active_quests[clean_quest_id]

    if reward_player == null:
        reward_player = get_tree().get_first_node_in_group("player")

    _apply_quest_rewards(quest_data, reward_player)

    var completed_flag: String = str(quest_data.get("completed_flag", "")).strip_edges()

    if completed_flag != "":
        SaveManager.set_flag(completed_flag, true)

    active_quests.erase(clean_quest_id)
    untrack_quest(clean_quest_id)

    _notify_quest_ui_changed()

    print("QuestManager completed quest: ", clean_quest_id)

    return true


func mark_quest_ready_to_turn_in(quest_id: String) -> bool:
    var clean_quest_id := quest_id.strip_edges()

    if clean_quest_id == "":
        return false

    if not active_quests.has(clean_quest_id):
        return false

    var quest_data: Dictionary = active_quests[clean_quest_id]

    if bool(quest_data.get("ready_to_turn_in", false)):
        return false

    quest_data["ready_to_turn_in"] = true
    active_quests[clean_quest_id] = quest_data

    var ready_flag: String = str(quest_data.get("ready_to_turn_in_flag", "")).strip_edges()

    if ready_flag != "":
        SaveManager.set_flag(ready_flag, true)

    _notify_quest_ui_changed()

    print("Quest ready to turn in: ", clean_quest_id)

    return true


func is_quest_active(quest_id: String) -> bool:
    return active_quests.has(quest_id.strip_edges())


func is_quest_ready_to_turn_in(quest_id: String) -> bool:
    var clean_quest_id := quest_id.strip_edges()

    if not active_quests.has(clean_quest_id):
        return false

    var quest_data: Dictionary = active_quests[clean_quest_id]

    return bool(quest_data.get("ready_to_turn_in", false))


func is_quest_completed(quest_id: String) -> bool:
    var clean_quest_id := quest_id.strip_edges()

    if clean_quest_id == "":
        return false

    if active_quests.has(clean_quest_id):
        return false

    var completed_flag := "quest_" + clean_quest_id + "_completed"

    return SaveManager.is_flag_set(completed_flag)


func track_quest(quest_id: String) -> bool:
    var clean_quest_id := quest_id.strip_edges()

    if clean_quest_id == "":
        return false

    if not active_quests.has(clean_quest_id):
        return false

    var quest_data: Dictionary = active_quests[clean_quest_id]
    var quest_type: String = str(quest_data.get("quest_type", QUEST_TYPE_OPTIONAL))

    if quest_type == QUEST_TYPE_STORY:
        tracked_story_quest_id = clean_quest_id
    else:
        if tracked_optional_quest_ids.has(clean_quest_id):
            return true

        if tracked_optional_quest_ids.size() >= 2:
            tracked_optional_quest_ids.remove_at(0)

        tracked_optional_quest_ids.append(clean_quest_id)

    _notify_quest_ui_changed()

    return true


func untrack_quest(quest_id: String) -> void:
    var clean_quest_id := quest_id.strip_edges()

    if clean_quest_id == "":
        return

    if tracked_story_quest_id == clean_quest_id:
        tracked_story_quest_id = ""

    for index in range(tracked_optional_quest_ids.size() - 1, -1, -1):
        if tracked_optional_quest_ids[index] == clean_quest_id:
            tracked_optional_quest_ids.remove_at(index)

    _notify_quest_ui_changed()


func get_tracked_quests() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []

    if tracked_story_quest_id.strip_edges() != "" and active_quests.has(tracked_story_quest_id):
        rows.append(active_quests[tracked_story_quest_id])

    for quest_id in tracked_optional_quest_ids:
        if not active_quests.has(quest_id):
            continue

        rows.append(active_quests[quest_id])

    return rows


func get_active_quest_rows() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []

    for quest_id in active_quests.keys():
        rows.append(active_quests[quest_id])

    return rows


func get_quest_save_data() -> Dictionary:
    return {
        "active_quests": active_quests.duplicate(true),
        "tracked_story_quest_id": tracked_story_quest_id,
        "tracked_optional_quest_ids": tracked_optional_quest_ids.duplicate()
    }


func load_quest_save_data(saved_quest_data: Dictionary) -> void:
    active_quests.clear()
    tracked_story_quest_id = ""
    tracked_optional_quest_ids.clear()

    if saved_quest_data.is_empty():
        _notify_quest_ui_changed()
        print("QuestManager loaded no saved quest data.")
        return

    var saved_active_quests: Dictionary = saved_quest_data.get("active_quests", {})

    for quest_id in saved_active_quests.keys():
        var clean_quest_id := str(quest_id).strip_edges()

        if clean_quest_id == "":
            continue

        var quest_data = saved_active_quests.get(quest_id, {})

        if typeof(quest_data) != TYPE_DICTIONARY:
            continue

        var typed_quest_data: Dictionary = quest_data.duplicate(true)

        var completed_flag: String = str(typed_quest_data.get("completed_flag", "")).strip_edges()

        if completed_flag != "" and SaveManager.is_flag_set(completed_flag):
            continue

        active_quests[clean_quest_id] = typed_quest_data

    var saved_story_id := str(saved_quest_data.get("tracked_story_quest_id", "")).strip_edges()

    if saved_story_id != "" and active_quests.has(saved_story_id):
        tracked_story_quest_id = saved_story_id

    var saved_optional_ids: Array = saved_quest_data.get("tracked_optional_quest_ids", [])

    for saved_optional_id in saved_optional_ids:
        var clean_optional_id := str(saved_optional_id).strip_edges()

        if clean_optional_id == "":
            continue

        if not active_quests.has(clean_optional_id):
            continue

        if tracked_optional_quest_ids.has(clean_optional_id):
            continue

        if tracked_optional_quest_ids.size() >= 2:
            break

        tracked_optional_quest_ids.append(clean_optional_id)

    _notify_quest_ui_changed()

    print("QuestManager loaded active quest count: ", active_quests.size())
    print("QuestManager loaded tracked optional quest count: ", tracked_optional_quest_ids.size())


func clear_quest_state() -> void:
    active_quests.clear()
    tracked_story_quest_id = ""
    tracked_optional_quest_ids.clear()
    _notify_quest_ui_changed()


func _build_quest_data_from_entry(quest_entry: QuestEntry) -> Dictionary:
    var quest_type_string := QUEST_TYPE_OPTIONAL

    if quest_entry.quest_type == QuestEntry.QuestType.STORY:
        quest_type_string = QUEST_TYPE_STORY

    var completion_mode_string := COMPLETION_MODE_RETURN_TO_QUEST_GIVER

    if quest_entry.completion_mode == QuestEntry.CompletionMode.AUTO_COMPLETE:
        completion_mode_string = COMPLETION_MODE_AUTO_COMPLETE

    var objectives := {}

    for objective_entry in quest_entry.objectives:
        if objective_entry == null:
            continue

        var objective_id := objective_entry.objective_id.strip_edges()

        if objective_id == "":
            continue

        var required_amount: int = maxi(1, objective_entry.required_amount)
        var current_amount: int = 0
        var completed := false

        if objective_entry.starts_completed:
            current_amount = required_amount
            completed = true

        objectives[objective_id] = {
            "objective_id": objective_id,
            "objective_type": int(objective_entry.objective_type),
            "text": objective_entry.objective_text,
            "current": current_amount,
            "required": required_amount,
            "completed": completed,
            "completed_flag": objective_entry.completed_flag
        }

    if objectives.is_empty():
        objectives["main"] = {
            "objective_id": "main",
            "objective_type": int(QuestObjectiveEntry.ObjectiveType.CUSTOM),
            "text": quest_entry.objective_text,
            "current": 0,
            "required": 1,
            "completed": false,
            "completed_flag": ""
        }

    return {
        "quest_id": quest_entry.quest_id.strip_edges(),
        "title": quest_entry.quest_title,
        "quest_type": quest_type_string,
        "summary": quest_entry.summary,
        "objective_text": quest_entry.objective_text,
        "started_flag": quest_entry.started_flag,
        "ready_to_turn_in_flag": quest_entry.ready_to_turn_in_flag,
        "completed_flag": quest_entry.completed_flag,
        "completion_mode": completion_mode_string,
        "ready_to_turn_in": false,
        "objectives": objectives,
        "reward_xp": maxi(0, quest_entry.reward_xp),
        "reward_currency_id": quest_entry.reward_currency_id,
        "reward_currency_amount": maxi(0, quest_entry.reward_currency_amount),
        "reward_item_1_id": quest_entry.reward_item_1_id,
        "reward_item_1_quantity": maxi(0, quest_entry.reward_item_1_quantity),
        "reward_item_2_id": quest_entry.reward_item_2_id,
        "reward_item_2_quantity": maxi(0, quest_entry.reward_item_2_quantity)
    }


func _check_quest_ready_or_complete(quest_id: String) -> void:
    var clean_quest_id := quest_id.strip_edges()

    if not active_quests.has(clean_quest_id):
        return

    var quest_data: Dictionary = active_quests[clean_quest_id]
    var objectives: Dictionary = quest_data.get("objectives", {})

    if objectives.is_empty():
        return

    for objective_id in objectives.keys():
        var objective_data: Dictionary = objectives[objective_id]

        if not bool(objective_data.get("completed", false)):
            return

    var completion_mode: String = str(quest_data.get("completion_mode", COMPLETION_MODE_RETURN_TO_QUEST_GIVER))

    if completion_mode == COMPLETION_MODE_AUTO_COMPLETE:
        complete_quest(clean_quest_id)
        return

    mark_quest_ready_to_turn_in(clean_quest_id)


func _apply_quest_rewards(quest_data: Dictionary, reward_player: Node) -> void:
    if reward_player == null:
        print("Quest rewards skipped because reward player is null.")
        return

    var reward_xp: int = int(quest_data.get("reward_xp", 0))

    if reward_xp > 0:
        if reward_player.has_method("gain_xp"):
            reward_player.gain_xp(reward_xp)
            print("Quest reward XP granted: ", reward_xp)
        else:
            push_warning("Quest reward XP failed. Player is missing gain_xp().")

    var reward_currency_id: String = str(quest_data.get("reward_currency_id", "")).strip_edges()
    var reward_currency_amount: int = int(quest_data.get("reward_currency_amount", 0))

    if reward_currency_id != "" and reward_currency_amount > 0:
        if reward_player.has_method("add_currency"):
            reward_player.add_currency(reward_currency_id, reward_currency_amount)
            print("Quest reward currency granted: ", reward_currency_id, " x", reward_currency_amount)
        else:
            push_warning("Quest reward currency failed. Player is missing add_currency().")

    _grant_item_reward(
        reward_player,
        str(quest_data.get("reward_item_1_id", "")),
        int(quest_data.get("reward_item_1_quantity", 0)),
        "Item Reward 1"
    )

    _grant_item_reward(
        reward_player,
        str(quest_data.get("reward_item_2_id", "")),
        int(quest_data.get("reward_item_2_quantity", 0)),
        "Item Reward 2"
    )


func _grant_item_reward(reward_player: Node, item_id: String, quantity: int, reward_label: String) -> void:
    var clean_item_id := item_id.strip_edges()
    var clean_quantity: int = maxi(0, quantity)

    if clean_item_id == "":
        return

    if clean_quantity <= 0:
        return

    if not reward_player.has_method("add_inventory_item"):
        push_warning("Quest " + reward_label + " failed. Player is missing add_inventory_item().")
        return

    var item_name := ItemDatabase.get_item_name(clean_item_id)

    for _index in range(clean_quantity):
        reward_player.add_inventory_item(clean_item_id, item_name)

    print("Quest reward item granted: ", item_name, " x", clean_quantity)


func _notify_quest_ui_changed() -> void:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("refresh_quest_display"):
            ui_node.refresh_quest_display()

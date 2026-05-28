extends Resource
class_name NPCDialogueEntry

@export_group("Condition")
@export var required_flag: String = ""
@export var blocked_if_flag_set: String = ""

@export_group("Dialogue")
@export var speaker_name_override: String = ""
@export_multiline var dialogue_text: String = ""

@export_group("After Dialogue - Flags")
@export var flags_to_set_after_dialogue: Array[String] = []

@export_group("After Dialogue - Quest Start")
@export var quest_to_start: QuestEntry = null

@export_group("After Dialogue - Quest Progress")
@export var progress_quest_id: String = ""
@export var progress_objective_id: String = ""
@export var progress_amount: int = 0

@export_group("After Dialogue - NPC Movement")
@export var trigger_npc_movement_after_dialogue: bool = false

@export_group("Behavior")
@export var priority: int = 0
@export var only_once: bool = false
@export var once_save_flag: String = ""


func can_use() -> bool:
    if dialogue_text.strip_edges() == "":
        return false

    if only_once:
        var clean_once_flag := once_save_flag.strip_edges()

        if clean_once_flag != "" and SaveManager.is_flag_set(clean_once_flag):
            return false

    var clean_required_flag := required_flag.strip_edges()

    if clean_required_flag != "":
        if not SaveManager.is_flag_set(clean_required_flag):
            return false

    var clean_blocked_flag := blocked_if_flag_set.strip_edges()

    if clean_blocked_flag != "":
        if SaveManager.is_flag_set(clean_blocked_flag):
            return false

    return true


func has_after_dialogue_actions() -> bool:
    if not flags_to_set_after_dialogue.is_empty():
        return true

    if quest_to_start != null:
        return true

    if progress_quest_id.strip_edges() != "" and progress_objective_id.strip_edges() != "" and progress_amount > 0:
        return true

    if trigger_npc_movement_after_dialogue:
        return true

    if only_once and once_save_flag.strip_edges() != "":
        return true

    return false

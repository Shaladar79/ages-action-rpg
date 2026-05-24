extends Resource
class_name QuestEntry

enum QuestType {
    STORY,
    OPTIONAL
}

enum CompletionMode {
    AUTO_COMPLETE,
    RETURN_TO_QUEST_GIVER
}

@export_group("Quest Identity")
@export var quest_id: String = ""
@export var quest_title: String = "New Quest"
@export var quest_type: QuestType = QuestType.OPTIONAL

@export_group("Quest Flags")
@export var started_flag: String = ""
@export var ready_to_turn_in_flag: String = ""
@export var completed_flag: String = ""

# Optional.
# Blank means this quest can appear immediately.
# Filled means this quest only becomes available after this flag is set.
@export var required_flag: String = ""

@export_group("Quest Text")
@export_multiline var first_time_dialogue: String = ""
@export_multiline var active_dialogue: String = ""
@export_multiline var ready_to_turn_in_dialogue: String = ""
@export_multiline var completed_dialogue: String = ""

@export_multiline var summary: String = ""
@export_multiline var objective_text: String = ""

@export_group("Objectives")
@export var objectives: Array[QuestObjectiveEntry] = []

@export_group("Behavior")
@export var start_on_interact: bool = true
@export var completion_mode: CompletionMode = CompletionMode.RETURN_TO_QUEST_GIVER
@export var track_on_hud_when_started: bool = true

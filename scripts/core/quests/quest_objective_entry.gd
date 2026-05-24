extends Resource
class_name QuestObjectiveEntry

enum ObjectiveType {
    CUSTOM,
    KILL,
    PICKUP,
    REACH_LOCATION,
    TALK_TO_NPC
}

@export_group("Objective Identity")
@export var objective_id: String = ""
@export var objective_type: ObjectiveType = ObjectiveType.CUSTOM

@export_group("Objective Display")
@export var objective_text: String = "Complete the objective"

@export_group("Progress")
@export var required_amount: int = 1
@export var starts_completed: bool = false

@export_group("Optional Flags")
# Optional. Blank means no flag is set when this objective completes.
@export var completed_flag: String = ""

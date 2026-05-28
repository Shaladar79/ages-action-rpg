extends Resource
class_name NPCMovementEventEntry

enum TriggerType {
    FLAG,
    QUEST_COMPLETED
}

enum MovementAction {
    FADE_OUT_ONLY,
    FADE_IN_ONLY,
    FADE_OUT_MOVE_FADE_IN,
    MOVE_ONLY,
    MOVE_THEN_FADE_OUT
}

@export_group("Event Identity")
@export var event_id: String = ""

@export_group("Trigger")
@export var trigger_type: TriggerType = TriggerType.FLAG
@export var required_flag: String = ""
@export var required_quest_id: String = ""

@export_group("Completion")
@export var completion_save_flag: String = ""
@export var only_once: bool = true

@export_group("Action")
@export var movement_action: MovementAction = MovementAction.FADE_OUT_MOVE_FADE_IN

@export_group("Target")
@export var target_marker_path: NodePath = NodePath("")
@export var use_target_marker: bool = true

@export_group("Movement")
@export var movement_speed: float = 60.0
@export var hide_while_moving: bool = true

@export_group("Fade")
@export var fade_out_duration: float = 0.75
@export var fade_in_duration: float = 0.75
@export var hide_after_fade_out: bool = true

@export_group("Interaction")
@export var disable_interaction_during_event: bool = true
@export var enable_interaction_after_event: bool = true


func can_run() -> bool:
    if only_once:
        var clean_completion_flag := completion_save_flag.strip_edges()

        if clean_completion_flag != "" and SaveManager.is_flag_set(clean_completion_flag):
            return false

    match trigger_type:
        TriggerType.FLAG:
            var clean_flag := required_flag.strip_edges()

            if clean_flag == "":
                return false

            return SaveManager.is_flag_set(clean_flag)

        TriggerType.QUEST_COMPLETED:
            var clean_quest_id := required_quest_id.strip_edges()

            if clean_quest_id == "":
                return false

            return QuestManager.is_quest_completed(clean_quest_id)

    return false


func mark_complete() -> void:
    var clean_completion_flag := completion_save_flag.strip_edges()

    if clean_completion_flag == "":
        return

    SaveManager.set_flag(clean_completion_flag, true)

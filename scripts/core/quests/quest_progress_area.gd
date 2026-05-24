extends Area2D
class_name QuestProgressArea

@export var quest_id: String = ""
@export var objective_id: String = ""
@export var progress_amount: int = 1

@export var trigger_once: bool = true
@export var disable_after_trigger: bool = true

@export var required_flag: String = ""
@export var debug_prints: bool = true

var _has_triggered: bool = false


func _ready() -> void:
    body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
    if _has_triggered and trigger_once:
        return

    if body == null:
        return

    if not body.is_in_group("player"):
        return

    var clean_quest_id := quest_id.strip_edges()
    var clean_objective_id := objective_id.strip_edges()

    if clean_quest_id == "":
        if debug_prints:
            push_warning("QuestProgressArea has blank quest_id.")
        return

    if clean_objective_id == "":
        if debug_prints:
            push_warning("QuestProgressArea has blank objective_id.")
        return

    if progress_amount <= 0:
        if debug_prints:
            push_warning("QuestProgressArea progress_amount must be greater than 0.")
        return

    if required_flag.strip_edges() != "":
        if not SaveManager.is_flag_set(required_flag):
            if debug_prints:
                print("QuestProgressArea blocked by missing required flag: ", required_flag)
            return

    if not QuestManager.is_quest_active(clean_quest_id):
        if debug_prints:
            print("QuestProgressArea ignored because quest is not active: ", clean_quest_id)
        return

    var progress_added := QuestManager.add_objective_progress(
        clean_quest_id,
        clean_objective_id,
        progress_amount
    )

    if not progress_added:
        if debug_prints:
            print("QuestProgressArea failed to add progress: ", clean_quest_id, " / ", clean_objective_id)
        return

    _has_triggered = true

    if debug_prints:
        print("QuestProgressArea added progress: ", clean_quest_id, " / ", clean_objective_id)

    if disable_after_trigger:
        monitoring = false
        set_deferred("monitorable", false)
        visible = false

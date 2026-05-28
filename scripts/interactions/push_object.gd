extends CharacterBody2D
class_name PushObject

@export_group("Persistence")
@export var persistent_id: String = ""

@export_group("Push Settings")
@export var push_distance: float = 32.0
@export var push_duration: float = 0.18

# 0 means unlimited pushes.
# 1 means this object can only be pushed once.
# 2+ means this object can be pushed that many times.
@export var max_push_count: int = 0

@export_group("Quest Progress")
@export var quest_id: String = ""
@export var objective_id: String = ""
@export var progress_amount: int = 1
@export var progress_on_first_successful_push: bool = true

# Optional.
# If filled, this flag is set after this push object gives quest progress.
# Also prevents repeated quest progress if Progress On First Successful Push is on.
@export var quest_progress_flag: String = ""

# Optional.
# If filled, this push object only gives quest progress after this flag is set.
# For the push-rock lesson, use starter_push_rock_lesson_started.
@export var required_flag: String = ""

@export_group("Debug")
@export var debug_prints: bool = true

var is_being_pushed: bool = false
var starting_position: Vector2 = Vector2.ZERO
var current_push_count: int = 0
var _pending_quest_progress: bool = false
var _quest_progress_recorded: bool = false


func _ready() -> void:
    starting_position = global_position
    _apply_saved_position_if_needed()
    _load_push_count_state()
    _load_quest_progress_state()


func _apply_saved_position_if_needed() -> void:
    if persistent_id.strip_edges() == "":
        return

    if not SaveManager.has_persistent_object_position(persistent_id):
        return

    global_position = SaveManager.get_persistent_object_position(persistent_id, global_position)

    if debug_prints:
        print("Push object loaded at saved position: ", persistent_id, " ", global_position)


func _load_push_count_state() -> void:
    if persistent_id.strip_edges() == "":
        return

    if max_push_count <= 0:
        return

    for push_index in range(1, max_push_count + 1):
        var push_flag := _get_push_count_flag(push_index)

        if SaveManager.is_flag_set(push_flag):
            current_push_count = push_index

    if debug_prints and current_push_count > 0:
        print("Push object loaded push count: ", persistent_id, " count: ", current_push_count)


func _load_quest_progress_state() -> void:
    var clean_progress_flag := quest_progress_flag.strip_edges()

    if clean_progress_flag == "":
        return

    _quest_progress_recorded = SaveManager.is_flag_set(clean_progress_flag)

    if debug_prints and _quest_progress_recorded:
        print("Push object quest progress already recorded: ", clean_progress_flag)


func push_from_player(player: Node2D) -> void:
    if is_being_pushed:
        return

    if player == null:
        return

    if not can_be_pushed():
        if debug_prints:
            print("Push object cannot be pushed anymore: ", name, " count: ", current_push_count, " max: ", max_push_count)
        return

    var push_direction := _get_push_direction_from_player(player)

    if push_direction == Vector2.ZERO:
        if debug_prints:
            print("Push object has no valid push direction.")
        return

    var movement := push_direction * push_distance

    if test_move(global_transform, movement):
        if debug_prints:
            print("Push object blocked.")
        return

    is_being_pushed = true
    _pending_quest_progress = _should_prepare_quest_progress()

    var target_position := global_position + movement
    var tween := create_tween()
    tween.tween_property(self, "global_position", target_position, push_duration)
    tween.finished.connect(_on_push_finished)

    if debug_prints:
        print("Push object moved: ", push_direction)


func can_be_pushed() -> bool:
    if max_push_count <= 0:
        return true

    return current_push_count < max_push_count


func reset_to_starting_position() -> void:
    if is_being_pushed:
        return

    global_position = starting_position
    current_push_count = 0
    save_current_position()

    if persistent_id.strip_edges() != "":
        for push_index in range(1, max_push_count + 1):
            var push_flag := _get_push_count_flag(push_index)

            if SaveManager.is_flag_set(push_flag):
                SaveManager.set_flag(push_flag, false)

    if debug_prints:
        print("Push object reset to starting position: ", name, " ", global_position)


func save_current_position() -> void:
    if persistent_id.strip_edges() == "":
        return

    SaveManager.set_persistent_object_position(persistent_id, global_position)

    if debug_prints:
        print("Saved push object position: ", persistent_id, " ", global_position)


func _save_push_count_state() -> void:
    if persistent_id.strip_edges() == "":
        return

    if max_push_count <= 0:
        return

    for push_index in range(1, current_push_count + 1):
        SaveManager.set_flag(_get_push_count_flag(push_index), true)

    if debug_prints:
        print("Saved push object push count: ", persistent_id, " count: ", current_push_count)


func _get_push_count_flag(push_index: int) -> String:
    return persistent_id.strip_edges() + "_push_count_" + str(push_index)


func _get_push_direction_from_player(player: Node2D) -> Vector2:
    var difference := global_position - player.global_position

    if abs(difference.x) > abs(difference.y):
        if difference.x > 0:
            return Vector2.RIGHT
        else:
            return Vector2.LEFT
    else:
        if difference.y > 0:
            return Vector2.DOWN
        else:
            return Vector2.UP


func _on_push_finished() -> void:
    is_being_pushed = false

    current_push_count += 1
    save_current_position()
    _save_push_count_state()

    if _pending_quest_progress:
        _pending_quest_progress = false
        _try_add_quest_progress()


func _should_prepare_quest_progress() -> bool:
    var clean_quest_id := quest_id.strip_edges()
    var clean_objective_id := objective_id.strip_edges()

    if clean_quest_id == "":
        return false

    if clean_objective_id == "":
        return false

    if progress_amount <= 0:
        return false

    var clean_required_flag := required_flag.strip_edges()

    if clean_required_flag != "" and not SaveManager.is_flag_set(clean_required_flag):
        if debug_prints:
            print("Push object quest progress blocked by missing required flag: ", clean_required_flag)
        return false

    if progress_on_first_successful_push and _quest_progress_recorded:
        if debug_prints:
            print("Push object quest progress already recorded.")
        return false

    var clean_progress_flag := quest_progress_flag.strip_edges()

    if progress_on_first_successful_push and clean_progress_flag != "" and SaveManager.is_flag_set(clean_progress_flag):
        _quest_progress_recorded = true

        if debug_prints:
            print("Push object quest progress blocked by saved progress flag: ", clean_progress_flag)

        return false

    if not QuestManager.is_quest_active(clean_quest_id):
        if debug_prints:
            print("Push object quest progress ignored because quest is not active: ", clean_quest_id)
        return false

    return true


func _try_add_quest_progress() -> void:
    var clean_quest_id := quest_id.strip_edges()
    var clean_objective_id := objective_id.strip_edges()

    if clean_quest_id == "":
        return

    if clean_objective_id == "":
        return

    if progress_amount <= 0:
        return

    var progress_added := QuestManager.add_objective_progress(
        clean_quest_id,
        clean_objective_id,
        progress_amount
    )

    if not progress_added:
        if debug_prints:
            print("Push object failed to add quest progress: ", clean_quest_id, " / ", clean_objective_id)
        return

    _quest_progress_recorded = true

    var clean_progress_flag := quest_progress_flag.strip_edges()

    if clean_progress_flag != "":
        SaveManager.set_flag(clean_progress_flag, true)

        if debug_prints:
            print("Push object set quest progress flag: ", clean_progress_flag)

    if debug_prints:
        print("Push object added quest progress: ", clean_quest_id, " / ", clean_objective_id)

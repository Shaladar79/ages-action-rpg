extends Area2D
class_name PuzzleResetStone

@export_group("Reset Setup")
@export var reset_id: String = ""
@export var push_object_paths: Array[NodePath] = []

@export_group("Interaction")
@export var interaction_prompt_text: String = "E"
@export var reset_message: String = "The puzzle stones return to their starting places."

@export_group("Quest Progress")
@export var quest_id: String = ""
@export var objective_id: String = ""
@export var progress_amount: int = 1
@export var progress_on_first_successful_reset: bool = true

# Optional.
# If filled, this flag is set after this reset stone gives quest progress.
# Also prevents repeated quest progress if Progress On First Successful Reset is on.
@export var quest_progress_flag: String = ""

# Optional.
# If filled, this reset stone only gives quest progress after this flag is set.
# For the puzzle lesson, use starter_puzzle_reset_lesson_started.
@export var required_flag: String = ""

@export_group("Debug")
@export var debug_prints: bool = true

var player_in_range: Node = null
var _quest_progress_recorded: bool = false


func _ready() -> void:
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)

    if not body_exited.is_connected(_on_body_exited):
        body_exited.connect(_on_body_exited)

    if reset_id.strip_edges() == "":
        reset_id = name

    _load_quest_progress_state()


func _process(_delta: float) -> void:
    if player_in_range == null:
        return

    if Input.is_action_just_pressed("interact"):
        reset_puzzle()


func reset_puzzle() -> void:
    var reset_count := 0

    for push_object_path in push_object_paths:
        var push_object := get_node_or_null(push_object_path)

        if push_object == null:
            push_warning("PuzzleResetStone could not find push object path: " + str(push_object_path))
            continue

        if not push_object.has_method("reset_to_starting_position"):
            push_warning("PuzzleResetStone target cannot reset: " + push_object.name)
            continue

        push_object.reset_to_starting_position()
        reset_count += 1

    if debug_prints:
        print("Puzzle reset stone used: ", reset_id, " reset count: ", reset_count)

    if reset_count > 0:
        _try_add_quest_progress()

    _show_reset_message()


func _load_quest_progress_state() -> void:
    var clean_progress_flag := quest_progress_flag.strip_edges()

    if clean_progress_flag == "":
        return

    _quest_progress_recorded = SaveManager.is_flag_set(clean_progress_flag)

    if debug_prints and _quest_progress_recorded:
        print("Puzzle reset quest progress already recorded: ", clean_progress_flag)


func _try_add_quest_progress() -> void:
    var clean_quest_id := quest_id.strip_edges()
    var clean_objective_id := objective_id.strip_edges()

    if clean_quest_id == "":
        return

    if clean_objective_id == "":
        return

    if progress_amount <= 0:
        return

    var clean_required_flag := required_flag.strip_edges()

    if clean_required_flag != "" and not SaveManager.is_flag_set(clean_required_flag):
        if debug_prints:
            print("Puzzle reset quest progress blocked by missing required flag: ", clean_required_flag)
        return

    if progress_on_first_successful_reset and _quest_progress_recorded:
        if debug_prints:
            print("Puzzle reset quest progress already recorded.")
        return

    var clean_progress_flag := quest_progress_flag.strip_edges()

    if progress_on_first_successful_reset and clean_progress_flag != "" and SaveManager.is_flag_set(clean_progress_flag):
        _quest_progress_recorded = true

        if debug_prints:
            print("Puzzle reset quest progress blocked by saved progress flag: ", clean_progress_flag)

        return

    if not QuestManager.is_quest_active(clean_quest_id):
        if debug_prints:
            print("Puzzle reset quest progress ignored because quest is not active: ", clean_quest_id)
        return

    var progress_added := QuestManager.add_objective_progress(
        clean_quest_id,
        clean_objective_id,
        progress_amount
    )

    if not progress_added:
        if debug_prints:
            print("Puzzle reset failed to add quest progress: ", clean_quest_id, " / ", clean_objective_id)
        return

    _quest_progress_recorded = true

    if clean_progress_flag != "":
        SaveManager.set_flag(clean_progress_flag, true)

        if debug_prints:
            print("Puzzle reset set quest progress flag: ", clean_progress_flag)

    if debug_prints:
        print("Puzzle reset added quest progress: ", clean_quest_id, " / ", clean_objective_id)


func _show_reset_message() -> void:
    var game_ui := _get_game_ui()

    if game_ui != null:
        if game_ui.has_method("show_notification"):
            game_ui.show_notification(reset_message)
            return

        if game_ui.has_method("show_reward_notification"):
            game_ui.show_reward_notification(reset_message)
            return

        if game_ui.has_method("show_story_message"):
            game_ui.show_story_message(reset_message, "Reset Stone")
            return

    if player_in_range != null and player_in_range.has_method("show_dialogue"):
        player_in_range.show_dialogue(reset_message)


func _show_prompt() -> void:
    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_prompt"):
        game_ui.show_prompt(interaction_prompt_text)


func _hide_prompt() -> void:
    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("hide_prompt"):
        game_ui.hide_prompt()


func _get_game_ui() -> Node:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null:
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null:
        return autoload_ui

    return null


func _is_player(body: Node) -> bool:
    if body == null:
        return false

    return body.is_in_group("player")


func _on_body_entered(body: Node) -> void:
    if not _is_player(body):
        return

    player_in_range = body
    _show_prompt()


func _on_body_exited(body: Node) -> void:
    if body != player_in_range:
        return

    player_in_range = null
    _hide_prompt()

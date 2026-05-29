extends Interactable
class_name SavePointInteractable

@export_group("Save Point")
@export var respawn_id: String = "start_cavern_totem"
@export var activated_message: String = "Respawn point activated."
@export var already_active_message: String = "This respawn point is already active."
@export var save_prompt_message: String = "Do you want to save your game?"

@export var respawn_marker_path: NodePath = NodePath("RespawnMarker")

@export_group("Quest Progress")
@export var quest_id: String = ""
@export var objective_id: String = ""
@export var progress_amount: int = 1
@export var progress_on_first_activation_only: bool = true

# Optional.
# If filled, this flag is set after this save point gives quest progress.
# Also prevents repeated quest progress if Progress On First Activation Only is on.
@export var quest_progress_flag: String = ""

# Optional.
# If filled, this save point only gives quest progress after this flag is set.
# For the save tutorial, use starter_save_totem_lesson_started.
@export var required_flag: String = ""

@export_group("Debug")
@export var debug_prints: bool = true

var is_activated: bool = false
var _quest_progress_recorded: bool = false


func _ready() -> void:
    interaction_id = respawn_id
    interaction_prompt = "Press E to activate."
    one_shot = false

    _load_activation_state()
    _load_quest_progress_state()

    super._ready()


func _load_activation_state() -> void:
    if respawn_id.strip_edges() == "":
        return

    is_activated = SaveManager.is_save_point_activated(respawn_id)

    if debug_prints and is_activated:
        print("Save point loaded as already activated: ", respawn_id)


func _load_quest_progress_state() -> void:
    var clean_progress_flag := quest_progress_flag.strip_edges()

    if clean_progress_flag == "":
        return

    _quest_progress_recorded = SaveManager.is_flag_set(clean_progress_flag)

    if debug_prints and _quest_progress_recorded:
        print("Save point quest progress already recorded: ", clean_progress_flag)


func _on_interact(player: Node2D) -> void:
    var respawn_position := _get_respawn_position()
    var scene_path := _get_current_scene_path()

    RespawnManager.set_respawn_point(respawn_id, scene_path, respawn_position)

    if respawn_id.strip_edges() != "":
        SaveManager.mark_save_point_activated(respawn_id)

    if debug_prints:
        print("Save point using respawn position: ", respawn_position)

    var was_already_activated := is_activated

    if is_activated:
        _show_or_print_message(player, already_active_message)
    else:
        is_activated = true
        _show_or_print_message(player, activated_message)

    if not was_already_activated or not progress_on_first_activation_only:
        _try_add_quest_progress()

    _show_save_prompt(player)


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
            print("Save point quest progress blocked by missing required flag: ", clean_required_flag)
        return

    if progress_on_first_activation_only and _quest_progress_recorded:
        if debug_prints:
            print("Save point quest progress already recorded.")
        return

    var clean_progress_flag := quest_progress_flag.strip_edges()

    if progress_on_first_activation_only and clean_progress_flag != "" and SaveManager.is_flag_set(clean_progress_flag):
        _quest_progress_recorded = true

        if debug_prints:
            print("Save point quest progress blocked by saved progress flag: ", clean_progress_flag)

        return

    if not QuestManager.is_quest_active(clean_quest_id):
        if debug_prints:
            print("Save point quest progress ignored because quest is not active: ", clean_quest_id)
        return

    var progress_added := QuestManager.add_objective_progress(
        clean_quest_id,
        clean_objective_id,
        progress_amount
    )

    if not progress_added:
        if debug_prints:
            print("Save point failed to add quest progress: ", clean_quest_id, " / ", clean_objective_id)
        return

    _quest_progress_recorded = true

    if clean_progress_flag != "":
        SaveManager.set_flag(clean_progress_flag, true)

        if debug_prints:
            print("Save point set quest progress flag: ", clean_progress_flag)

    if debug_prints:
        print("Save point added quest progress: ", clean_quest_id, " / ", clean_objective_id)


func _show_save_prompt(player: Node2D) -> void:
    if debug_prints:
        print("Trying to show save prompt...")

    var game_ui := get_node_or_null("/root/GameUi")

    if game_ui == null:
        if debug_prints:
            print("No /root/GameUi found. Trying interaction_ui group.")

        game_ui = get_tree().get_first_node_in_group("interaction_ui")

    if game_ui == null:
        push_warning("No GameUi found. Cannot show save prompt.")
        return

    if debug_prints:
        print("Found UI node: ", game_ui.name)

    if not game_ui.has_method("show_save_prompt"):
        push_warning("Found UI node does not have show_save_prompt(): " + game_ui.name)
        return

    if debug_prints:
        print("Calling GameUi.show_save_prompt().")

    game_ui.show_save_prompt(player, save_prompt_message)


func _get_respawn_position() -> Vector2:
    var marker := get_node_or_null(respawn_marker_path) as Node2D

    if marker != null:
        return marker.global_position

    marker = find_child("RespawnMarker", true, false) as Node2D

    if marker != null:
        return marker.global_position

    push_warning("No RespawnMarker found for save point: " + name + ". Using save point position.")
    return global_position


func _get_current_scene_path() -> String:
    var current_scene := get_tree().current_scene

    if current_scene == null:
        return ""

    return current_scene.scene_file_path


func _show_or_print_message(player: Node2D, message: String) -> void:
    if message.strip_edges() == "":
        return

    var game_ui := get_node_or_null("/root/GameUi")

    if game_ui == null:
        game_ui = get_tree().get_first_node_in_group("interaction_ui")

    if game_ui != null and game_ui.has_method("show_notification"):
        game_ui.show_notification(message)
        return

    if player != null and player.has_method("show_dialogue"):
        player.show_dialogue(message)
    else:
        print(message)

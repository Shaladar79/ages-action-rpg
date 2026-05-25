extends Interactable
class_name RestAreaInteractable

@export_group("Rest Area Identity")
@export var rest_area_id: String = "rest_area_01"
@export var rest_area_name: String = "Rest Area"

@export_group("Interaction")
@export var interaction_prompt_text: String = "Press E to rest."
@export var rest_message: String = "You rest and recover."
@export var already_active_message: String = "This rest area is already your active respawn point."

@export_group("Restore Options")
@export var restore_health: bool = true
@export var restore_mana: bool = true
@export var restore_stamina: bool = true

@export_group("Save Options")
@export var can_save: bool = false
@export var show_save_prompt_after_rest: bool = false
@export var save_prompt_message: String = "Do you want to save your game?"

@export_group("Respawn Options")
@export var acts_as_respawn_point: bool = false
@export var respawn_id: String = ""
@export var respawn_marker_path: NodePath = NodePath("RespawnMarker")

@export_group("Debug")
@export var debug_prints: bool = true

var is_activated: bool = false


func _ready() -> void:
    if rest_area_id.strip_edges() == "":
        rest_area_id = name

    if respawn_id.strip_edges() == "":
        respawn_id = rest_area_id

    interaction_id = rest_area_id
    interaction_prompt = interaction_prompt_text
    one_shot = false

    super._ready()


func _on_interact(player: Node2D) -> void:
    if player == null:
        return

    var did_restore := _restore_player_resources(player)
    var did_set_respawn := false

    if acts_as_respawn_point:
        did_set_respawn = _set_respawn_point()

    if did_set_respawn:
        if is_activated:
            _show_or_print_message(player, already_active_message)
        else:
            is_activated = true
            _show_or_print_message(player, rest_message)
    elif did_restore:
        _show_or_print_message(player, rest_message)
    else:
        _show_or_print_message(player, rest_message)

    if can_save and show_save_prompt_after_rest:
        _show_save_prompt(player)


func _restore_player_resources(player: Node2D) -> bool:
    if player == null:
        return false

    if not player.has_method("get_character_stats"):
        return false

    var stats: CharacterStats = player.get_character_stats()

    if stats == null:
        return false

    var restored_anything := false

    if restore_health:
        if stats.current_health < stats.max_health:
            restored_anything = true

        stats.current_health = stats.max_health

    if restore_mana and stats.has_mana_resource:
        if stats.current_mana < stats.max_mana:
            restored_anything = true

        stats.current_mana = stats.max_mana

    if restore_stamina and stats.has_stamina_resource:
        if stats.current_stamina < stats.max_stamina:
            restored_anything = true

        stats.current_stamina = stats.max_stamina

    if player.has_method("_notify_ui_stats_changed"):
        player._notify_ui_stats_changed()

    if debug_prints:
        print(rest_area_name, " restored resources.")
        print("Health: ", stats.current_health, " / ", stats.max_health)

        if stats.has_mana_resource:
            print("Mana: ", stats.current_mana, " / ", stats.max_mana)

        if stats.has_stamina_resource:
            print("Stamina: ", stats.current_stamina, " / ", stats.max_stamina)

    return restored_anything


func _set_respawn_point() -> bool:
    var clean_respawn_id := respawn_id.strip_edges()

    if clean_respawn_id == "":
        push_warning("Rest area cannot set respawn. Respawn ID is blank: " + name)
        return false

    var respawn_position := _get_respawn_position()
    var scene_path := _get_current_scene_path()

    RespawnManager.set_respawn_point(clean_respawn_id, scene_path, respawn_position)

    if SaveManager != null and SaveManager.has_method("mark_save_point_activated"):
        SaveManager.mark_save_point_activated(clean_respawn_id)

    if debug_prints:
        print("Rest area set respawn point.")
        print("Respawn ID: ", clean_respawn_id)
        print("Respawn scene: ", scene_path)
        print("Respawn position: ", respawn_position)

    return true


func _show_save_prompt(player: Node2D) -> void:
    var game_ui := get_node_or_null("/root/GameUi")

    if game_ui == null:
        game_ui = get_tree().get_first_node_in_group("interaction_ui")

    if game_ui == null:
        push_warning("No GameUi found. Cannot show save prompt.")
        return

    if not game_ui.has_method("show_save_prompt"):
        push_warning("Found UI node does not have show_save_prompt(): " + game_ui.name)
        return

    game_ui.show_save_prompt(player, save_prompt_message)


func _get_respawn_position() -> Vector2:
    var marker := get_node_or_null(respawn_marker_path) as Node2D

    if marker != null:
        return marker.global_position

    marker = find_child("RespawnMarker", true, false) as Node2D

    if marker != null:
        return marker.global_position

    push_warning("No RespawnMarker found for rest area: " + name + ". Using rest area position.")
    return global_position


func _get_current_scene_path() -> String:
    var current_scene := get_tree().current_scene

    if current_scene == null:
        return ""

    return current_scene.scene_file_path


func _show_or_print_message(player: Node2D, message: String) -> void:
    var clean_message := message.strip_edges()

    if clean_message == "":
        return

    if player != null and player.has_method("show_dialogue"):
        player.show_dialogue(clean_message, rest_area_name)
        return

    print(clean_message)

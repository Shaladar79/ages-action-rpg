extends RefCounted
class_name PlayerInteractionComponent

var player: Node = null


func setup(owner_player: Node) -> void:
    player = owner_player


func show_dialogue(message: String, speaker_name: String = "System") -> void:
    if player == null:
        return

    var clean_message := message.strip_edges()

    if clean_message == "":
        return

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("show_story_message"):
        game_ui.show_story_message(clean_message, speaker_name)
        return

    print("Dialogue message with no GameUi available: ", clean_message)


func hide_dialogue() -> void:
    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("hide_story_dialogue"):
        game_ui.hide_story_dialogue()
        return


func is_dialogue_active() -> bool:
    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("is_story_dialogue_active"):
        return game_ui.is_story_dialogue_active()

    return false


func notify_nearby_interactable_dialogue_closed() -> void:
    if player == null:
        return

    var nearby_interactable: Node = player.get("nearby_interactable")

    if nearby_interactable == null:
        return

    if nearby_interactable.has_method("on_player_dialogue_closed"):
        nearby_interactable.on_player_dialogue_closed(player)


func set_nearby_interactable(interactable: Node) -> void:
    if player == null:
        return

    if bool(player.get("is_defeated")):
        return

    player.set("nearby_interactable", interactable)

    print("Nearby interactable: ", interactable.name)

    show_interaction_prompt()


func clear_nearby_interactable(interactable: Node) -> void:
    if player == null:
        return

    var nearby_interactable: Node = player.get("nearby_interactable")

    if nearby_interactable != interactable:
        return

    print("Cleared interactable: ", interactable.name)

    player.set("nearby_interactable", null)

    hide_interaction_prompt()


func show_interaction_prompt() -> void:
    if player == null:
        return

    var interaction_ui := player.get_tree().get_first_node_in_group("interaction_ui")

    if interaction_ui == null:
        push_warning("No node found in group: interaction_ui")
        return

    if interaction_ui.has_method("show_prompt"):
        interaction_ui.show_prompt("🖱 Right Mouse / Alt")


func hide_interaction_prompt() -> void:
    if player == null:
        return

    var interaction_ui := player.get_tree().get_first_node_in_group("interaction_ui")

    if interaction_ui == null:
        return

    if interaction_ui.has_method("hide_prompt"):
        interaction_ui.hide_prompt()


func try_interact() -> void:
    if player == null:
        return

    if bool(player.get("is_defeated")):
        return

    if is_dialogue_active():
        return

    var game_ui := _get_game_ui()

    if game_ui != null and game_ui.has_method("should_block_player_interact"):
        if game_ui.should_block_player_interact():
            return

    var nearby_interactable: Node = player.get("nearby_interactable")

    if nearby_interactable == null:
        print("No nearby interactable.")
        return

    if nearby_interactable.has_method("interact"):
        nearby_interactable.interact(player)


func _get_game_ui() -> Node:
    if player == null:
        return null

    if player.has_method("_get_game_ui"):
        return player._get_game_ui()

    var group_nodes := player.get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node != null and ui_node.has_method("show_story_dialogue"):
            return ui_node

    var autoload_ui := player.get_node_or_null("/root/GameUi")

    if autoload_ui != null and autoload_ui.has_method("show_story_dialogue"):
        return autoload_ui

    return null

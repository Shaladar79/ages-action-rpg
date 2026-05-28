extends Area2D
class_name NPCActor

@export_group("NPC Identity")
@export var npc_name: String = "NPC"
@export var interaction_prompt_text: String = "E"

@export_group("Interaction")
@export var interaction_enabled: bool = true
@export var auto_setup_child_modules: bool = true

@export_group("Facing")
@export var face_player_on_interact: bool = true
@export var face_player_on_enter_range: bool = false
@export var animated_sprite_path: NodePath = NodePath("AnimatedSprite2D")

@export var idle_up_animation: String = "idle_up"
@export var idle_down_animation: String = "idle_down"
@export var idle_left_animation: String = "idle_left"
@export var idle_right_animation: String = "idle_right"

@export_group("Debug")
@export var debug_prints: bool = true

var nearby_player: Node = null
var behavior_modules: Array[NPCBehaviorModule] = []


func _ready() -> void:
    if auto_setup_child_modules:
        _setup_child_modules()

    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)

    if not body_exited.is_connected(_on_body_exited):
        body_exited.connect(_on_body_exited)

    if debug_prints:
        print("NPCActor ready: ", npc_name)
        print("NPCActor module count: ", behavior_modules.size())


func interact(player: Node) -> void:
    if not interaction_enabled:
        if debug_prints:
            print("NPCActor interaction blocked. Interaction disabled: ", npc_name)
        return

    if player == null:
        return

    nearby_player = player

    if face_player_on_interact:
        _face_player(player)

    var sorted_modules: Array[NPCBehaviorModule] = behavior_modules.duplicate()
    sorted_modules.sort_custom(_sort_modules_by_priority)

    for module in sorted_modules:
        if module == null:
            continue

        if not module.can_handle_interact(player):
            continue

        var handled: bool = bool(module.handle_interact(player))

        if handled:
            if debug_prints:
                print("NPCActor interaction handled by module: ", module.name)
            return

    if debug_prints:
        print("NPCActor had no module handle interaction: ", npc_name)


func set_interaction_enabled(enabled: bool) -> void:
    interaction_enabled = enabled

    for module in behavior_modules:
        if module == null:
            continue

        module.set_behavior_enabled(enabled)

    if not enabled:
        _hide_interaction_prompt()


func register_behavior_module(module: NPCBehaviorModule) -> void:
    if module == null:
        return

    if behavior_modules.has(module):
        return

    behavior_modules.append(module)
    module.setup(self)

    if debug_prints:
        print("NPCActor registered module: ", module.name)


func _setup_child_modules() -> void:
    behavior_modules.clear()

    for child in get_children():
        if child is NPCBehaviorModule:
            var module := child as NPCBehaviorModule
            register_behavior_module(module)


func _sort_modules_by_priority(a: NPCBehaviorModule, b: NPCBehaviorModule) -> bool:
    if a == null:
        return false

    if b == null:
        return true

    return a.get_interaction_priority() > b.get_interaction_priority()


func _on_body_entered(body: Node) -> void:
    if body == null:
        return

    if not body.is_in_group("player"):
        return

    nearby_player = body

    if face_player_on_enter_range:
        _face_player(body)

    if body.has_method("set_nearby_interactable"):
        body.set_nearby_interactable(self)

    if interaction_enabled:
        _show_interaction_prompt()

    for module in behavior_modules:
        if module == null:
            continue

        module.on_player_entered(body)

    if debug_prints:
        print("Player entered NPCActor range: ", npc_name)


func _on_body_exited(body: Node) -> void:
    if body != nearby_player:
        return

    if body.has_method("clear_nearby_interactable"):
        body.clear_nearby_interactable(self)

    for module in behavior_modules:
        if module == null:
            continue

        module.on_player_exited(body)

    nearby_player = null
    _hide_interaction_prompt()

    if debug_prints:
        print("Player left NPCActor range: ", npc_name)


func _face_player(player: Node) -> void:
    if player == null:
        return

    if not player is Node2D:
        return

    var player_2d := player as Node2D
    var difference: Vector2 = player_2d.global_position - global_position

    if difference == Vector2.ZERO:
        return

    var facing_direction := _get_cardinal_direction_from_vector(difference)
    _play_idle_direction(facing_direction)


func _get_cardinal_direction_from_vector(direction: Vector2) -> String:
    if abs(direction.x) > abs(direction.y):
        if direction.x > 0.0:
            return "right"

        return "left"

    if direction.y > 0.0:
        return "down"

    return "up"


func _play_idle_direction(direction_name: String) -> void:
    var sprite := _get_animated_sprite()

    if sprite == null:
        if debug_prints:
            print("NPCActor has no AnimatedSprite2D for facing: ", npc_name)
        return

    var animation_name := _get_idle_animation_name(direction_name)

    if animation_name.strip_edges() == "":
        return

    if sprite.sprite_frames == null:
        if debug_prints:
            print("NPCActor AnimatedSprite2D has no SpriteFrames: ", npc_name)
        return

    if not sprite.sprite_frames.has_animation(animation_name):
        if debug_prints:
            print("NPCActor missing facing animation: ", animation_name, " on ", npc_name)
        return

    sprite.play(animation_name)


func _get_idle_animation_name(direction_name: String) -> String:
    match direction_name:
        "up":
            return idle_up_animation
        "down":
            return idle_down_animation
        "left":
            return idle_left_animation
        "right":
            return idle_right_animation

    return idle_down_animation


func _get_animated_sprite() -> AnimatedSprite2D:
    if animated_sprite_path == NodePath(""):
        return null

    var node := get_node_or_null(animated_sprite_path)

    if node == null:
        return null

    if not node is AnimatedSprite2D:
        return null

    return node as AnimatedSprite2D


func _show_interaction_prompt() -> void:
    var game_ui := get_tree().get_first_node_in_group("interaction_ui")

    if game_ui == null:
        return

    if game_ui.has_method("show_prompt"):
        game_ui.show_prompt(interaction_prompt_text)


func _hide_interaction_prompt() -> void:
    var game_ui := get_tree().get_first_node_in_group("interaction_ui")

    if game_ui == null:
        return

    if game_ui.has_method("hide_prompt"):
        game_ui.hide_prompt()


func get_game_ui() -> Node:
    var group_nodes := get_tree().get_nodes_in_group("interaction_ui")

    for ui_node in group_nodes:
        if ui_node == null:
            continue

        if ui_node.has_method("show_story_dialogue"):
            return ui_node

        if ui_node.has_method("show_shop"):
            return ui_node

        if ui_node.has_method("show_prompt"):
            return ui_node

    var autoload_ui := get_node_or_null("/root/GameUi")

    if autoload_ui != null:
        return autoload_ui

    return null

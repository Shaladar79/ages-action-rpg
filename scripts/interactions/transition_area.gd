extends Area2D
class_name TransitionArea

enum TransitionType {
    SAME_MAP,
    CHANGE_SCENE
}

@export var transition_type: TransitionType = TransitionType.SAME_MAP

@export var target_marker_path: NodePath
@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_id: String = ""

@export var require_interact_button: bool = false
@export var transition_cooldown: float = 0.25

var can_transition: bool = true
var player_in_area: Node2D = null


func _ready() -> void:
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)

    if not body_exited.is_connected(_on_body_exited):
        body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
    if not require_interact_button:
        return

    if player_in_area == null:
        return

    if Input.is_action_just_pressed("interact"):
        _try_transition(player_in_area)


func _on_body_entered(body: Node2D) -> void:
    print("Transition body entered: ", body.name)

    if not body.is_in_group("player"):
        print("Entered body is not player.")
        return

    print("Player entered transition area.")

    player_in_area = body

    if require_interact_button:
        print("Transition requires interact button.")
        return

    _try_transition(body)


func _on_body_exited(body: Node2D) -> void:
    if body != player_in_area:
        return

    player_in_area = null


func _try_transition(player: Node2D) -> void:
    if not can_transition:
        print("Transition is cooling down.")
        return

    match transition_type:
        TransitionType.SAME_MAP:
            _transition_same_map(player)

        TransitionType.CHANGE_SCENE:
            _transition_to_scene()


func _transition_same_map(player: Node2D) -> void:
    print("Trying same-map transition.")

    var marker := get_node_or_null(target_marker_path) as Node2D

    if marker == null:
        marker = get_tree().current_scene.get_node_or_null(target_marker_path) as Node2D

    if marker == null:
        push_warning("TransitionArea has no valid target marker. Target path is: " + str(target_marker_path))
        return

    print("Moving player to marker: ", marker.name, " at ", marker.global_position)

    can_transition = false
    player.global_position = marker.global_position

    await get_tree().create_timer(transition_cooldown).timeout
    can_transition = true


func _transition_to_scene() -> void:
    print("Trying scene transition.")

    if target_scene_path.strip_edges() == "":
        push_warning("TransitionArea target_scene_path is blank: " + name)
        return

    if not ResourceLoader.exists(target_scene_path):
        push_warning("TransitionArea target scene does not exist: " + target_scene_path)
        return

    get_tree().change_scene_to_file(target_scene_path)

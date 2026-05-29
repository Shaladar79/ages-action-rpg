extends StaticBody2D
class_name BreakableObject

@export_group("Persistence")
@export var persistent_id: String = ""

@export_group("Break Settings")
@export var max_hit_points: int = 3
@export var required_tool_tag: String = "club"
@export var broken_sprite_visible: bool = false

@export_group("Quest Progress")
@export var quest_id: String = ""
@export var objective_id: String = ""
@export var progress_amount: int = 1
@export var progress_on_break: bool = true

# Optional.
# If filled, this flag is set after this breakable gives quest progress.
# Also prevents repeated quest progress if this object somehow tries to report again.
@export var quest_progress_flag: String = ""

# Optional.
# If filled, this breakable only gives quest progress after this flag is set.
# For the breakable tutorial, use starter_breakable_object_lesson_started.
@export var required_flag: String = ""

@export_group("Debug")
@export var debug_prints: bool = true

@onready var object_sprite: Sprite2D = get_node_or_null("RockSprite") as Sprite2D

var current_hit_points: int = 0
var is_broken: bool = false
var _quest_progress_recorded: bool = false


func _ready() -> void:
    current_hit_points = max_hit_points
    _load_quest_progress_state()

    if _should_start_broken_from_save():
        _set_broken_state(false)


func _load_quest_progress_state() -> void:
    var clean_progress_flag := quest_progress_flag.strip_edges()

    if clean_progress_flag == "":
        return

    _quest_progress_recorded = SaveManager.is_flag_set(clean_progress_flag)

    if debug_prints and _quest_progress_recorded:
        print("Breakable object quest progress already recorded: ", clean_progress_flag)


func _should_start_broken_from_save() -> bool:
    if persistent_id.strip_edges() == "":
        return false

    if not SaveManager.is_breakable_broken(persistent_id):
        return false

    if debug_prints:
        print("Breakable object loaded as already broken: ", persistent_id)

    return true


func can_be_damaged_by(player: Node2D) -> bool:
    if is_broken:
        return false

    if required_tool_tag.strip_edges() == "":
        return true

    if player == null:
        return false

    if not player.has_method("get_character_stats"):
        return false

    var stats: CharacterStats = player.get_character_stats()

    if stats == null:
        return false

    return stats.has_equipped_breakable_tool(required_tool_tag)


func take_damage_from_player(damage_amount: int, player: Node2D) -> void:
    if is_broken:
        return

    if not can_be_damaged_by(player):
        if debug_prints:
            print("This object requires tool tag: ", required_tool_tag)
        return

    take_damage(damage_amount)


func take_damage(damage_amount: int) -> void:
    if is_broken:
        return

    if damage_amount <= 0:
        return

    current_hit_points -= damage_amount

    if debug_prints:
        print("Breakable object took damage: ", damage_amount)
        print("Breakable HP: ", current_hit_points, " / ", max_hit_points)

    if current_hit_points <= 0:
        break_object()


func break_object() -> void:
    if is_broken:
        return

    if persistent_id.strip_edges() != "":
        SaveManager.mark_breakable_broken(persistent_id)

    if progress_on_break:
        _try_add_quest_progress()

    _set_broken_state(true)


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
            print("Breakable quest progress blocked by missing required flag: ", clean_required_flag)
        return

    if _quest_progress_recorded:
        if debug_prints:
            print("Breakable quest progress already recorded.")
        return

    var clean_progress_flag := quest_progress_flag.strip_edges()

    if clean_progress_flag != "" and SaveManager.is_flag_set(clean_progress_flag):
        _quest_progress_recorded = true

        if debug_prints:
            print("Breakable quest progress blocked by saved progress flag: ", clean_progress_flag)

        return

    if not QuestManager.is_quest_active(clean_quest_id):
        if debug_prints:
            print("Breakable quest progress ignored because quest is not active: ", clean_quest_id)
        return

    var progress_added := QuestManager.add_objective_progress(
        clean_quest_id,
        clean_objective_id,
        progress_amount
    )

    if not progress_added:
        if debug_prints:
            print("Breakable failed to add quest progress: ", clean_quest_id, " / ", clean_objective_id)
        return

    _quest_progress_recorded = true

    if clean_progress_flag != "":
        SaveManager.set_flag(clean_progress_flag, true)

        if debug_prints:
            print("Breakable set quest progress flag: ", clean_progress_flag)

    if debug_prints:
        print("Breakable added quest progress: ", clean_quest_id, " / ", clean_objective_id)


func _set_broken_state(print_message: bool = true) -> void:
    is_broken = true
    current_hit_points = 0

    _disable_all_collision_shapes(self)

    collision_layer = 0
    collision_mask = 0
    process_mode = Node.PROCESS_MODE_DISABLED

    if object_sprite != null:
        object_sprite.visible = broken_sprite_visible

    if print_message and debug_prints:
        print("Breakable object broken. Collision layer/mask disabled.")


func _disable_all_collision_shapes(node: Node) -> void:
    for child in node.get_children():
        if child is CollisionShape2D:
            child.set_deferred("disabled", true)

        if child is CollisionPolygon2D:
            child.set_deferred("disabled", true)

        if child is StaticBody2D:
            child.set_deferred("collision_layer", 0)
            child.set_deferred("collision_mask", 0)

        _disable_all_collision_shapes(child)

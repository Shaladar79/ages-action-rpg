extends StaticBody2D
class_name BreakableObject

@export var max_hit_points: int = 3
@export var required_tool_tag: String = "club"
@export var broken_sprite_visible: bool = false

@onready var object_sprite: Sprite2D = get_node_or_null("RockSprite") as Sprite2D

var current_hit_points: int = 0
var is_broken: bool = false


func _ready() -> void:
    current_hit_points = max_hit_points


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
        print("This object requires tool tag: ", required_tool_tag)
        return

    take_damage(damage_amount)


func take_damage(damage_amount: int) -> void:
    if is_broken:
        return

    if damage_amount <= 0:
        return

    current_hit_points -= damage_amount

    print("Breakable object took damage: ", damage_amount)
    print("Breakable HP: ", current_hit_points, " / ", max_hit_points)

    if current_hit_points <= 0:
        break_object()


func break_object() -> void:
    if is_broken:
        return

    is_broken = true

    _disable_all_collision_shapes(self)

    collision_layer = 0
    collision_mask = 0
    process_mode = Node.PROCESS_MODE_DISABLED

    if object_sprite != null:
        object_sprite.visible = broken_sprite_visible

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

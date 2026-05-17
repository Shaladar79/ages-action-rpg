extends StaticBody2D

@export var required_equipped_item_id: String = "crude_club"
@export var broken_sprite_visible: bool = false

@onready var body_collision: CollisionShape2D = $BodyCollision
@onready var object_sprite: Sprite2D = $RockSprite

var is_broken: bool = false


func can_break(player: Node2D) -> bool:
    # Temporary placeholder until player inventory/equipment exists.
    # Later this will check something like:
    # return player.has_equipped_item(required_equipped_item_id)
    return false


func try_break(player: Node2D) -> void:
    if is_broken:
        return

    if not can_break(player):
        print("This object requires equipped item: ", required_equipped_item_id)
        return

    break_object()


func break_object() -> void:
    if is_broken:
        return

    is_broken = true

    if body_collision != null:
        body_collision.disabled = true

    if object_sprite != null:
        object_sprite.visible = broken_sprite_visible

    print("Breakable object broken.")

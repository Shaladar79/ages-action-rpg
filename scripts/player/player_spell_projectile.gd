extends Area2D
class_name PlayerSpellProjectile

var caster: Node2D = null
var direction: Vector2 = Vector2.ZERO
var speed: float = 260.0
var max_range: float = 220.0
var traveled_distance: float = 0.0

var spell_item_id: String = ""
var spell_name: String = ""
var status_effect: String = ""
var status_duration: float = 0.0
var status_effect_data: Dictionary = {}

var has_hit: bool = false


func setup(
        projectile_caster: Node2D,
        cast_direction: Vector2,
        item_id: String,
        range_value: float,
        effect_id: String,
        effect_duration: float,
        effect_data: Dictionary = {}
) -> void:
    caster = projectile_caster
    direction = cast_direction.normalized()
    spell_item_id = item_id
    spell_name = ItemDatabase.get_spell_name(item_id)
    max_range = range_value
    status_effect = effect_id
    status_duration = effect_duration
    status_effect_data = effect_data.duplicate(true)

    if direction == Vector2.ZERO:
        direction = Vector2.DOWN

    rotation = direction.angle()


func _ready() -> void:
    monitoring = true
    monitorable = true

    if collision_layer == 0:
        collision_layer = 0

    if collision_mask == 0:
        collision_mask = 1

    _ensure_collision_shape()
    _ensure_visual()

    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
    if has_hit:
        return

    var movement := direction * speed * delta
    global_position += movement
    traveled_distance += movement.length()

    if traveled_distance >= max_range:
        queue_free()


func _ensure_collision_shape() -> void:
    var existing_collision := get_node_or_null("CollisionShape2D") as CollisionShape2D

    if existing_collision != null:
        return

    var collision_shape := CollisionShape2D.new()
    collision_shape.name = "CollisionShape2D"

    var circle_shape := CircleShape2D.new()
    circle_shape.radius = 8.0

    collision_shape.shape = circle_shape
    add_child(collision_shape)


func _ensure_visual() -> void:
    if get_node_or_null("ProjectileVisual") != null:
        return

    var visual := Polygon2D.new()
    visual.name = "ProjectileVisual"
    visual.color = Color(0.25, 1.0, 0.35, 0.95)
    visual.polygon = PackedVector2Array([
        Vector2(10.0, 0.0),
        Vector2(2.0, -6.0),
        Vector2(-8.0, -3.0),
        Vector2(-5.0, 0.0),
        Vector2(-8.0, 3.0),
        Vector2(2.0, 6.0)
    ])
    visual.z_index = 40
    add_child(visual)


func _on_body_entered(body: Node2D) -> void:
    _try_hit_target(body)


func _on_area_entered(area: Area2D) -> void:
    if area == null:
        return

    var possible_target := area.get_parent()

    if possible_target == null:
        return

    _try_hit_target(possible_target)


func _try_hit_target(target: Node) -> void:
    if has_hit:
        return

    if target == null:
        return

    if target == caster:
        return

    if caster != null and caster.is_ancestor_of(target):
        return

    if target.is_in_group("player"):
        return

    if not target.has_method("apply_status_effect"):
        return

    has_hit = true

    var applied: bool = target.apply_status_effect(status_effect, status_duration, status_effect_data)

    if applied:
        print(spell_name, " hit ", target.name, " and applied ", status_effect)

    queue_free()

extends Area2D
class_name PlayerRangedProjectile

var caster: Node2D = null
var direction: Vector2 = Vector2.ZERO
var speed: float = 320.0
var max_range: float = 220.0
var traveled_distance: float = 0.0
var damage_amount: int = 1
var damage_types: int = DamageTypes.BASHING
var has_hit: bool = false
var projectile_color: Color = Color(0.75, 0.65, 0.45, 1.0)


func setup(
        projectile_caster: Node2D,
        cast_direction: Vector2,
        projectile_damage: int,
        projectile_damage_types: int,
        projectile_speed: float,
        projectile_range: float,
        hit_radius: float,
        visual_color: Color
) -> void:
    caster = projectile_caster
    direction = cast_direction.normalized()
    damage_amount = projectile_damage
    damage_types = projectile_damage_types
    speed = projectile_speed
    max_range = projectile_range
    projectile_color = visual_color

    if direction == Vector2.ZERO:
        direction = Vector2.DOWN

    rotation = direction.angle()
    _ensure_collision_shape(hit_radius)
    _ensure_visual()


func _ready() -> void:
    monitoring = true
    monitorable = true

    if collision_layer == 0:
        collision_layer = 0

    if collision_mask == 0:
        collision_mask = 1

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


func _ensure_collision_shape(hit_radius: float) -> void:
    var existing_collision := get_node_or_null("CollisionShape2D") as CollisionShape2D

    if existing_collision != null:
        return

    var collision_shape := CollisionShape2D.new()
    collision_shape.name = "CollisionShape2D"

    var circle_shape := CircleShape2D.new()
    circle_shape.radius = maxf(1.0, hit_radius)

    collision_shape.shape = circle_shape
    add_child(collision_shape)


func _ensure_visual() -> void:
    if get_node_or_null("ProjectileVisual") != null:
        return

    var visual := Polygon2D.new()
    visual.name = "ProjectileVisual"
    visual.color = projectile_color
    visual.polygon = PackedVector2Array([
        Vector2(6.0, 0.0),
        Vector2(0.0, -4.0),
        Vector2(-6.0, 0.0),
        Vector2(0.0, 4.0)
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

    if not target.has_method("take_damage_with_types") and not target.has_method("take_damage"):
        return

    has_hit = true

    if target.has_method("take_damage_with_types"):
        target.take_damage_with_types(damage_amount, damage_types, caster)
    elif target.has_method("take_damage"):
        target.take_damage(damage_amount)

    print("Ranged projectile hit: ", target.name, " damage: ", damage_amount)
    queue_free()

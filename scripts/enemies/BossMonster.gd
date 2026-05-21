extends Monster
class_name BossMonster

enum BossSpecialChoice {
    NONE,
    AOE,
    SLAM
}

@export_group("Boss Specials")
@export var special_attacks_enabled: bool = true
@export var special_global_cooldown: float = 1.0
@export var lock_movement_during_special: bool = true
@export var telegraph_polygon_sides: int = 48
@export var telegraph_z_index: int = 200
@export var telegraph_impact_flash_time: float = 0.12
@export var telegraph_impact_flash_color: Color = Color(1.0, 0.0, 0.0, 0.85)

@export_group("AOE Special")
@export var aoe_enabled: bool = true
@export var aoe_damage: int = 1
@export_flags(
    "Bashing",
    "Slashing",
    "Chopping",
    "Piercing",
    "Fire",
    "Ice",
    "Lightning",
    "Acid",
    "Light",
	"Shadow"
)
var aoe_damage_types: int = DamageTypes.FIRE
@export var aoe_radius: float = 72.0
@export var aoe_trigger_range: float = 160.0
@export var aoe_windup_time: float = 1.25
@export var aoe_cooldown: float = 5.0
@export var aoe_telegraph_color: Color = Color(1.0, 0.25, 0.05, 0.35)

@export_group("Slam Special")
@export var slam_enabled: bool = true
@export var slam_damage: int = 5
@export_flags(
    "Bashing",
    "Slashing",
    "Chopping",
    "Piercing",
    "Fire",
    "Ice",
    "Lightning",
    "Acid",
    "Light",
	"Shadow"
)
var slam_damage_types: int = DamageTypes.BASHING
@export var slam_length: float = 82.0
@export var slam_width: float = 36.0
@export var slam_trigger_range: float = 72.0
@export var slam_windup_time: float = 0.8
@export var slam_cooldown: float = 3.5
@export var slam_telegraph_color: Color = Color(1.0, 0.0, 0.0, 0.45)

var is_using_special_attack: bool = false
var aoe_special_timer: float = 0.0
var slam_special_timer: float = 0.0
var special_global_timer: float = 0.0

var active_telegraphs: Array[Polygon2D] = []


func _exit_tree() -> void:
    _clear_active_telegraphs()


func _physics_process(delta: float) -> void:
    if is_dead:
        return

    _update_boss_special_timers(delta)

    if is_using_special_attack:
        if lock_movement_during_special:
            velocity = Vector2.ZERO
            move_and_slide()
            _update_animation_from_velocity(Vector2.ZERO)
        return

    if special_attacks_enabled and _try_start_boss_special_attack():
        return

    super._physics_process(delta)


func die(player: Node2D = null) -> void:
    _clear_active_telegraphs()
    is_using_special_attack = false
    super.die(player)


func _update_boss_special_timers(delta: float) -> void:
    if aoe_special_timer > 0.0:
        aoe_special_timer -= delta

    if slam_special_timer > 0.0:
        slam_special_timer -= delta

    if special_global_timer > 0.0:
        special_global_timer -= delta


func _try_start_boss_special_attack() -> bool:
    if player_target == null:
        player_target = get_tree().get_first_node_in_group("player") as Node2D

    if player_target == null:
        return false

    if special_global_timer > 0.0:
        return false

    var choice: BossSpecialChoice = _choose_boss_special_attack()

    match choice:
        BossSpecialChoice.AOE:
            _start_aoe_special()
            return true

        BossSpecialChoice.SLAM:
            _start_slam_special()
            return true

        _:
            return false


func _choose_boss_special_attack() -> BossSpecialChoice:
    if player_target == null:
        return BossSpecialChoice.NONE

    var distance_to_player: float = global_position.distance_to(player_target.global_position)

    if slam_enabled and slam_special_timer <= 0.0 and distance_to_player <= slam_trigger_range:
        return BossSpecialChoice.SLAM

    if aoe_enabled and aoe_special_timer <= 0.0 and distance_to_player <= aoe_trigger_range:
        return BossSpecialChoice.AOE

    return BossSpecialChoice.NONE


func _start_aoe_special() -> void:
    if is_using_special_attack:
        return

    is_using_special_attack = true
    aoe_special_timer = aoe_cooldown
    special_global_timer = special_global_cooldown

    var attack_center: Vector2 = global_position
    var telegraph: Polygon2D = _create_circle_telegraph(attack_center, aoe_radius, aoe_telegraph_color)

    print(monster_name, " begins AOE special.")

    await get_tree().create_timer(aoe_windup_time).timeout

    if not is_inside_tree():
        _clear_active_telegraphs()
        return

    if is_dead:
        _clear_active_telegraphs()
        is_using_special_attack = false
        return

    await _flash_and_clear_telegraph(telegraph)

    if is_dead:
        is_using_special_attack = false
        return

    _damage_player_if_in_radius(attack_center, aoe_radius, aoe_damage, aoe_damage_types, "AOE")

    is_using_special_attack = false


func _start_slam_special() -> void:
    if is_using_special_attack:
        return

    is_using_special_attack = true
    slam_special_timer = slam_cooldown
    special_global_timer = special_global_cooldown

    var slam_direction: Vector2 = _get_direction_to_player()
    var slam_origin: Vector2 = global_position
    var telegraph: Polygon2D = _create_rectangle_telegraph(
        slam_origin,
        slam_direction,
        slam_length,
        slam_width,
        slam_telegraph_color
    )

    print(monster_name, " begins slam special.")

    await get_tree().create_timer(slam_windup_time).timeout

    if not is_inside_tree():
        _clear_active_telegraphs()
        return

    if is_dead:
        _clear_active_telegraphs()
        is_using_special_attack = false
        return

    await _flash_and_clear_telegraph(telegraph)

    if is_dead:
        is_using_special_attack = false
        return

    _damage_player_if_in_rectangle(
        slam_origin,
        slam_direction,
        slam_length,
        slam_width,
        slam_damage,
        slam_damage_types,
		"Slam"
    )

    is_using_special_attack = false


func _flash_and_clear_telegraph(telegraph: Polygon2D) -> void:
    if not is_instance_valid(telegraph):
        _remove_telegraph_from_active_list(telegraph)
        return

    telegraph.color = telegraph_impact_flash_color

    if telegraph_impact_flash_time > 0.0:
        await get_tree().create_timer(telegraph_impact_flash_time).timeout

    if is_instance_valid(telegraph):
        _remove_telegraph_from_active_list(telegraph)
        telegraph.queue_free()


func _clear_active_telegraphs() -> void:
    for telegraph in active_telegraphs:
        if is_instance_valid(telegraph):
            telegraph.queue_free()

    active_telegraphs.clear()


func _track_telegraph(telegraph: Polygon2D) -> void:
    if telegraph == null:
        return

    active_telegraphs.append(telegraph)


func _remove_telegraph_from_active_list(telegraph: Polygon2D) -> void:
    if telegraph == null:
        return

    for index in range(active_telegraphs.size() - 1, -1, -1):
        if active_telegraphs[index] == telegraph:
            active_telegraphs.remove_at(index)


func _get_direction_to_player() -> Vector2:
    var player := get_tree().get_first_node_in_group("player") as Node2D

    if player == null:
        match last_direction:
            "up":
                return Vector2.UP
            "down":
                return Vector2.DOWN
            "left":
                return Vector2.LEFT
            "right":
                return Vector2.RIGHT

        return Vector2.DOWN

    var direction: Vector2 = global_position.direction_to(player.global_position)

    if direction == Vector2.ZERO:
        return Vector2.DOWN

    return direction.normalized()


func _damage_player_if_in_radius(
    attack_center: Vector2,
    attack_radius: float,
    damage_amount: int,
    attack_damage_types: int,
    attack_name: String
) -> void:
    var player := get_tree().get_first_node_in_group("player") as Node2D

    if player == null:
        return

    var distance_to_player: float = attack_center.distance_to(player.global_position)

    if distance_to_player > attack_radius:
        print(monster_name, " ", attack_name, " missed player.")
        return

    _damage_player_from_special(player, damage_amount, attack_damage_types)
    print(monster_name, " ", attack_name, " hit player for base damage: ", damage_amount)


func _damage_player_if_in_rectangle(
    attack_origin: Vector2,
    attack_direction: Vector2,
    attack_length: float,
    attack_width: float,
    damage_amount: int,
    attack_damage_types: int,
    attack_name: String
) -> void:
    var player := get_tree().get_first_node_in_group("player") as Node2D

    if player == null:
        return

    var normalized_direction: Vector2 = attack_direction.normalized()
    var right_direction: Vector2 = normalized_direction.orthogonal()
    var to_player: Vector2 = player.global_position - attack_origin

    var forward_distance: float = to_player.dot(normalized_direction)
    var side_distance: float = absf(to_player.dot(right_direction))

    if forward_distance < 0.0:
        print(monster_name, " ", attack_name, " missed player.")
        return

    if forward_distance > attack_length:
        print(monster_name, " ", attack_name, " missed player.")
        return

    if side_distance > attack_width * 0.5:
        print(monster_name, " ", attack_name, " missed player.")
        return

    _damage_player_from_special(player, damage_amount, attack_damage_types)
    print(monster_name, " ", attack_name, " hit player for base damage: ", damage_amount)


func _damage_player_from_special(player: Node2D, damage_amount: int, attack_damage_types: int) -> void:
    if player == null:
        return

    if player.has_method("take_damage_with_types"):
        player.take_damage_with_types(damage_amount, attack_damage_types)
    elif player.has_method("take_damage"):
        player.take_damage(damage_amount)


func _create_circle_telegraph(center_position: Vector2, radius: float, telegraph_color: Color) -> Polygon2D:
    var telegraph := Polygon2D.new()
    telegraph.name = "BossAttackTelegraphCircle"
    telegraph.color = telegraph_color
    telegraph.polygon = _build_circle_polygon(radius, telegraph_polygon_sides)
    telegraph.global_position = center_position
    telegraph.z_index = telegraph_z_index
    telegraph.z_as_relative = false

    var current_scene := get_tree().current_scene

    if current_scene != null:
        current_scene.add_child(telegraph)
    else:
        add_child(telegraph)

    _track_telegraph(telegraph)

    return telegraph


func _create_rectangle_telegraph(
    origin_position: Vector2,
    direction: Vector2,
    length: float,
    width: float,
    telegraph_color: Color
) -> Polygon2D:
    var telegraph := Polygon2D.new()
    telegraph.name = "BossAttackTelegraphRectangle"
    telegraph.color = telegraph_color
    telegraph.polygon = _build_forward_rectangle_polygon(length, width)
    telegraph.global_position = origin_position
    telegraph.rotation = direction.angle()
    telegraph.z_index = telegraph_z_index
    telegraph.z_as_relative = false

    var current_scene := get_tree().current_scene

    if current_scene != null:
        current_scene.add_child(telegraph)
    else:
        add_child(telegraph)

    _track_telegraph(telegraph)

    return telegraph


func _build_circle_polygon(radius: float, sides: int) -> PackedVector2Array:
    var safe_sides: int = maxi(8, sides)
    var points := PackedVector2Array()

    for i in range(safe_sides):
        var angle: float = (TAU / float(safe_sides)) * float(i)
        var point: Vector2 = Vector2(cos(angle), sin(angle)) * radius
        points.append(point)

    return points


func _build_forward_rectangle_polygon(length: float, width: float) -> PackedVector2Array:
    var half_width: float = width * 0.5
    var points := PackedVector2Array()

    points.append(Vector2(0.0, -half_width))
    points.append(Vector2(length, -half_width))
    points.append(Vector2(length, half_width))
    points.append(Vector2(0.0, half_width))

    return points

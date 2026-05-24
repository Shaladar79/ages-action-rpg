extends Node
class_name MonsterSpecialAttacks

enum SpecialChoice {
    NONE,
    AOE,
    SLAM,
    BURST,
    PROJECTILE
}

var monster: Monster = null

var is_using_special_attack: bool = false
var current_special_locks_movement: bool = false

var aoe_special_timer: float = 0.0
var slam_special_timer: float = 0.0
var burst_special_timer: float = 0.0
var projectile_special_timer: float = 0.0
var special_global_timer: float = 0.0

var active_telegraphs: Array[Polygon2D] = []
var active_burst_projectiles: Array[Area2D] = []
var active_single_projectiles: Array[Area2D] = []


func setup(owner_monster: Monster) -> void:
    monster = owner_monster


func _exit_tree() -> void:
    clear_all_special_visuals()


func update_special_timers(delta: float) -> void:
    if aoe_special_timer > 0.0:
        aoe_special_timer -= delta

    if slam_special_timer > 0.0:
        slam_special_timer -= delta

    if burst_special_timer > 0.0:
        burst_special_timer -= delta

    if projectile_special_timer > 0.0:
        projectile_special_timer -= delta

    if special_global_timer > 0.0:
        special_global_timer -= delta


func is_busy() -> bool:
    return is_using_special_attack


func is_locking_movement() -> bool:
    if monster == null:
        return false

    return monster.lock_movement_during_special and current_special_locks_movement


func try_start_special_attack() -> bool:
    if monster == null:
        return false

    if not monster.special_attacks_enabled:
        return false

    if is_using_special_attack:
        return false

    if special_global_timer > 0.0:
        return false

    if monster.player_target == null:
        monster.player_target = monster.get_tree().get_first_node_in_group("player") as Node2D

    if monster.player_target == null:
        return false

    var choice := _choose_special_attack()

    match choice:
        SpecialChoice.AOE:
            _start_aoe_special()
            return true

        SpecialChoice.SLAM:
            _start_slam_special()
            return true

        SpecialChoice.BURST:
            _start_burst_special()
            return true

        SpecialChoice.PROJECTILE:
            _start_projectile_special()
            return true

        _:
            return false


func clear_all_special_visuals() -> void:
    _clear_active_telegraphs()
    _clear_active_burst_projectiles()
    _clear_active_single_projectiles()
    is_using_special_attack = false
    current_special_locks_movement = false


func _choose_special_attack() -> SpecialChoice:
    if monster == null:
        return SpecialChoice.NONE

    if monster.player_target == null:
        return SpecialChoice.NONE

    var distance_to_player: float = monster.global_position.distance_to(monster.player_target.global_position)

    if monster.slam_enabled and slam_special_timer <= 0.0 and distance_to_player <= monster.slam_trigger_range:
        return SpecialChoice.SLAM

    if monster.aoe_enabled and aoe_special_timer <= 0.0 and distance_to_player <= monster.aoe_trigger_range:
        return SpecialChoice.AOE

    if monster.burst_enabled and burst_special_timer <= 0.0 and distance_to_player <= monster.burst_trigger_range:
        return SpecialChoice.BURST

    if monster.projectile_enabled and projectile_special_timer <= 0.0 and distance_to_player <= monster.projectile_trigger_range:
        return SpecialChoice.PROJECTILE

    return SpecialChoice.NONE


func _start_aoe_special() -> void:
    if monster == null:
        return

    if is_using_special_attack:
        return

    is_using_special_attack = true
    current_special_locks_movement = monster.aoe_lock_movement
    aoe_special_timer = monster.aoe_cooldown
    special_global_timer = monster.special_global_cooldown

    _flash_monster_for_special_attack()

    var attack_center: Vector2 = monster.global_position
    var telegraph: Polygon2D = _create_circle_telegraph(
        attack_center,
        monster.aoe_radius,
        monster.aoe_telegraph_color
    )

    print(monster.monster_name, " begins AOE special.")

    await monster.get_tree().create_timer(monster.aoe_windup_time).timeout

    if not _is_monster_valid_for_special():
        _clear_active_telegraphs()
        _end_special()
        return

    await _flash_and_clear_telegraph(telegraph)

    if not _is_monster_valid_for_special():
        _end_special()
        return

    _damage_player_if_in_radius(
        attack_center,
        monster.aoe_radius,
        monster.aoe_damage,
        monster.aoe_damage_types,
        "AOE"
    )

    _end_special()


func _start_slam_special() -> void:
    if monster == null:
        return

    if is_using_special_attack:
        return

    is_using_special_attack = true
    current_special_locks_movement = monster.slam_lock_movement
    slam_special_timer = monster.slam_cooldown
    special_global_timer = monster.special_global_cooldown

    _flash_monster_for_special_attack()

    var slam_direction: Vector2 = _get_direction_to_player()
    var slam_origin: Vector2 = monster.global_position
    var telegraph: Polygon2D = _create_rectangle_telegraph(
        slam_origin,
        slam_direction,
        monster.slam_length,
        monster.slam_width,
        monster.slam_telegraph_color
    )

    print(monster.monster_name, " begins slam special.")

    await monster.get_tree().create_timer(monster.slam_windup_time).timeout

    if not _is_monster_valid_for_special():
        _clear_active_telegraphs()
        _end_special()
        return

    await _flash_and_clear_telegraph(telegraph)

    if not _is_monster_valid_for_special():
        _end_special()
        return

    _damage_player_if_in_rectangle(
        slam_origin,
        slam_direction,
        monster.slam_length,
        monster.slam_width,
        monster.slam_damage,
        monster.slam_damage_types,
        "Slam"
    )

    _end_special()


func _start_burst_special() -> void:
    if monster == null:
        return

    if is_using_special_attack:
        return

    is_using_special_attack = true
    current_special_locks_movement = monster.burst_lock_movement
    burst_special_timer = monster.burst_cooldown
    special_global_timer = monster.special_global_cooldown

    _flash_monster_for_special_attack()

    print(monster.monster_name, " begins burst special.")

    _fire_burst_cardinal_projectiles()

    if monster.burst_followup_delay > 0.0:
        await monster.get_tree().create_timer(monster.burst_followup_delay).timeout

    if not _is_monster_valid_for_special():
        _clear_active_burst_projectiles()
        _end_special()
        return

    _fire_burst_diagonal_projectiles()

    _end_special()


func _start_projectile_special() -> void:
    if monster == null:
        return

    if is_using_special_attack:
        return

    is_using_special_attack = true
    current_special_locks_movement = monster.projectile_lock_movement
    projectile_special_timer = monster.projectile_cooldown
    special_global_timer = monster.special_global_cooldown

    _flash_monster_for_special_attack()

    var projectile_direction := _get_direction_to_player()
    var projectile_origin := monster.global_position
    var telegraph: Polygon2D = null

    if monster.projectile_use_line_telegraph:
        telegraph = _create_rectangle_telegraph(
            projectile_origin,
            projectile_direction,
            monster.projectile_range,
            monster.projectile_telegraph_width,
            monster.projectile_telegraph_color
        )

    print(monster.monster_name, " begins projectile special.")

    if monster.projectile_windup_time > 0.0:
        await monster.get_tree().create_timer(monster.projectile_windup_time).timeout

    if not _is_monster_valid_for_special():
        if telegraph != null:
            _remove_telegraph_from_active_list(telegraph)
            if is_instance_valid(telegraph):
                telegraph.queue_free()

        _end_special()
        return

    if telegraph != null:
        await _flash_and_clear_telegraph(telegraph)

    if not _is_monster_valid_for_special():
        _end_special()
        return

    _spawn_single_projectile(projectile_direction)

    _end_special()


func _flash_monster_for_special_attack() -> void:
    if monster == null:
        return

    if monster.has_method("flash_for_special_attack"):
        monster.flash_for_special_attack()


func _fire_burst_cardinal_projectiles() -> void:
    _spawn_burst_projectile(Vector2.UP)
    _spawn_burst_projectile(Vector2.DOWN)
    _spawn_burst_projectile(Vector2.LEFT)
    _spawn_burst_projectile(Vector2.RIGHT)

    if monster != null:
        print(monster.monster_name, " fired cardinal burst.")


func _fire_burst_diagonal_projectiles() -> void:
    _spawn_burst_projectile(Vector2(-1.0, -1.0).normalized())
    _spawn_burst_projectile(Vector2(1.0, -1.0).normalized())
    _spawn_burst_projectile(Vector2(-1.0, 1.0).normalized())
    _spawn_burst_projectile(Vector2(1.0, 1.0).normalized())

    if monster != null:
        print(monster.monster_name, " fired diagonal burst.")


func _spawn_burst_projectile(direction: Vector2) -> void:
    if monster == null:
        return

    if direction == Vector2.ZERO:
        return

    var normalized_direction := direction.normalized()

    var projectile := Area2D.new()
    projectile.name = "BossBurstProjectile"
    projectile.global_position = monster.global_position + (normalized_direction * monster.burst_projectile_spawn_offset)
    projectile.rotation = normalized_direction.angle()
    projectile.z_index = monster.burst_projectile_z_index
    projectile.z_as_relative = false
    projectile.monitoring = true
    projectile.monitorable = true
    projectile.collision_layer = monster.burst_projectile_collision_layer
    projectile.collision_mask = monster.burst_projectile_collision_mask
    projectile.set_meta("has_hit_player", false)

    var collision_shape := CollisionShape2D.new()
    var circle_shape := CircleShape2D.new()
    circle_shape.radius = monster.burst_projectile_hit_radius
    collision_shape.shape = circle_shape
    projectile.add_child(collision_shape)

    if monster.burst_projectile_texture != null:
        var sprite := Sprite2D.new()
        sprite.name = "ProjectileSprite"
        sprite.texture = monster.burst_projectile_texture
        sprite.scale = monster.burst_projectile_scale
        sprite.z_index = monster.burst_projectile_z_index
        projectile.add_child(sprite)
    else:
        var polygon := Polygon2D.new()
        polygon.name = "ProjectileFallbackPolygon"
        polygon.color = monster.burst_projectile_color
        polygon.polygon = PackedVector2Array([
            Vector2(10.0, 0.0),
            Vector2(0.0, -5.0),
            Vector2(-10.0, 0.0),
            Vector2(0.0, 5.0)
        ])
        polygon.z_index = monster.burst_projectile_z_index
        projectile.add_child(polygon)

    var current_scene := monster.get_tree().current_scene

    if current_scene != null:
        current_scene.add_child(projectile)
    else:
        monster.add_child(projectile)

    active_burst_projectiles.append(projectile)

    projectile.body_entered.connect(_on_burst_projectile_body_entered.bind(projectile))

    var end_position := projectile.global_position + (normalized_direction * monster.burst_projectile_range)
    var travel_time := 0.8

    if monster.burst_projectile_speed > 0.0:
        travel_time = monster.burst_projectile_range / monster.burst_projectile_speed

    travel_time = maxf(0.05, travel_time)

    var tween := projectile.create_tween()
    tween.tween_property(projectile, "global_position", end_position, travel_time)
    tween.finished.connect(_on_burst_projectile_finished.bind(projectile))


func _spawn_single_projectile(direction: Vector2) -> void:
    if monster == null:
        return

    if direction == Vector2.ZERO:
        return

    var normalized_direction := direction.normalized()

    var projectile := Area2D.new()
    projectile.name = "MonsterProjectileSpecial"
    projectile.global_position = monster.global_position + (normalized_direction * monster.projectile_spawn_offset)
    projectile.rotation = normalized_direction.angle()
    projectile.z_index = monster.projectile_z_index
    projectile.z_as_relative = false
    projectile.monitoring = true
    projectile.monitorable = true
    projectile.collision_layer = monster.projectile_collision_layer
    projectile.collision_mask = monster.projectile_collision_mask
    projectile.set_meta("has_hit_player", false)

    var collision_shape := CollisionShape2D.new()
    var circle_shape := CircleShape2D.new()
    circle_shape.radius = monster.projectile_hit_radius
    collision_shape.shape = circle_shape
    projectile.add_child(collision_shape)

    if monster.projectile_texture != null:
        var sprite := Sprite2D.new()
        sprite.name = "ProjectileSprite"
        sprite.texture = monster.projectile_texture
        sprite.scale = monster.projectile_scale
        sprite.z_index = monster.projectile_z_index
        projectile.add_child(sprite)
    else:
        var polygon := Polygon2D.new()
        polygon.name = "ProjectileFallbackPolygon"
        polygon.color = monster.projectile_color
        polygon.polygon = PackedVector2Array([
            Vector2(8.0, 0.0),
            Vector2(0.0, -4.0),
            Vector2(-8.0, 0.0),
            Vector2(0.0, 4.0)
        ])
        polygon.z_index = monster.projectile_z_index
        projectile.add_child(polygon)

    var current_scene := monster.get_tree().current_scene

    if current_scene != null:
        current_scene.add_child(projectile)
    else:
        monster.add_child(projectile)

    active_single_projectiles.append(projectile)

    projectile.body_entered.connect(_on_single_projectile_body_entered.bind(projectile))
    projectile.area_entered.connect(_on_single_projectile_area_entered.bind(projectile))

    var end_position := projectile.global_position + (normalized_direction * monster.projectile_range)
    var travel_time := 0.8

    if monster.projectile_speed > 0.0:
        travel_time = monster.projectile_range / monster.projectile_speed

    travel_time = maxf(0.05, travel_time)

    var tween := projectile.create_tween()
    tween.tween_property(projectile, "global_position", end_position, travel_time)
    tween.finished.connect(_on_single_projectile_finished.bind(projectile))

    print(monster.monster_name, " fired projectile special.")


func _on_burst_projectile_body_entered(body: Node2D, projectile: Area2D) -> void:
    if monster == null:
        return

    if projectile == null:
        return

    if not is_instance_valid(projectile):
        return

    if bool(projectile.get_meta("has_hit_player", false)):
        return

    if body == null:
        return

    if not body.is_in_group("player"):
        return

    projectile.set_meta("has_hit_player", true)

    _damage_player_from_special(body, monster.burst_damage, monster.burst_damage_types)

    print(monster.monster_name, " burst projectile hit player for base damage: ", monster.burst_damage)

    _remove_burst_projectile_from_active_list(projectile)
    projectile.queue_free()


func _on_single_projectile_body_entered(body: Node2D, projectile: Area2D) -> void:
    if monster == null:
        return

    if projectile == null:
        return

    if not is_instance_valid(projectile):
        return

    if bool(projectile.get_meta("has_hit_player", false)):
        return

    if body == null:
        return

    if not body.is_in_group("player"):
        return

    projectile.set_meta("has_hit_player", true)

    _damage_player_from_special(body, monster.projectile_damage, monster.projectile_damage_types)

    print(monster.monster_name, " projectile special hit player for base damage: ", monster.projectile_damage)

    _remove_single_projectile_from_active_list(projectile)
    projectile.queue_free()


func _on_single_projectile_area_entered(area: Area2D, projectile: Area2D) -> void:
    if monster == null:
        return

    if projectile == null:
        return

    if not is_instance_valid(projectile):
        return

    if bool(projectile.get_meta("has_hit_player", false)):
        return

    if area == null:
        return

    var possible_player := area.get_parent()

    if possible_player == null:
        return

    if not possible_player.is_in_group("player"):
        return

    projectile.set_meta("has_hit_player", true)

    _damage_player_from_special(possible_player, monster.projectile_damage, monster.projectile_damage_types)

    print(monster.monster_name, " projectile special hit player hurtbox for base damage: ", monster.projectile_damage)

    _remove_single_projectile_from_active_list(projectile)
    projectile.queue_free()


func _on_burst_projectile_finished(projectile: Area2D) -> void:
    if projectile == null:
        return

    if not is_instance_valid(projectile):
        _remove_burst_projectile_from_active_list(projectile)
        return

    _remove_burst_projectile_from_active_list(projectile)
    projectile.queue_free()


func _on_single_projectile_finished(projectile: Area2D) -> void:
    if projectile == null:
        return

    if not is_instance_valid(projectile):
        _remove_single_projectile_from_active_list(projectile)
        return

    _remove_single_projectile_from_active_list(projectile)
    projectile.queue_free()


func _damage_player_if_in_radius(
    attack_center: Vector2,
    attack_radius: float,
    damage_amount: int,
    attack_damage_types: int,
    attack_name: String
) -> void:
    if monster == null:
        return

    var player := monster.get_tree().get_first_node_in_group("player") as Node2D

    if player == null:
        return

    var distance_to_player: float = attack_center.distance_to(player.global_position)

    if distance_to_player > attack_radius:
        print(monster.monster_name, " ", attack_name, " missed player.")
        return

    _damage_player_from_special(player, damage_amount, attack_damage_types)
    print(monster.monster_name, " ", attack_name, " hit player for base damage: ", damage_amount)


func _damage_player_if_in_rectangle(
    attack_origin: Vector2,
    attack_direction: Vector2,
    attack_length: float,
    attack_width: float,
    damage_amount: int,
    attack_damage_types: int,
    attack_name: String
) -> void:
    if monster == null:
        return

    var player := monster.get_tree().get_first_node_in_group("player") as Node2D

    if player == null:
        return

    var normalized_direction: Vector2 = attack_direction.normalized()
    var right_direction: Vector2 = normalized_direction.orthogonal()
    var to_player: Vector2 = player.global_position - attack_origin

    var forward_distance: float = to_player.dot(normalized_direction)
    var side_distance: float = absf(to_player.dot(right_direction))

    if forward_distance < 0.0:
        print(monster.monster_name, " ", attack_name, " missed player.")
        return

    if forward_distance > attack_length:
        print(monster.monster_name, " ", attack_name, " missed player.")
        return

    if side_distance > attack_width * 0.5:
        print(monster.monster_name, " ", attack_name, " missed player.")
        return

    _damage_player_from_special(player, damage_amount, attack_damage_types)
    print(monster.monster_name, " ", attack_name, " hit player for base damage: ", damage_amount)


func _damage_player_from_special(player: Node2D, damage_amount: int, attack_damage_types: int) -> void:
    if player == null:
        return

    if player.has_method("take_damage_with_types"):
        player.take_damage_with_types(damage_amount, attack_damage_types)
    elif player.has_method("take_damage"):
        player.take_damage(damage_amount)


func _get_direction_to_player() -> Vector2:
    if monster == null:
        return Vector2.DOWN

    var player := monster.get_tree().get_first_node_in_group("player") as Node2D

    if player == null:
        match monster.last_direction:
            "up":
                return Vector2.UP
            "down":
                return Vector2.DOWN
            "left":
                return Vector2.LEFT
            "right":
                return Vector2.RIGHT

        return Vector2.DOWN

    var direction: Vector2 = monster.global_position.direction_to(player.global_position)

    if direction == Vector2.ZERO:
        return Vector2.DOWN

    return direction.normalized()


func _create_circle_telegraph(center_position: Vector2, radius: float, telegraph_color: Color) -> Polygon2D:
    var telegraph := Polygon2D.new()
    telegraph.name = "BossAttackTelegraphCircle"
    telegraph.color = telegraph_color
    telegraph.polygon = _build_circle_polygon(radius, monster.telegraph_polygon_sides)
    telegraph.global_position = center_position
    telegraph.z_index = monster.telegraph_z_index
    telegraph.z_as_relative = false

    var current_scene := monster.get_tree().current_scene

    if current_scene != null:
        current_scene.add_child(telegraph)
    else:
        monster.add_child(telegraph)

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
    telegraph.z_index = monster.telegraph_z_index
    telegraph.z_as_relative = false

    var current_scene := monster.get_tree().current_scene

    if current_scene != null:
        current_scene.add_child(telegraph)
    else:
        monster.add_child(telegraph)

    _track_telegraph(telegraph)

    return telegraph


func _flash_and_clear_telegraph(telegraph: Polygon2D) -> void:
    if not is_instance_valid(telegraph):
        _remove_telegraph_from_active_list(telegraph)
        return

    telegraph.color = monster.telegraph_impact_flash_color

    if monster.telegraph_impact_flash_time > 0.0:
        await monster.get_tree().create_timer(monster.telegraph_impact_flash_time).timeout

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


func _clear_active_burst_projectiles() -> void:
    for projectile in active_burst_projectiles:
        if is_instance_valid(projectile):
            projectile.queue_free()

    active_burst_projectiles.clear()


func _remove_burst_projectile_from_active_list(projectile: Area2D) -> void:
    if projectile == null:
        return

    for index in range(active_burst_projectiles.size() - 1, -1, -1):
        if active_burst_projectiles[index] == projectile:
            active_burst_projectiles.remove_at(index)


func _clear_active_single_projectiles() -> void:
    for projectile in active_single_projectiles:
        if is_instance_valid(projectile):
            projectile.queue_free()

    active_single_projectiles.clear()


func _remove_single_projectile_from_active_list(projectile: Area2D) -> void:
    if projectile == null:
        return

    for index in range(active_single_projectiles.size() - 1, -1, -1):
        if active_single_projectiles[index] == projectile:
            active_single_projectiles.remove_at(index)


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


func _is_monster_valid_for_special() -> bool:
    if monster == null:
        return false

    if not monster.is_inside_tree():
        return false

    if monster.is_dead:
        return false

    return true


func _end_special() -> void:
    is_using_special_attack = false
    current_special_locks_movement = false

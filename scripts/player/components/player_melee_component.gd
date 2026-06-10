extends RefCounted
class_name PlayerMeleeComponent

var player: Node = null


func setup(owner_player: Node) -> void:
    player = owner_player


func try_attack() -> void:
    if player == null:
        return

    if bool(player.get("is_defeated")):
        return

    if player.has_method("is_dialogue_active"):
        if player.is_dialogue_active():
            return

    if bool(player.get("is_attacking")):
        return

    if float(player.get("cooldown_timer")) > 0.0:
        return

    player.set("is_attacking", true)
    player.set("attack_damage_timer", float(player.get("attack_damage_window")))
    player.set("weapon_visual_timer", float(player.get("weapon_visual_duration")))

    var attack_cooldown := 0.5

    if player.has_method("get_current_attack_cooldown"):
        attack_cooldown = player.get_current_attack_cooldown()

    player.set("cooldown_timer", attack_cooldown)

    var hit_targets: Array = player.get("hit_targets")
    hit_targets.clear()
    player.set("hit_targets", hit_targets)

    position_attack_area()
    show_weapon_sprite_for_attack()
    enable_attack_hitbox()

    print("Player attack: ", str(player.get("last_direction")))

    var attack_area: Area2D = player.get("attack_area") as Area2D

    if attack_area != null:
        print("AttackArea position: ", attack_area.position)


func update_attack_timers(delta: float) -> void:
    if player == null:
        return

    var cooldown_timer: float = float(player.get("cooldown_timer"))
    var attack_damage_timer: float = float(player.get("attack_damage_timer"))
    var weapon_visual_timer: float = float(player.get("weapon_visual_timer"))

    if cooldown_timer > 0.0:
        cooldown_timer -= delta
        cooldown_timer = maxf(cooldown_timer, 0.0)

    if attack_damage_timer > 0.0:
        attack_damage_timer -= delta

        if attack_damage_timer <= 0.0:
            attack_damage_timer = 0.0
            disable_attack_hitbox()

    if weapon_visual_timer > 0.0:
        weapon_visual_timer -= delta

        if weapon_visual_timer <= 0.0:
            weapon_visual_timer = 0.0
            hide_weapon_sprite()

    player.set("cooldown_timer", cooldown_timer)
    player.set("attack_damage_timer", attack_damage_timer)
    player.set("weapon_visual_timer", weapon_visual_timer)

    if attack_damage_timer <= 0.0 and weapon_visual_timer <= 0.0:
        player.set("is_attacking", false)


func position_attack_area() -> void:
    if player == null:
        return

    var attack_area: Area2D = player.get("attack_area") as Area2D
    var attack_collision: CollisionShape2D = player.get("attack_collision") as CollisionShape2D

    if attack_area == null:
        return

    var last_direction: String = str(player.get("last_direction"))
    var half_extents := _get_attack_collision_half_extents(attack_collision)

    # This pushes the attack box away from Gene so it does not sit on top of him.
    var body_edge_padding := 4.0

    if attack_collision != null:
        attack_collision.position = Vector2.ZERO

    match last_direction:
        "down":
            if attack_collision != null:
                attack_collision.rotation_degrees = 0.0

            attack_area.position = Vector2(0, half_extents.y + body_edge_padding)

        "up":
            if attack_collision != null:
                attack_collision.rotation_degrees = 0.0

            attack_area.position = Vector2(0, -(half_extents.y + body_edge_padding))

        "left":
            if attack_collision != null:
                attack_collision.rotation_degrees = 90.0

            attack_area.position = Vector2(-(half_extents.y + body_edge_padding), 0)

        "right":
            if attack_collision != null:
                attack_collision.rotation_degrees = 90.0

            attack_area.position = Vector2(half_extents.y + body_edge_padding, 0)

        _:
            if attack_collision != null:
                attack_collision.rotation_degrees = 0.0

            attack_area.position = Vector2(0, half_extents.y + body_edge_padding)

func _get_attack_collision_half_extents(attack_collision: CollisionShape2D) -> Vector2:
    if attack_collision == null:
        return Vector2(12.0, 12.0)

    if attack_collision.shape == null:
        return Vector2(12.0, 12.0)

    if attack_collision.shape is RectangleShape2D:
        var rectangle_shape := attack_collision.shape as RectangleShape2D
        return rectangle_shape.size * 0.5

    if attack_collision.shape is CircleShape2D:
        var circle_shape := attack_collision.shape as CircleShape2D
        return Vector2(circle_shape.radius, circle_shape.radius)

    if attack_collision.shape is CapsuleShape2D:
        var capsule_shape := attack_collision.shape as CapsuleShape2D
        return Vector2(capsule_shape.radius, capsule_shape.height * 0.5)

    return Vector2(12.0, 12.0)

func show_weapon_sprite_for_attack() -> void:
    if player == null:
        return

    var weapon_sprite: Sprite2D = player.get("weapon_sprite") as Sprite2D

    if weapon_sprite == null:
        return

    # Temporary first-pass behavior:
    # Do not show a weapon image until we have real equipped weapon sprites.
    # The melee hitbox still turns on through enable_attack_hitbox().
    hide_weapon_sprite()

func _get_equipped_melee_weapon_id() -> String:
    if player == null:
        return ""

    if player.has_method("get_character_stats"):
        var stats = player.get_character_stats()

        if stats != null:
            return str(stats.equipped_melee_weapon_id).strip_edges()

    return ""


func _apply_equipped_weapon_attack_texture(weapon_sprite: Sprite2D, equipped_weapon_id: String) -> void:
    if weapon_sprite == null:
        return

    var texture_path := ItemDatabase.get_weapon_attack_visual_texture_path(equipped_weapon_id)

    if texture_path.strip_edges() == "":
        return

    if not ResourceLoader.exists(texture_path):
        push_warning("Weapon attack visual texture path does not exist: " + texture_path)
        return

    var loaded_texture := load(texture_path) as Texture2D

    if loaded_texture == null:
        push_warning("Weapon attack visual texture failed to load: " + texture_path)
        return

    weapon_sprite.texture = loaded_texture


func _position_weapon_sprite_swing(weapon_sprite: Sprite2D, weapon_visual_offset: float) -> void:
    var last_direction: String = str(player.get("last_direction"))

    match last_direction:
        "down":
            weapon_sprite.position = Vector2(0, weapon_visual_offset)
            weapon_sprite.rotation_degrees = 180.0
            weapon_sprite.z_index = 10
        "up":
            weapon_sprite.position = Vector2(0, -weapon_visual_offset)
            weapon_sprite.rotation_degrees = 0.0
            weapon_sprite.z_index = -1
        "left":
            weapon_sprite.position = Vector2(-weapon_visual_offset, 0)
            weapon_sprite.rotation_degrees = -90.0
            weapon_sprite.z_index = 10
        "right":
            weapon_sprite.position = Vector2(weapon_visual_offset, 0)
            weapon_sprite.rotation_degrees = 90.0
            weapon_sprite.z_index = 10


func _position_weapon_sprite_thrust(weapon_sprite: Sprite2D, weapon_visual_offset: float) -> void:
    var last_direction: String = str(player.get("last_direction"))

    match last_direction:
        "down":
            weapon_sprite.position = Vector2(0, weapon_visual_offset)
            weapon_sprite.rotation_degrees = 180.0
            weapon_sprite.z_index = 10
        "up":
            weapon_sprite.position = Vector2(0, -weapon_visual_offset)
            weapon_sprite.rotation_degrees = 0.0
            weapon_sprite.z_index = -1
        "left":
            weapon_sprite.position = Vector2(-weapon_visual_offset, 0)
            weapon_sprite.rotation_degrees = -90.0
            weapon_sprite.z_index = 10
        "right":
            weapon_sprite.position = Vector2(weapon_visual_offset, 0)
            weapon_sprite.rotation_degrees = 90.0
            weapon_sprite.z_index = 10


func _position_weapon_sprite_raise(weapon_sprite: Sprite2D, weapon_visual_offset: float) -> void:
    var last_direction: String = str(player.get("last_direction"))

    match last_direction:
        "down":
            weapon_sprite.position = Vector2(0, weapon_visual_offset * 0.5)
            weapon_sprite.rotation_degrees = 0.0
            weapon_sprite.z_index = 10
        "up":
            weapon_sprite.position = Vector2(0, -weapon_visual_offset)
            weapon_sprite.rotation_degrees = 0.0
            weapon_sprite.z_index = 10
        "left":
            weapon_sprite.position = Vector2(-weapon_visual_offset * 0.75, -weapon_visual_offset * 0.5)
            weapon_sprite.rotation_degrees = 0.0
            weapon_sprite.z_index = 10
        "right":
            weapon_sprite.position = Vector2(weapon_visual_offset * 0.75, -weapon_visual_offset * 0.5)
            weapon_sprite.rotation_degrees = 0.0
            weapon_sprite.z_index = 10

func hide_weapon_sprite() -> void:
    if player == null:
        return

    var weapon_sprite: Sprite2D = player.get("weapon_sprite") as Sprite2D

    if weapon_sprite == null:
        return

    weapon_sprite.visible = false


func enable_attack_hitbox() -> void:
    if player == null:
        return

    var attack_area: Area2D = player.get("attack_area") as Area2D
    var attack_collision: CollisionShape2D = player.get("attack_collision") as CollisionShape2D

    if attack_area != null:
        attack_area.monitoring = true
        attack_area.monitorable = true
        attack_area.visible = true
        _show_debug_attack_visual(attack_area, attack_collision)

    if attack_collision != null:
        attack_collision.disabled = false


func disable_attack_hitbox() -> void:
    if player == null:
        return

    var attack_area: Area2D = player.get("attack_area") as Area2D
    var attack_collision: CollisionShape2D = player.get("attack_collision") as CollisionShape2D

    if attack_area != null:
        attack_area.monitoring = false
        attack_area.monitorable = false
        attack_area.visible = false
        _hide_debug_attack_visual(attack_area)

    if attack_collision != null:
        attack_collision.disabled = true

func _show_debug_attack_visual(attack_area: Area2D, attack_collision: CollisionShape2D) -> void:
    if attack_area == null:
        return

    var debug_visual := attack_area.get_node_or_null("AttackDebugVisual") as Polygon2D

    if debug_visual == null:
       debug_visual = Polygon2D.new()
       debug_visual.name = "AttackDebugVisual"
       debug_visual.z_index = 100
       attack_area.add_child(debug_visual)

       debug_visual.color = Color(0.65, 0.0, 1.0, 0.35)

    var debug_size := Vector2(24, 24)
    var debug_position := Vector2.ZERO
    var debug_rotation := 0.0

    if attack_collision != null:
        debug_position = attack_collision.position
        debug_rotation = attack_collision.rotation

        if attack_collision.shape != null:
            if attack_collision.shape is RectangleShape2D:
                var rectangle_shape := attack_collision.shape as RectangleShape2D
                debug_size = rectangle_shape.size
            elif attack_collision.shape is CircleShape2D:
                var circle_shape := attack_collision.shape as CircleShape2D
                debug_size = Vector2(circle_shape.radius * 2.0, circle_shape.radius * 2.0)
            elif attack_collision.shape is CapsuleShape2D:
                var capsule_shape := attack_collision.shape as CapsuleShape2D
                debug_size = Vector2(capsule_shape.radius * 2.0, capsule_shape.height)

    var half_size := debug_size * 0.5

    debug_visual.polygon = PackedVector2Array([
        Vector2(-half_size.x, -half_size.y),
        Vector2(half_size.x, -half_size.y),
        Vector2(half_size.x, half_size.y),
        Vector2(-half_size.x, half_size.y)
    ])

    debug_visual.position = debug_position
    debug_visual.rotation = debug_rotation
    debug_visual.visible = true


func _hide_debug_attack_visual(attack_area: Area2D) -> void:
    if attack_area == null:
        return

    var debug_visual := attack_area.get_node_or_null("AttackDebugVisual") as Polygon2D

    if debug_visual == null:
        return

    debug_visual.visible = false

func on_attack_area_entered(area: Area2D) -> void:
    if area == null:
        return

    print("AttackArea entered area: ", area.name)
    damage_area_target(area)


func check_attack_overlaps() -> void:
    if player == null:
        return

    var attack_area: Area2D = player.get("attack_area") as Area2D

    if attack_area == null:
        return

    var overlapping_areas := attack_area.get_overlapping_areas()

    for area in overlapping_areas:
        print("AttackArea overlapping: ", area.name)
        damage_area_target(area)


func damage_area_target(area: Area2D) -> void:
    if player == null:
        return

    if bool(player.get("is_defeated")):
        return

    if float(player.get("attack_damage_timer")) <= 0.0:
        return

    if area == null:
        return

    var target := area.get_parent()

    if target == null:
        return

    if target == player:
        return

    if target.is_in_group("player"):
        return

    if player.is_ancestor_of(target):
        return

    var hit_targets: Array = player.get("hit_targets")

    if hit_targets.has(target):
        return

    var attack_damage := 1

    if player.has_method("get_attack_damage"):
        attack_damage = player.get_attack_damage()

    if target.has_method("take_damage_from_player"):
        hit_targets.append(target)
        player.set("hit_targets", hit_targets)

        target.take_damage_from_player(attack_damage, player)
        print("Hit target with player-aware damage: ", target.name)
        return

    if target.has_method("take_damage"):
        hit_targets.append(target)
        player.set("hit_targets", hit_targets)

        target.take_damage(attack_damage)
        print("Hit target: ", target.name)

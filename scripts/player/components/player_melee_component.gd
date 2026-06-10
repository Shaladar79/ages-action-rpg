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

    if attack_area == null:
        return

    var attack_offset: float = float(player.get("attack_offset"))
    var last_direction: String = str(player.get("last_direction"))

    match last_direction:
        "down":
            attack_area.position = Vector2(0, attack_offset)
        "up":
            attack_area.position = Vector2(0, -attack_offset)
        "left":
            attack_area.position = Vector2(-attack_offset, 0)
        "right":
            attack_area.position = Vector2(attack_offset, 0)


func show_weapon_sprite_for_attack() -> void:
    if player == null:
        return

    var weapon_sprite: Sprite2D = player.get("weapon_sprite") as Sprite2D

    if weapon_sprite == null:
        return

    if player.has_method("has_equipped_weapon"):
        if not player.has_equipped_weapon():
            hide_weapon_sprite()
            return

    weapon_sprite.visible = true
    weapon_sprite.scale = player.get("weapon_visual_scale")
    weapon_sprite.flip_h = false
    weapon_sprite.flip_v = false

    var weapon_visual_offset: float = float(player.get("weapon_visual_offset"))
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

    if attack_collision != null:
        attack_collision.disabled = true


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

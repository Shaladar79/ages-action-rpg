extends RefCounted
class_name PlayerRangedComponent

var player: Node = null


func setup(owner_player: Node) -> void:
    player = owner_player


func try_ranged_attack() -> void:
    if player == null:
        return

    if bool(player.get("is_defeated")):
        return

    if player.has_method("is_dialogue_active"):
        if player.is_dialogue_active():
            return

    if bool(player.get("is_attacking")):
        return

    var cooldown_timer: float = float(player.get("cooldown_timer"))

    if cooldown_timer > 0.0:
        return

    var character_stats: CharacterStats = player.get("character_stats")

    if character_stats == null:
        return

    if character_stats.equipped_ranged_weapon_id.strip_edges() == "":
        print("No ranged weapon equipped.")
        return

    var ranged_weapon_id := character_stats.equipped_ranged_weapon_id

    if ItemDatabase.weapon_requires_ammo(ranged_weapon_id):
        var ammo_item_id := ItemDatabase.get_weapon_ammo_item_id(ranged_weapon_id)
        var ammo_per_shot := ItemDatabase.get_weapon_ammo_per_shot(ranged_weapon_id)

        if ammo_item_id.strip_edges() == "":
            print("Ranged weapon requires ammo but has no ammo item id: ", ranged_weapon_id)
            return

        if not has_inventory_quantity(ammo_item_id, ammo_per_shot):
            print("No ammo for ranged weapon. Need: ", ItemDatabase.get_item_name(ammo_item_id))
            return

        if not player.has_method("remove_inventory_item"):
            print("Player has no remove_inventory_item method.")
            return

        var removed_ammo: bool = player.remove_inventory_item(ammo_item_id, ammo_per_shot)

        if not removed_ammo:
            print("Failed to remove ammo for ranged weapon.")
            return

    fire_ranged_weapon_projectile(ranged_weapon_id)

    player.set("cooldown_timer", float(player.get("ranged_attack_cooldown")))

    print("Player fired ranged weapon: ", ItemDatabase.get_item_name(ranged_weapon_id))


func fire_ranged_weapon_projectile(ranged_weapon_id: String) -> void:
    if player == null:
        return

    var cast_direction := Vector2.DOWN

    if player.has_method("_get_last_direction_vector"):
        cast_direction = player._get_last_direction_vector()

    if cast_direction == Vector2.ZERO:
        cast_direction = Vector2.DOWN

    var projectile := PlayerRangedProjectile.new()
    projectile.name = "PlayerRangedProjectile"

    var spawn_offset := ItemDatabase.get_weapon_projectile_spawn_offset(ranged_weapon_id)
    projectile.global_position = player.global_position + (cast_direction.normalized() * spawn_offset)
    projectile.collision_layer = int(player.get("ranged_projectile_collision_layer"))
    projectile.collision_mask = int(player.get("ranged_projectile_collision_mask"))

    var character_stats: CharacterStats = player.get("character_stats")

    if character_stats == null:
        return

    var ranged_damage := 1

    if player.has_method("get_ranged_attack_damage"):
        ranged_damage = player.get_ranged_attack_damage()

    projectile.setup(
        player,
        cast_direction,
        ranged_damage,
        character_stats.get_equipped_ranged_weapon_damage_types(),
        ItemDatabase.get_weapon_projectile_speed(ranged_weapon_id),
        ItemDatabase.get_weapon_projectile_range(ranged_weapon_id),
        ItemDatabase.get_weapon_projectile_hit_radius(ranged_weapon_id),
        ItemDatabase.get_weapon_projectile_color(ranged_weapon_id)
    )

    var current_scene := player.get_tree().current_scene

    if current_scene != null:
        current_scene.add_child(projectile)
    else:
        player.get_parent().add_child(projectile)


func has_inventory_quantity(item_id: String, required_quantity: int) -> bool:
    if player == null:
        return false

    var inventory_component = player.get("inventory_component")

    if inventory_component == null:
        return false

    return inventory_component.has_inventory_quantity(item_id, required_quantity)

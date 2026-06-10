extends RefCounted
class_name PlayerMagicComponent

var player: Node = null


func setup(owner_player: Node) -> void:
    player = owner_player


func record_spell_school_mastery_cast(item_id: String) -> void:
    var spell_school := ItemDatabase.get_spell_school(item_id).strip_edges()

    if spell_school == "":
        return

    if MasteryManager == null:
        return

    if not MasteryManager.has_method("add_school_cast"):
        return

    var added := MasteryManager.add_school_cast(spell_school, 1)

    if added:
        print("School mastery cast added: ", spell_school)


func cast_self_buff_spell(item_id: String, status_effect: String, status_duration: float) -> void:
    if player == null:
        return

    var status_effect_data := {
        StatusEffects.KEY_MOVE_SPEED_MULTIPLIER: ItemDatabase.get_spell_move_speed_multiplier(item_id)
    }

    if status_effect == StatusEffects.STATUS_ROCK_SKIN:
        status_effect_data[StatusEffects.KEY_DEFENSE_BONUS] = ItemDatabase.get_spell_defense_bonus(item_id)

    if status_effect == StatusEffects.STATUS_BURNING:
        status_effect_data[StatusEffects.KEY_DAMAGE_PER_TICK] = ItemDatabase.get_spell_status_damage_per_tick(item_id)
        status_effect_data[StatusEffects.KEY_DAMAGE_TICK_INTERVAL] = ItemDatabase.get_spell_status_tick_interval(item_id)
        status_effect_data[StatusEffects.KEY_DAMAGE_TYPES] = ItemDatabase.get_spell_damage_types(item_id)
        status_effect_data[StatusEffects.KEY_IGNORE_DEFENSE] = true

    if player.has_method("apply_status_effect"):
        player.apply_status_effect(status_effect, status_duration, status_effect_data)

    print(
        "Self-cast spell applied: ",
        ItemDatabase.get_spell_name(item_id),
        " status: ",
        status_effect,
        " duration: ",
        status_duration
    )


func spawn_spell_projectile(
        item_id: String,
        cast_direction: Vector2,
        spell_range: float,
        status_effect: String,
        status_duration: float
) -> void:
    if player == null:
        return

    var projectile := PlayerSpellProjectile.new()
    projectile.name = "PlayerSpellProjectile"

    var spell_projectile_spawn_offset: float = float(player.get("spell_projectile_spawn_offset"))
    var spawn_position: Vector2 = player.global_position + (cast_direction.normalized() * spell_projectile_spawn_offset)

    projectile.global_position = spawn_position
    projectile.speed = float(player.get("spell_projectile_speed"))
    projectile.collision_layer = int(player.get("spell_projectile_collision_layer"))
    projectile.collision_mask = int(player.get("spell_projectile_collision_mask"))

    var status_effect_data := {
        StatusEffects.KEY_MOVE_SPEED_MULTIPLIER: ItemDatabase.get_spell_move_speed_multiplier(item_id)
    }

    if status_effect == StatusEffects.STATUS_BURNING:
        status_effect_data[StatusEffects.KEY_DAMAGE_PER_TICK] = ItemDatabase.get_spell_status_damage_per_tick(item_id)
        status_effect_data[StatusEffects.KEY_DAMAGE_TICK_INTERVAL] = ItemDatabase.get_spell_status_tick_interval(item_id)
        status_effect_data[StatusEffects.KEY_DAMAGE_TYPES] = ItemDatabase.get_spell_damage_types(item_id)
        status_effect_data[StatusEffects.KEY_IGNORE_DEFENSE] = true

    projectile.setup(
        player,
        cast_direction,
        item_id,
        spell_range,
        status_effect,
        status_duration,
        status_effect_data,
        ItemDatabase.get_spell_damage(item_id),
        ItemDatabase.get_spell_damage_types(item_id)
    )

    var current_scene := player.get_tree().current_scene

    if current_scene != null:
        current_scene.add_child(projectile)
    else:
        player.get_parent().add_child(projectile)


func restore_player_mana(mana_amount: int) -> bool:
    if player == null:
        return false

    if mana_amount <= 0:
        return false

    var character_stats: CharacterStats = player.get("character_stats")

    if character_stats == null:
        return false

    var restored: bool = character_stats.restore_mana(mana_amount)

    if restored:
        if player.has_method("_notify_ui_stats_changed"):
            player._notify_ui_stats_changed()

    return restored

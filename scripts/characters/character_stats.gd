extends RefCounted
class_name CharacterStats

const STARTING_HEALTH_BASE: int = 15
const HEALTH_PER_TOUGHNESS: int = 10

const DEFAULT_SPEED_STAT: int = 10
const DEFAULT_ATTACK_SPEED_BONUS_PER_AGILITY: float = 0.01

var character_name: String = "Gene Ambrose"

var level: int = 0
var xp: int = 0
var xp_to_next_level: int = 3

var stat_points: int = 0
var ability_points: int = 0

var max_health: int = 0
var current_health: int = 0

var has_mana_resource: bool = false
var max_mana: int = 0
var current_mana: int = 0

var has_stamina_resource: bool = false
var max_stamina: int = 0
var current_stamina: int = 0

var might: int = 1
var agility: int = 1
var toughness: int = 1
var endurance: int = 1
var focus: int = 1
var speed: int = DEFAULT_SPEED_STAT

var base_attack: int = 0
var base_defense: int = 0

var equipped_melee_weapon_id: String = ""
var equipped_melee_weapon_name: String = "None"

var equipped_ranged_weapon_id: String = ""
var equipped_ranged_weapon_name: String = "None"

var equipped_armor_id: String = "grass_tunic"
var equipped_armor_name: String = "Grass Tunic"

var equipped_accessory_1_id: String = ""
var equipped_accessory_1_name: String = "None"

var equipped_accessory_2_id: String = ""
var equipped_accessory_2_name: String = "None"


func _init() -> void:
    recalculate_derived_stats(true)


func add_xp(amount: int) -> bool:
    if amount <= 0:
        return false

    xp += amount
    print("Gained XP: ", amount)
    print("XP: ", xp, " / ", xp_to_next_level)

    if xp >= xp_to_next_level:
        level_up()
        return true

    return false


func level_up() -> void:
    level += 1
    xp = 0
    stat_points += 1
    ability_points += 1
    xp_to_next_level = get_xp_required_for_current_level()

    recalculate_derived_stats(true)

    print("Level up! New level: ", level)
    print("Stat Points: ", stat_points)
    print("Ability Points: ", ability_points)
    print("Next Level XP: ", xp_to_next_level)


func get_xp_required_for_current_level() -> int:
    match level:
        0:
            return 3
        1:
            return 10
        2:
            return 25
        3:
            return 50
        4:
            return 100
        _:
            return 100 + ((level - 4) * 75)


func spend_stat_point(stat_id: String) -> bool:
    if stat_points <= 0:
        print("No stat points available.")
        return false

    match stat_id:
        "might":
            might += 1
        "agility":
            agility += 1
        "toughness":
            toughness += 1
        "speed":
            speed += 1
        "endurance":
            endurance += 1
        "focus":
            focus += 1
        _:
            push_warning("Unknown stat id: " + stat_id)
            return false

    stat_points -= 1
    recalculate_derived_stats(true)

    print("Spent stat point on: ", stat_id)
    print("Remaining Stat Points: ", stat_points)

    return true


func recalculate_derived_stats(heal_by_max_health_gain: bool = false) -> void:
    var old_max_health := max_health

    max_health = get_calculated_max_health()

    if current_health <= 0:
        current_health = max_health
        return

    if heal_by_max_health_gain:
        var health_gain := max_health - old_max_health
        if health_gain > 0:
            current_health += health_gain

    current_health = clampi(current_health, 0, max_health)


func get_calculated_max_health() -> int:
    return STARTING_HEALTH_BASE + (HEALTH_PER_TOUGHNESS * toughness) + _get_equipped_health_bonus()


func get_attack() -> int:
    return get_melee_attack()


func get_melee_attack() -> int:
    return base_attack + might + _get_equipped_melee_weapon_attack_bonus()


func get_ranged_attack() -> int:
    return base_attack + agility + _get_equipped_ranged_weapon_attack_bonus()


func get_defense() -> int:
    return base_defense + _get_equipped_armor_defense_bonus()


func get_move_speed(base_move_speed: float, move_speed_per_speed_point: float) -> float:
    return base_move_speed + ((speed - DEFAULT_SPEED_STAT) * move_speed_per_speed_point)


func get_attack_cooldown(base_attack_cooldown: float, attack_speed_bonus_per_agility: float = DEFAULT_ATTACK_SPEED_BONUS_PER_AGILITY) -> float:
    var speed_multiplier := 1.0 + (agility * attack_speed_bonus_per_agility)

    if speed_multiplier <= 0.0:
        return base_attack_cooldown

    return base_attack_cooldown / speed_multiplier


func get_equipped_melee_weapon_name() -> String:
    if equipped_melee_weapon_name.strip_edges() == "":
        return "None"

    return equipped_melee_weapon_name


func get_equipped_ranged_weapon_name() -> String:
    if equipped_ranged_weapon_name.strip_edges() == "":
        return "None"

    return equipped_ranged_weapon_name


func get_equipped_armor_name() -> String:
    if equipped_armor_name.strip_edges() == "":
        return "None"

    return equipped_armor_name


func get_equipped_accessory_1_name() -> String:
    if equipped_accessory_1_name.strip_edges() == "":
        return "None"

    return equipped_accessory_1_name


func get_equipped_accessory_2_name() -> String:
    if equipped_accessory_2_name.strip_edges() == "":
        return "None"

    return equipped_accessory_2_name


func get_equipped_weapon_name() -> String:
    return get_equipped_melee_weapon_name()


func get_equipped_accessory_name() -> String:
    return get_equipped_accessory_1_name()


func get_equipped_melee_weapon_damage_types() -> int:
    if equipped_melee_weapon_id.strip_edges() == "":
        return DamageTypes.NONE

    return ItemDatabase.get_damage_types(equipped_melee_weapon_id)


func get_equipped_ranged_weapon_damage_types() -> int:
    if equipped_ranged_weapon_id.strip_edges() == "":
        return DamageTypes.NONE

    return ItemDatabase.get_damage_types(equipped_ranged_weapon_id)


func get_equipped_weapon_damage_types() -> int:
    return get_equipped_melee_weapon_damage_types()


func get_equipped_armor_damage_resistances() -> int:
    if equipped_armor_id.strip_edges() == "":
        return DamageTypes.NONE

    return ItemDatabase.get_damage_resistances(equipped_armor_id)


func get_equipped_armor_damage_weaknesses() -> int:
    if equipped_armor_id.strip_edges() == "":
        return DamageTypes.NONE

    return ItemDatabase.get_damage_weaknesses(equipped_armor_id)


func get_equipped_accessory_1_damage_resistances() -> int:
    if equipped_accessory_1_id.strip_edges() == "":
        return DamageTypes.NONE

    return ItemDatabase.get_damage_resistances(equipped_accessory_1_id)


func get_equipped_accessory_1_damage_weaknesses() -> int:
    if equipped_accessory_1_id.strip_edges() == "":
        return DamageTypes.NONE

    return ItemDatabase.get_damage_weaknesses(equipped_accessory_1_id)


func get_equipped_accessory_2_damage_resistances() -> int:
    if equipped_accessory_2_id.strip_edges() == "":
        return DamageTypes.NONE

    return ItemDatabase.get_damage_resistances(equipped_accessory_2_id)


func get_equipped_accessory_2_damage_weaknesses() -> int:
    if equipped_accessory_2_id.strip_edges() == "":
        return DamageTypes.NONE

    return ItemDatabase.get_damage_weaknesses(equipped_accessory_2_id)


func get_equipped_accessory_damage_resistances() -> int:
    return get_equipped_accessory_1_damage_resistances()


func get_equipped_accessory_damage_weaknesses() -> int:
    return get_equipped_accessory_1_damage_weaknesses()


func get_total_damage_resistances() -> int:
    return (
        get_equipped_armor_damage_resistances()
        | get_equipped_accessory_1_damage_resistances()
        | get_equipped_accessory_2_damage_resistances()
    )


func get_total_damage_weaknesses() -> int:
    return (
        get_equipped_armor_damage_weaknesses()
        | get_equipped_accessory_1_damage_weaknesses()
        | get_equipped_accessory_2_damage_weaknesses()
    )


func equip_melee_weapon(item_id: String, item_name: String) -> bool:
    if item_id.strip_edges() != "" and not ItemDatabase.can_equip_in_slot(item_id, ItemDatabase.EQUIPMENT_SLOT_MELEE_WEAPON):
        push_warning("Item cannot be equipped in melee weapon slot: " + item_id)
        return false

    equipped_melee_weapon_id = item_id
    equipped_melee_weapon_name = _get_clean_equipped_name(item_name)
    recalculate_derived_stats(false)
    return true


func equip_ranged_weapon(item_id: String, item_name: String) -> bool:
    if item_id.strip_edges() != "" and not ItemDatabase.can_equip_in_slot(item_id, ItemDatabase.EQUIPMENT_SLOT_RANGED_WEAPON):
        push_warning("Item cannot be equipped in ranged weapon slot: " + item_id)
        return false

    equipped_ranged_weapon_id = item_id
    equipped_ranged_weapon_name = _get_clean_equipped_name(item_name)
    recalculate_derived_stats(false)
    return true


func equip_armor(item_id: String, item_name: String) -> bool:
    if item_id.strip_edges() != "" and not ItemDatabase.can_equip_in_slot(item_id, ItemDatabase.EQUIPMENT_SLOT_ARMOR):
        push_warning("Item cannot be equipped in armor slot: " + item_id)
        return false

    equipped_armor_id = item_id
    equipped_armor_name = _get_clean_equipped_name(item_name)
    recalculate_derived_stats(true)
    return true


func equip_accessory_1(item_id: String, item_name: String) -> bool:
    if item_id.strip_edges() != "" and not ItemDatabase.can_equip_in_slot(item_id, ItemDatabase.EQUIPMENT_SLOT_ACCESSORY):
        push_warning("Item cannot be equipped in accessory 1 slot: " + item_id)
        return false

    equipped_accessory_1_id = item_id
    equipped_accessory_1_name = _get_clean_equipped_name(item_name)
    recalculate_derived_stats(true)
    return true


func equip_accessory_2(item_id: String, item_name: String) -> bool:
    if item_id.strip_edges() != "" and not ItemDatabase.can_equip_in_slot(item_id, ItemDatabase.EQUIPMENT_SLOT_ACCESSORY):
        push_warning("Item cannot be equipped in accessory 2 slot: " + item_id)
        return false

    equipped_accessory_2_id = item_id
    equipped_accessory_2_name = _get_clean_equipped_name(item_name)
    recalculate_derived_stats(true)
    return true


func equip_accessory(item_id: String, item_name: String) -> bool:
    return equip_accessory_1(item_id, item_name)


func equip_weapon(item_id: String, item_name: String) -> bool:
    if ItemDatabase.can_equip_in_slot(item_id, ItemDatabase.EQUIPMENT_SLOT_RANGED_WEAPON):
        return equip_ranged_weapon(item_id, item_name)

    return equip_melee_weapon(item_id, item_name)


func unequip_melee_weapon() -> void:
    equipped_melee_weapon_id = ""
    equipped_melee_weapon_name = "None"
    recalculate_derived_stats(false)


func unequip_ranged_weapon() -> void:
    equipped_ranged_weapon_id = ""
    equipped_ranged_weapon_name = "None"
    recalculate_derived_stats(false)


func unequip_armor() -> void:
    equipped_armor_id = ""
    equipped_armor_name = "None"
    recalculate_derived_stats(false)


func unequip_accessory_1() -> void:
    equipped_accessory_1_id = ""
    equipped_accessory_1_name = "None"
    recalculate_derived_stats(false)


func unequip_accessory_2() -> void:
    equipped_accessory_2_id = ""
    equipped_accessory_2_name = "None"
    recalculate_derived_stats(false)


func unequip_weapon() -> void:
    unequip_melee_weapon()


func unequip_accessory() -> void:
    unequip_accessory_1()


func has_equipped_breakable_tool(required_tag: String) -> bool:
    if equipped_melee_weapon_id.strip_edges() != "":
        if ItemDatabase.item_has_breakable_tool_tag(equipped_melee_weapon_id, required_tag):
            return true

    if equipped_ranged_weapon_id.strip_edges() != "":
        if ItemDatabase.item_has_breakable_tool_tag(equipped_ranged_weapon_id, required_tag):
            return true

    return false


func _get_equipped_melee_weapon_attack_bonus() -> int:
    if equipped_melee_weapon_id.strip_edges() == "":
        return 0

    return ItemDatabase.get_attack_bonus(equipped_melee_weapon_id)


func _get_equipped_ranged_weapon_attack_bonus() -> int:
    if equipped_ranged_weapon_id.strip_edges() == "":
        return 0

    return ItemDatabase.get_attack_bonus(equipped_ranged_weapon_id)


func _get_equipped_weapon_attack_bonus() -> int:
    return _get_equipped_melee_weapon_attack_bonus()


func _get_equipped_armor_defense_bonus() -> int:
    if equipped_armor_id.strip_edges() == "":
        return 0

    return ItemDatabase.get_defense_bonus(equipped_armor_id)


func _get_equipped_health_bonus() -> int:
    var health_bonus := 0

    if equipped_armor_id.strip_edges() != "":
        var armor_data := ItemDatabase.get_item_data(equipped_armor_id)
        health_bonus += int(armor_data.get("health_bonus", 0))

    if equipped_accessory_1_id.strip_edges() != "":
        var accessory_1_data := ItemDatabase.get_item_data(equipped_accessory_1_id)
        health_bonus += int(accessory_1_data.get("health_bonus", 0))

    if equipped_accessory_2_id.strip_edges() != "":
        var accessory_2_data := ItemDatabase.get_item_data(equipped_accessory_2_id)
        health_bonus += int(accessory_2_data.get("health_bonus", 0))

    return health_bonus


func _get_clean_equipped_name(item_name: String) -> String:
    if item_name.strip_edges() == "":
        return "None"

    return item_name

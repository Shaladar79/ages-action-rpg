extends RefCounted
class_name ItemDatabase

const EQUIPMENT_SLOT_NONE: String = ""
const EQUIPMENT_SLOT_MELEE_WEAPON: String = "melee_weapon"
const EQUIPMENT_SLOT_RANGED_WEAPON: String = "ranged_weapon"
const EQUIPMENT_SLOT_ARMOR: String = "armor"
const EQUIPMENT_SLOT_ACCESSORY: String = "accessory"


static func get_item_data(item_id: String) -> Dictionary:
    var item_data := WeaponDatabase.get_item_data(item_id)

    if not item_data.is_empty():
        return item_data

    item_data = ArmorDatabase.get_item_data(item_id)

    if not item_data.is_empty():
        return item_data

    item_data = AccessoryDatabase.get_item_data(item_id)

    if not item_data.is_empty():
        return item_data

    item_data = ConsumableDatabase.get_item_data(item_id)

    if not item_data.is_empty():
        return item_data

    item_data = KeyItemDatabase.get_item_data(item_id)

    if not item_data.is_empty():
        return item_data

    item_data = SpellBookDatabase.get_item_data(item_id)

    if not item_data.is_empty():
        return item_data

    item_data = TechniqueDatabase.get_item_data(item_id)

    if not item_data.is_empty():
        return item_data

    return {}


static func get_item_name(item_id: String) -> String:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return item_id

    return item_data.get("name", item_id)


static func get_item_type(item_id: String) -> String:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return ""

    return item_data.get("type", "")

static func get_story_flag_on_acquire(item_id: String) -> String:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return ""

    return str(item_data.get("story_flag_on_acquire", ""))
    
static func get_item_tags(item_id: String) -> Array:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return []

    return item_data.get("item_tags", [])


static func item_has_tag(item_id: String, tag: String) -> bool:
    var tags := get_item_tags(item_id)

    for item_tag in tags:
        if str(item_tag) == tag:
            return true

    return false


static func get_equipment_slot(item_id: String) -> String:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return EQUIPMENT_SLOT_NONE

    return str(item_data.get("equipment_slot", EQUIPMENT_SLOT_NONE))


static func can_equip_in_slot(item_id: String, equipment_slot: String) -> bool:
    if item_id.strip_edges() == "":
        return false

    return get_equipment_slot(item_id) == equipment_slot


static func is_melee_weapon(item_id: String) -> bool:
    return get_equipment_slot(item_id) == EQUIPMENT_SLOT_MELEE_WEAPON


static func is_ranged_weapon(item_id: String) -> bool:
    return get_equipment_slot(item_id) == EQUIPMENT_SLOT_RANGED_WEAPON

static func is_ammo(item_id: String) -> bool:
    return get_item_type(item_id) == "ammo"


static func is_stackable_item(item_id: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    if get_item_type(item_id) == "consumable":
        return true

    return bool(item_data.get("stackable", false))


static func weapon_requires_ammo(item_id: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    return bool(item_data.get("requires_ammo", false))


static func get_weapon_ammo_item_id(item_id: String) -> String:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return ""

    return str(item_data.get("ammo_item_id", ""))


static func get_weapon_ammo_per_shot(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 0

    return int(item_data.get("ammo_per_shot", 0))


static func get_weapon_projectile_speed(item_id: String) -> float:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 0.0

    return float(item_data.get("projectile_speed", 0.0))


static func get_weapon_projectile_range(item_id: String) -> float:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 0.0

    return float(item_data.get("projectile_range", 0.0))


static func get_weapon_projectile_hit_radius(item_id: String) -> float:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 8.0

    return float(item_data.get("projectile_hit_radius", 8.0))


static func get_weapon_projectile_spawn_offset(item_id: String) -> float:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 18.0

    return float(item_data.get("projectile_spawn_offset", 18.0))


static func get_weapon_projectile_color(item_id: String) -> Color:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return Color(1.0, 1.0, 1.0, 1.0)

    return item_data.get("projectile_color", Color(1.0, 1.0, 1.0, 1.0))
    
static func is_armor(item_id: String) -> bool:
    return get_equipment_slot(item_id) == EQUIPMENT_SLOT_ARMOR


static func is_accessory(item_id: String) -> bool:
    return get_equipment_slot(item_id) == EQUIPMENT_SLOT_ACCESSORY


static func is_consumable(item_id: String) -> bool:
    return get_item_type(item_id) == "consumable"


static func is_spell_book(item_id: String) -> bool:
    return get_item_type(item_id) == "spell_book"


static func is_key_item(item_id: String) -> bool:
    return get_item_type(item_id) == "key_item"

static func is_technique_manual(item_id: String) -> bool:
    return get_item_type(item_id) == "technique_manual"


static func is_hotbar_usable(item_id: String) -> bool:
    var item_type := get_item_type(item_id)

    return item_type == "consumable" or item_type == "spell_book" or item_type == "technique_manual"


static func get_attack_bonus(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 0

    return int(item_data.get("attack_bonus", 0))


static func get_defense_bonus(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 0

    return int(item_data.get("defense_bonus", 0))


static func get_damage_types(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return DamageTypes.NONE

    return int(item_data.get("damage_types", DamageTypes.NONE))


static func get_damage_resistances(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return DamageTypes.NONE

    return int(item_data.get("damage_resistances", DamageTypes.NONE))


static func get_damage_weaknesses(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return DamageTypes.NONE

    return int(item_data.get("damage_weaknesses", DamageTypes.NONE))


static func get_consumable_effect(item_id: String) -> String:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return ""

    return str(item_data.get("consumable_effect", ""))


static func get_heal_amount(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 0

    return int(item_data.get("heal_amount", 0))


static func get_mana_gain(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 0

    return int(item_data.get("mana_gain", 0))
    
static func is_consumed_on_use(item_id: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    return bool(item_data.get("consumed_on_use", false))


static func get_spell_id(item_id: String) -> String:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return ""

    return str(item_data.get("spell_id", ""))

static func get_spell_range(item_id: String) -> float:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 0.0

    return float(item_data.get("spell_range", 0.0))

static func get_spell_name(item_id: String) -> String:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return get_item_name(item_id)

    return str(item_data.get("spell_name", get_item_name(item_id)))


static func get_spell_school(item_id: String) -> String:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return ""

    return str(item_data.get("spell_school", ""))


static func get_spell_mana_cost(item_id: String) -> int:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 0

    return int(item_data.get("mana_cost", 0))


static func get_spell_cooldown(item_id: String) -> float:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 0.0

    return float(item_data.get("cooldown", 0.0))


static func get_spell_status_effect(item_id: String) -> String:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return ""

    return str(item_data.get("status_effect", ""))


static func get_spell_status_duration(item_id: String) -> float:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return 0.0

    return float(item_data.get("status_duration", 0.0))


static func damage_types_overlap(first_damage_types: int, second_damage_types: int) -> bool:
    return (first_damage_types & second_damage_types) != 0


static func item_has_breakable_tool_tag(item_id: String, required_tag: String) -> bool:
    var item_data := get_item_data(item_id)

    if item_data.is_empty():
        return false

    if not bool(item_data.get("required_for_breakables", false)):
        return false

    return item_data.get("breakable_tool_tag", "") == required_tag

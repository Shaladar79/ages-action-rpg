extends RefCounted
class_name CharacterStats

var character_name: String = "Gene Ambrose"

var level: int = 1
var xp: int = 0
var xp_to_next_level: int = 100

var max_health: int = 10
var current_health: int = 10

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
var speed: int = 1

var base_attack: int = 0
var base_defense: int = 0

var equipped_weapon_id: String = ""
var equipped_weapon_name: String = "None"

var equipped_armor_id: String = "grass_tunic"
var equipped_armor_name: String = "Grass Tunic"

var equipped_accessory_id: String = ""
var equipped_accessory_name: String = "None"


func get_attack() -> int:
    return base_attack + might + _get_equipped_weapon_attack_bonus()


func get_defense() -> int:
    return base_defense + _get_equipped_armor_defense_bonus()


func get_equipped_weapon_name() -> String:
    if equipped_weapon_name.strip_edges() == "":
        return "None"

    return equipped_weapon_name


func get_equipped_armor_name() -> String:
    if equipped_armor_name.strip_edges() == "":
        return "None"

    return equipped_armor_name


func get_equipped_accessory_name() -> String:
    if equipped_accessory_name.strip_edges() == "":
        return "None"

    return equipped_accessory_name


func equip_weapon(item_id: String, item_name: String) -> void:
    equipped_weapon_id = item_id
    equipped_weapon_name = item_name


func equip_armor(item_id: String, item_name: String) -> void:
    equipped_armor_id = item_id
    equipped_armor_name = item_name


func equip_accessory(item_id: String, item_name: String) -> void:
    equipped_accessory_id = item_id
    equipped_accessory_name = item_name


func unequip_weapon() -> void:
    equipped_weapon_id = ""
    equipped_weapon_name = "None"


func unequip_armor() -> void:
    equipped_armor_id = ""
    equipped_armor_name = "None"


func unequip_accessory() -> void:
    equipped_accessory_id = ""
    equipped_accessory_name = "None"


func has_equipped_breakable_tool(required_tag: String) -> bool:
    if equipped_weapon_id.strip_edges() == "":
        return false

    return ItemDatabase.item_has_breakable_tool_tag(equipped_weapon_id, required_tag)


func _get_equipped_weapon_attack_bonus() -> int:
    if equipped_weapon_id.strip_edges() == "":
        return 0

    return ItemDatabase.get_attack_bonus(equipped_weapon_id)


func _get_equipped_armor_defense_bonus() -> int:
    if equipped_armor_id.strip_edges() == "":
        return 0

    return ItemDatabase.get_defense_bonus(equipped_armor_id)

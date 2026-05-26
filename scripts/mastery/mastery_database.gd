extends RefCounted
class_name MasteryDatabase

const MASTERY_TYPE_WEAPON: String = "weapon"
const MASTERY_TYPE_SCHOOL: String = "school"

const WEAPON_CLUB: String = "club"
const WEAPON_SLING: String = "sling"

const SCHOOL_FIRE: String = "fire"
const SCHOOL_NATURE: String = "nature"
const SCHOOL_EARTH: String = "earth"

const MAX_MASTERY_LEVEL: int = 10


static func get_weapon_mastery_ids() -> Array[String]:
    return [
        WEAPON_CLUB,
        WEAPON_SLING
    ]


static func get_school_mastery_ids() -> Array[String]:
    return [
        SCHOOL_FIRE,
        SCHOOL_NATURE,
        SCHOOL_EARTH
    ]


static func get_weapon_mastery_data(mastery_id: String) -> Dictionary:
    match mastery_id:
        WEAPON_CLUB:
            return {
                "id": WEAPON_CLUB,
                "type": MASTERY_TYPE_WEAPON,
                "name": "Club Mastery",
                "description": "Mastery gained by defeating monsters with club weapons.",
                "level_1_unlock_name": "Smash",
                "level_1_unlock_description": "Unlocks Smash, a club technique that strikes in a forward slam area.",
                "level_2_unlock_name": "Heavy Club Strikes",
                "level_2_unlock_description": "Increases damage dealt with club weapons by 20%."
            }

        WEAPON_SLING:
            return {
                "id": WEAPON_SLING,
                "type": MASTERY_TYPE_WEAPON,
                "name": "Sling Mastery",
                "description": "Mastery gained by defeating monsters with sling weapons.",
                "level_1_unlock_name": "Double Shot",
                "level_1_unlock_description": "Unlocks Double Shot, allowing two sling shots in quick succession.",
                "level_2_unlock_name": "Deadlier Sling Stones",
                "level_2_unlock_description": "Increases damage dealt with sling weapons by 20%."
            }

        _:
            return {}


static func get_school_mastery_data(mastery_id: String) -> Dictionary:
    match mastery_id:
        SCHOOL_FIRE:
            return {
                "id": SCHOOL_FIRE,
                "type": MASTERY_TYPE_SCHOOL,
                "name": "Fire School Mastery",
                "description": "Mastery gained by casting Fire school spells."
            }

        SCHOOL_NATURE:
            return {
                "id": SCHOOL_NATURE,
                "type": MASTERY_TYPE_SCHOOL,
                "name": "Nature School Mastery",
                "description": "Mastery gained by casting Nature school spells."
            }

        SCHOOL_EARTH:
            return {
                "id": SCHOOL_EARTH,
                "type": MASTERY_TYPE_SCHOOL,
                "name": "Earth School Mastery",
                "description": "Mastery gained by casting Earth school spells."
            }

        _:
            return {}


static func get_mastery_display_name(mastery_type: String, mastery_id: String) -> String:
    var mastery_data := {}

    match mastery_type:
        MASTERY_TYPE_WEAPON:
            mastery_data = get_weapon_mastery_data(mastery_id)

        MASTERY_TYPE_SCHOOL:
            mastery_data = get_school_mastery_data(mastery_id)

    if mastery_data.is_empty():
        return mastery_id.capitalize()

    return str(mastery_data.get("name", mastery_id.capitalize()))


static func get_mastery_description(mastery_type: String, mastery_id: String) -> String:
    var mastery_data := {}

    match mastery_type:
        MASTERY_TYPE_WEAPON:
            mastery_data = get_weapon_mastery_data(mastery_id)

        MASTERY_TYPE_SCHOOL:
            mastery_data = get_school_mastery_data(mastery_id)

    if mastery_data.is_empty():
        return ""

    return str(mastery_data.get("description", ""))


static func weapon_mastery_exists(mastery_id: String) -> bool:
    return not get_weapon_mastery_data(mastery_id).is_empty()


static func school_mastery_exists(mastery_id: String) -> bool:
    return not get_school_mastery_data(mastery_id).is_empty()


static func get_weapon_kills_required_for_next_level(current_level: int) -> int:
    match current_level:
        0:
            return 50
        1:
            return 75
        2:
            return 125
        3:
            return 200
        4:
            return 300
        5:
            return 425
        6:
            return 575
        7:
            return 750
        8:
            return 950
        9:
            return 1175
        _:
            return 0


static func get_school_casts_required_for_next_level(current_level: int) -> int:
    match current_level:
        0:
            return 20
        1:
            return 50
        2:
            return 75
        3:
            return 125
        4:
            return 200
        5:
            return 300
        6:
            return 425
        7:
            return 575
        8:
            return 750
        9:
            return 950
        _:
            return 0


static func get_required_progress_for_next_level(mastery_type: String, current_level: int) -> int:
    if current_level >= MAX_MASTERY_LEVEL:
        return 0

    match mastery_type:
        MASTERY_TYPE_WEAPON:
            return get_weapon_kills_required_for_next_level(current_level)

        MASTERY_TYPE_SCHOOL:
            return get_school_casts_required_for_next_level(current_level)

        _:
            return 0


static func get_weapon_damage_multiplier(mastery_id: String, mastery_level: int) -> float:
    if not weapon_mastery_exists(mastery_id):
        return 1.0

    if mastery_level >= 2:
        return 1.2

    return 1.0


static func has_weapon_technique_unlocked(mastery_id: String, mastery_level: int) -> bool:
    if not weapon_mastery_exists(mastery_id):
        return false

    return mastery_level >= 1

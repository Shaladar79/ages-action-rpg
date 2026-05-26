extends RefCounted
class_name FactionDatabase

const FACTION_BOUNTY_HUNTERS: String = "bounty_hunters"


static func get_faction_data(faction_id: String) -> Dictionary:
    match faction_id:
        FACTION_BOUNTY_HUNTERS:
            return {
                "id": FACTION_BOUNTY_HUNTERS,
                "name": "The Bounty Hunters",
                "description": "A practical faction of creature hunters who track dangerous beasts, field monsters, and stronger threats for coin, standing, and regional safety.",
                "tiers": [
                    {
                        "tier": 0,
                        "points_required": 0,
                        "title": "Unknown"
                    },
                    {
                        "tier": 1,
                        "points_required": 100,
                        "title": "Noticed"
                    },
                    {
                        "tier": 2,
                        "points_required": 250,
                        "title": "Proven"
                    },
                    {
                        "tier": 3,
                        "points_required": 500,
                        "title": "Trusted"
                    },
                    {
                        "tier": 4,
                        "points_required": 900,
                        "title": "Reliable"
                    },
                    {
                        "tier": 5,
                        "points_required": 1500,
                        "title": "Respected"
                    },
                    {
                        "tier": 6,
                        "points_required": 2400,
                        "title": "Veteran"
                    },
                    {
                        "tier": 7,
                        "points_required": 3700,
                        "title": "Elite"
                    },
                    {
                        "tier": 8,
                        "points_required": 5500,
                        "title": "Renowned"
                    },
                    {
                        "tier": 9,
                        "points_required": 8000,
                        "title": "Legendary"
                    },
                    {
                        "tier": 10,
                        "points_required": 12000,
                        "title": "Guild Champion"
                    }
                ]
            }

        _:
            return {}


static func get_all_faction_ids() -> Array[String]:
    return [
        FACTION_BOUNTY_HUNTERS
    ]


static func get_faction_name(faction_id: String) -> String:
    var faction_data := get_faction_data(faction_id)

    if faction_data.is_empty():
        return faction_id

    return str(faction_data.get("name", faction_id))


static func get_faction_description(faction_id: String) -> String:
    var faction_data := get_faction_data(faction_id)

    if faction_data.is_empty():
        return ""

    return str(faction_data.get("description", ""))


static func get_faction_tiers(faction_id: String) -> Array:
    var faction_data := get_faction_data(faction_id)

    if faction_data.is_empty():
        return []

    return faction_data.get("tiers", [])


static func get_tier_for_points(faction_id: String, points: int) -> Dictionary:
    var tiers := get_faction_tiers(faction_id)

    if tiers.is_empty():
        return {
            "tier": 0,
            "points_required": 0,
            "title": "Unknown"
        }

    var current_tier: Dictionary = tiers[0]

    for tier_data in tiers:
        if typeof(tier_data) != TYPE_DICTIONARY:
            continue

        var required_points: int = int(tier_data.get("points_required", 0))

        if points >= required_points:
            current_tier = tier_data
        else:
            break

    return current_tier


static func get_next_tier_for_points(faction_id: String, points: int) -> Dictionary:
    var tiers := get_faction_tiers(faction_id)

    for tier_data in tiers:
        if typeof(tier_data) != TYPE_DICTIONARY:
            continue

        var required_points: int = int(tier_data.get("points_required", 0))

        if points < required_points:
            return tier_data

    return {}


static func faction_exists(faction_id: String) -> bool:
    return not get_faction_data(faction_id).is_empty()

extends RefCounted
class_name WeaponDatabase

const ITEM_STONE_CLUB: String = "club"
const ITEM_SLING: String = "sling"
const ITEM_SLING_AMMO: String = "sling_ammo"

const ATTACK_VISUAL_TYPE_SWING: String = "swing"
const ATTACK_VISUAL_TYPE_THRUST: String = "thrust"
const ATTACK_VISUAL_TYPE_RAISE: String = "raise"


static func get_item_data(item_id: String) -> Dictionary:
    match item_id:
        ITEM_STONE_CLUB:
            return {
                "id": ITEM_STONE_CLUB,
                "name": "Stone Club",
                "type": "weapon",

                "equipment_slot": ItemDatabase.EQUIPMENT_SLOT_MELEE_WEAPON,
                "item_tags": [
                    "weapon",
                    "melee_weapon",
                    "breakable_tool"
                ],

                "weapon_mastery_id": MasteryDatabase.WEAPON_CLUB,

                "attack_bonus": 0,
                "damage_types": DamageTypes.BASHING,

                "required_for_breakables": true,
                "breakable_tool_tag": "club",

                # First-pass melee attack visual data.
                # Leave texture path empty to use the current WeaponSprite texture as fallback.
                # Later, replace this with your real weapon attack image path.
                # Example:
                # "attack_visual_texture_path": "res://assets/weapons/club_attack.png",
                "attack_visual_texture_path": "",
                "attack_visual_type": ATTACK_VISUAL_TYPE_SWING,
                "attack_visual_offset": 22.0,
                "attack_visual_scale": Vector2(1.0, 1.0)
            }

        ITEM_SLING:
            return {
                "id": ITEM_SLING,
                "name": "Sling",
                "type": "weapon",

                "equipment_slot": ItemDatabase.EQUIPMENT_SLOT_RANGED_WEAPON,
                "item_tags": [
                    "weapon",
                    "ranged_weapon",
                    "sling"
                ],

                "weapon_mastery_id": MasteryDatabase.WEAPON_SLING,

                "attack_bonus": 0,
                "damage_types": DamageTypes.BASHING,

                "requires_ammo": true,
                "ammo_item_id": ITEM_SLING_AMMO,
                "ammo_per_shot": 1,

                "projectile_speed": 320.0,
                "projectile_range": 220.0,
                "projectile_hit_radius": 7.0,
                "projectile_spawn_offset": 18.0,
                "projectile_color": Color(0.75, 0.65, 0.45, 1.0)
            }

        ITEM_SLING_AMMO:
            return {
                "id": ITEM_SLING_AMMO,
                "name": "Sling Ammo",
                "type": "ammo",

                "item_tags": [
                    "ammo",
                    "sling_ammo"
                ],

                "stackable": true,
                "ammo_for_weapon_id": ITEM_SLING,
                "description": "Small stones or pellets used as ammunition for a sling."
            }

        _:
            return {}

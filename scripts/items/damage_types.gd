extends RefCounted
class_name DamageTypes

const NONE: int = 0
const BASHING: int = 1 << 0
const SLASHING: int = 1 << 1
const CHOPPING: int = 1 << 2
const PIERCING: int = 1 << 3
const FIRE: int = 1 << 4
const ICE: int = 1 << 5
const LIGHTNING: int = 1 << 6
const ACID: int = 1 << 7
const LIGHT: int = 1 << 8
const SHADOW: int = 1 << 9


static func damage_types_overlap(first_damage_types: int, second_damage_types: int) -> bool:
    return (first_damage_types & second_damage_types) != 0


static func get_damage_type_names(damage_types: int) -> Array[String]:
    var names: Array[String] = []

    if (damage_types & BASHING) != 0:
        names.append("Bashing")

    if (damage_types & SLASHING) != 0:
        names.append("Slashing")

    if (damage_types & CHOPPING) != 0:
        names.append("Chopping")

    if (damage_types & PIERCING) != 0:
        names.append("Piercing")

    if (damage_types & FIRE) != 0:
        names.append("Fire")

    if (damage_types & ICE) != 0:
        names.append("Ice")

    if (damage_types & LIGHTNING) != 0:
        names.append("Lightning")

    if (damage_types & ACID) != 0:
        names.append("Acid")

    if (damage_types & LIGHT) != 0:
        names.append("Light")

    if (damage_types & SHADOW) != 0:
        names.append("Shadow")

    return names

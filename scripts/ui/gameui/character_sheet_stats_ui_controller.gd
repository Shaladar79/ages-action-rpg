extends RefCounted
class_name CharacterSheetStatsUiController

var character_panel: Panel = null

var stats_root: Control = null

var title_label: Label = null
var character_name_label: Label = null
var level_label: Label = null
var xp_label: Label = null
var stat_points_label: Label = null
var ability_points_label: Label = null

var sheet_health_label: Label = null
var sheet_mana_label: Label = null
var sheet_stamina_label: Label = null

var attack_label: Label = null
var defense_label: Label = null

var attributes_label: Label = null
var might_label: Label = null
var agility_label: Label = null
var toughness_label: Label = null
var endurance_label: Label = null
var focus_label: Label = null
var speed_label: Label = null


func setup(panel_node: Panel) -> void:
    character_panel = panel_node

    if character_panel == null:
        push_warning("CharacterSheetStatsUiController setup failed. Character panel is null.")
        return

    _hide_legacy_editor_labels()
    _create_character_sheet_stats_panel()
    clear_character_sheet()


func update_character_sheet(stats: CharacterStats) -> void:
    if title_label != null:
        title_label.text = "Character Sheet"

    if stats == null:
        clear_character_sheet()
        return

    if character_name_label != null:
        character_name_label.text = stats.character_name

    if level_label != null:
        level_label.text = "Level: " + str(stats.level)

    if xp_label != null:
        xp_label.text = "XP: %s / %s" % [stats.xp, stats.xp_to_next_level]

    if stat_points_label != null:
        stat_points_label.text = "Stat Points: " + str(stats.stat_points)

    if ability_points_label != null:
        ability_points_label.text = "Ability Points: " + str(stats.ability_points)
        ability_points_label.visible = false

    _update_sheet_resources(stats)
    _update_attributes_panel(stats)
    _update_combat_stats(stats)


func clear_character_sheet() -> void:
    if title_label != null:
        title_label.text = "Character Sheet"

    if character_name_label != null:
        character_name_label.text = "No Character"

    if level_label != null:
        level_label.text = "Level: --"

    if xp_label != null:
        xp_label.text = "XP: -- / --"

    if stat_points_label != null:
        stat_points_label.text = "Stat Points: --"

    if ability_points_label != null:
        ability_points_label.text = "Ability Points: --"
        ability_points_label.visible = false

    _clear_sheet_resources()
    _clear_attributes_panel()
    _clear_combat_stats()


func _create_character_sheet_stats_panel() -> void:
    if stats_root != null:
        return

    stats_root = Control.new()
    stats_root.name = "CodeBuiltCharacterSheetStats"
    stats_root.anchor_left = 0.0
    stats_root.anchor_right = 1.0
    stats_root.anchor_top = 0.0
    stats_root.anchor_bottom = 1.0
    stats_root.offset_left = 0.0
    stats_root.offset_right = 0.0
    stats_root.offset_top = 0.0
    stats_root.offset_bottom = 0.0
    stats_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    character_panel.add_child(stats_root)

    title_label = _create_label("TitleLabel", "Character Sheet", Vector2(16.0, 8.0), Vector2(260.0, 28.0), 20)

    character_name_label = _create_label("CharacterNameLabel", "No Character", Vector2(16.0, 38.0), Vector2(250.0, 24.0), 15)
    level_label = _create_label("LevelLabel", "Level: --", Vector2(270.0, 38.0), Vector2(120.0, 24.0), 15)
    xp_label = _create_label("XpLabel", "XP: -- / --", Vector2(400.0, 38.0), Vector2(180.0, 24.0), 15)

    stat_points_label = _create_label("StatPointsLabel", "Stat Points: --", Vector2(16.0, 70.0), Vector2(180.0, 24.0), 14)
    ability_points_label = _create_label("AbilityPointsLabel", "Ability Points: --", Vector2(200.0, 70.0), Vector2(180.0, 24.0), 14)
    ability_points_label.visible = false

    sheet_health_label = _create_label("Health", "Health: -- / --", Vector2(16.0, 104.0), Vector2(180.0, 24.0), 14)
    sheet_mana_label = _create_label("Mana", "", Vector2(200.0, 104.0), Vector2(160.0, 24.0), 14)
    sheet_stamina_label = _create_label("Stamina", "", Vector2(365.0, 104.0), Vector2(170.0, 24.0), 14)

    attack_label = _create_label("MeleeAttackLabel", "Attack: --", Vector2(16.0, 138.0), Vector2(180.0, 24.0), 14)
    defense_label = _create_label("DefenseLabel", "Defense: --", Vector2(200.0, 138.0), Vector2(180.0, 24.0), 14)

    attributes_label = _create_label("AttributesLabel", "Attributes", Vector2(16.0, 180.0), Vector2(180.0, 24.0), 16)

    might_label = _create_label("Might", "Might: --", Vector2(24.0, 212.0), Vector2(135.0, 24.0), 14)
    agility_label = _create_label("Agility", "Agility: --", Vector2(24.0, 242.0), Vector2(135.0, 24.0), 14)
    toughness_label = _create_label("Toughness", "Toughness: --", Vector2(24.0, 272.0), Vector2(135.0, 24.0), 14)
    speed_label = _create_label("Speed", "Speed: --", Vector2(24.0, 302.0), Vector2(135.0, 24.0), 14)

    endurance_label = _create_label("Endurance", "Endurance: --", Vector2(24.0, 332.0), Vector2(135.0, 24.0), 14)
    endurance_label.visible = false

    focus_label = _create_label("Focus", "Focus: --", Vector2(24.0, 362.0), Vector2(135.0, 24.0), 14)
    focus_label.visible = false


func _create_label(label_name: String, label_text: String, position: Vector2, size: Vector2, font_size: int = 14) -> Label:
    var label := Label.new()
    label.name = label_name
    label.text = label_text
    label.anchor_left = 0.0
    label.anchor_right = 0.0
    label.anchor_top = 0.0
    label.anchor_bottom = 0.0
    label.offset_left = position.x
    label.offset_top = position.y
    label.offset_right = position.x + size.x
    label.offset_bottom = position.y + size.y
    label.custom_minimum_size = size
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size", font_size)

    stats_root.add_child(label)
    return label


func _hide_legacy_editor_labels() -> void:
    _hide_legacy_node("TitleLabel")
    _hide_legacy_node("CharacterNameLabel")
    _hide_legacy_node("LevelLabel")
    _hide_legacy_node("XpLabel")
    _hide_legacy_node("StatPointsLabel")
    _hide_legacy_node("AbilityPointsLabel")
    _hide_legacy_node("Health")
    _hide_legacy_node("Mana")
    _hide_legacy_node("Stamina")
    _hide_legacy_node("AttributesPanel_base")

    var old_attack_label := character_panel.find_child("atk_lbl", true, false) as CanvasItem
    if old_attack_label != null:
        old_attack_label.visible = false

    var old_defense_label := character_panel.find_child("def_lbl", true, false) as CanvasItem
    if old_defense_label != null:
        old_defense_label.visible = false


func _hide_legacy_node(node_path: String) -> void:
    if character_panel == null:
        return

    var node := character_panel.get_node_or_null(node_path)

    if node == null:
        return

    if node is CanvasItem:
        var canvas_item := node as CanvasItem
        canvas_item.visible = false


func _clear_sheet_resources() -> void:
    if sheet_health_label != null:
        sheet_health_label.text = "Health: -- / --"

    if sheet_mana_label != null:
        sheet_mana_label.visible = false
        sheet_mana_label.text = ""

    if sheet_stamina_label != null:
        sheet_stamina_label.visible = false
        sheet_stamina_label.text = ""


func _update_sheet_resources(stats: CharacterStats) -> void:
    if sheet_health_label != null:
        sheet_health_label.text = "Health: %s / %s" % [stats.current_health, stats.max_health]

    if sheet_mana_label != null:
        sheet_mana_label.visible = stats.has_mana_resource

        if stats.has_mana_resource:
            sheet_mana_label.text = "Mana: %s / %s" % [stats.current_mana, stats.max_mana]
        else:
            sheet_mana_label.text = ""

    if sheet_stamina_label != null:
        sheet_stamina_label.visible = stats.has_stamina_resource

        if stats.has_stamina_resource:
            sheet_stamina_label.text = "Stamina: %s / %s" % [stats.current_stamina, stats.max_stamina]
        else:
            sheet_stamina_label.text = ""


func _clear_attributes_panel() -> void:
    if attributes_label != null:
        attributes_label.text = "Attributes"

    if might_label != null:
        might_label.text = "Might: --"

    if agility_label != null:
        agility_label.text = "Agility: --"

    if toughness_label != null:
        toughness_label.text = "Toughness: --"

    if endurance_label != null:
        endurance_label.text = "Endurance: --"
        endurance_label.visible = false

    if focus_label != null:
        focus_label.text = "Focus: --"
        focus_label.visible = false

    if speed_label != null:
        speed_label.text = "Speed: --"


func _update_attributes_panel(stats: CharacterStats) -> void:
    if attributes_label != null:
        attributes_label.text = "Attributes"

    if might_label != null:
        might_label.text = "Might: " + str(stats.might)

    if agility_label != null:
        agility_label.text = "Agility: " + str(stats.agility)

    if toughness_label != null:
        toughness_label.text = "Toughness: " + str(stats.toughness)

    if endurance_label != null:
        endurance_label.text = "Endurance: " + str(stats.endurance)
        endurance_label.visible = false

    if focus_label != null:
        focus_label.text = "Focus: " + str(stats.focus)
        focus_label.visible = stats.has_mana_resource

    if speed_label != null:
        speed_label.text = "Speed: " + str(stats.speed)


func _clear_combat_stats() -> void:
    if attack_label != null:
        attack_label.text = "Attack: --"

    if defense_label != null:
        defense_label.text = "Defense: --"


func _update_combat_stats(stats: CharacterStats) -> void:
    if attack_label != null:
        attack_label.text = "Melee Attack: " + str(stats.get_melee_attack())

    if defense_label != null:
        defense_label.text = "Defense: " + str(stats.get_defense())

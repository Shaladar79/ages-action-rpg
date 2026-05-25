extends RefCounted
class_name CharacterSheetStatsUiController

var character_panel: Panel = null

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

    _bind_existing_editor_labels()
    _position_character_sheet_header_labels()
    _hide_locked_resources_and_stats()
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


func _bind_existing_editor_labels() -> void:
    title_label = character_panel.get_node_or_null("TitleLabel") as Label
    character_name_label = character_panel.get_node_or_null("CharacterNameLabel") as Label
    level_label = character_panel.get_node_or_null("LevelLabel") as Label
    xp_label = character_panel.get_node_or_null("XpLabel") as Label
    stat_points_label = character_panel.get_node_or_null("StatPointsLabel") as Label
    ability_points_label = character_panel.get_node_or_null("AbilityPointsLabel") as Label

    sheet_health_label = character_panel.get_node_or_null("Health") as Label
    sheet_mana_label = character_panel.get_node_or_null("Mana") as Label
    sheet_stamina_label = character_panel.get_node_or_null("Stamina") as Label

    attack_label = character_panel.find_child("atk_lbl", true, false) as Label
    defense_label = character_panel.find_child("def_lbl", true, false) as Label

    attributes_label = character_panel.get_node_or_null("AttributesPanel_base/Attribute_panel_att/AttributesLabel") as Label
    might_label = character_panel.get_node_or_null("AttributesPanel_base/Attribute_panel_att/Might") as Label
    agility_label = character_panel.get_node_or_null("AttributesPanel_base/Attribute_panel_att/Agility") as Label
    toughness_label = character_panel.get_node_or_null("AttributesPanel_base/Attribute_panel_att/Toughness") as Label
    endurance_label = character_panel.get_node_or_null("AttributesPanel_base/Attribute_panel_att/Endurance") as Label
    focus_label = character_panel.get_node_or_null("AttributesPanel_base/Attribute_panel_att/Focus") as Label
    speed_label = character_panel.get_node_or_null("AttributesPanel_base/Attribute_panel_att/Speed") as Label


func _position_character_sheet_header_labels() -> void:
    if character_name_label != null:
        character_name_label.anchor_left = 0.0
        character_name_label.anchor_right = 0.0
        character_name_label.anchor_top = 0.0
        character_name_label.anchor_bottom = 0.0
        character_name_label.offset_left = 16.0
        character_name_label.offset_right = 260.0
        character_name_label.offset_top = 20.0
        character_name_label.offset_bottom = 46.0

    if level_label != null:
        level_label.anchor_left = 0.0
        level_label.anchor_right = 0.0
        level_label.anchor_top = 0.0
        level_label.anchor_bottom = 0.0
        level_label.offset_left = 270.0
        level_label.offset_right = 390.0
        level_label.offset_top = 20.0
        level_label.offset_bottom = 46.0

    if xp_label != null:
        xp_label.anchor_left = 0.0
        xp_label.anchor_right = 0.0
        xp_label.anchor_top = 0.0
        xp_label.anchor_bottom = 0.0
        xp_label.offset_left = 400.0
        xp_label.offset_right = 560.0
        xp_label.offset_top = 20.0
        xp_label.offset_bottom = 46.0


func _hide_locked_resources_and_stats() -> void:
    if ability_points_label != null:
        ability_points_label.visible = false

    if endurance_label != null:
        endurance_label.visible = false

    if focus_label != null:
        focus_label.visible = false


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
        focus_label.visible = false

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

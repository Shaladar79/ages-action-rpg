extends CanvasLayer

@onready var hud_health_label: Label = get_node_or_null("HUD/Health") as Label
@onready var hud_mana_label: Label = get_node_or_null("HUD/Mana") as Label
@onready var hud_stamina_label: Label = get_node_or_null("HUD/Stamina") as Label

@onready var interaction_prompt: Control = $InteractionPrompt
@onready var interaction_label: Label = $InteractionPrompt/InteractionLabel

@onready var character_screen: Control = $CharacterScreen
@onready var character_panel: Panel = $CharacterScreen/Panel

@onready var title_label: Label = $CharacterScreen/Panel/TitleLabel
@onready var character_name_label: Label = $CharacterScreen/Panel/CharacterNameLabel
@onready var level_label: Label = $CharacterScreen/Panel/LevelLabel
@onready var xp_label: Label = $CharacterScreen/Panel/XpLabel
@onready var stat_points_label: Label = get_node_or_null("CharacterScreen/Panel/StatPointsLabel") as Label
@onready var ability_points_label: Label = get_node_or_null("CharacterScreen/Panel/AbilityPointsLabel") as Label

@onready var sheet_health_label: Label = get_node_or_null("CharacterScreen/Panel/Health") as Label
@onready var sheet_mana_label: Label = get_node_or_null("CharacterScreen/Panel/Mana") as Label
@onready var sheet_stamina_label: Label = get_node_or_null("CharacterScreen/Panel/Stamina") as Label

@onready var attack_label: Label = get_node_or_null("CharacterScreen/Panel/atk_lbl") as Label
@onready var defense_label: Label = get_node_or_null("CharacterScreen/Panel/def_lbl") as Label

@onready var attributes_label: Label = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/AttributesLabel") as Label
@onready var might_label: Label = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/Might") as Label
@onready var agility_label: Label = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/Agility") as Label
@onready var toughness_label: Label = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/Toughness") as Label
@onready var endurance_label: Label = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/Endurance") as Label
@onready var focus_label: Label = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/Focus") as Label
@onready var speed_label: Label = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/Speed") as Label

@onready var add_might_button: Button = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/AddMightButton") as Button
@onready var add_agility_button: Button = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/AddAgilityButton") as Button
@onready var add_toughness_button: Button = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/AddToughnessButton") as Button
@onready var add_speed_button: Button = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/AddSpeedButton") as Button

@onready var add_endurance_button: Button = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/AddEnduranceButton") as Button
@onready var add_focus_button: Button = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/AddFocusButton") as Button

@onready var weapon_slot_label: Label = $CharacterScreen/Panel/WeaponSlotLabel
@onready var armor_slot_label: Label = $CharacterScreen/Panel/ArmorSlotLabel
@onready var accessory_slot_label: Label = $CharacterScreen/Panel/AccessorySlotLabel
@onready var inventory_label: Label = $CharacterScreen/Panel/InventoryLabel

@onready var equip_weapon_button: Button = $CharacterScreen/Panel/EquipWeaponButton
@onready var equip_armor_button: Button = $CharacterScreen/Panel/EquipArmorButton
@onready var equip_accessory_button: Button = $CharacterScreen/Panel/EquipAccessoryButton
@onready var close_button: Button = $CharacterScreen/Panel/CloseButton

var player: Node = null


func _ready() -> void:
    add_to_group("interaction_ui")

    player = get_tree().get_first_node_in_group("player")

    character_screen.visible = false
    interaction_prompt.visible = false

    _hide_locked_resources_and_stats()
    _connect_buttons()
    _update_hud()
    _update_character_screen()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("character_screen"):
        toggle_character_screen()
        get_viewport().set_input_as_handled()


func show_prompt(key_text: String = "E") -> void:
    interaction_label.text = key_text
    interaction_prompt.visible = true


func hide_prompt() -> void:
    interaction_prompt.visible = false


func refresh_character_display() -> void:
    _refresh_player_reference()
    _update_hud()
    _update_character_screen()


func toggle_character_screen() -> void:
    character_screen.visible = not character_screen.visible

    if character_screen.visible:
        _refresh_player_reference()
        _update_character_screen()


func open_character_screen() -> void:
    character_screen.visible = true
    _refresh_player_reference()
    _update_character_screen()


func close_character_screen() -> void:
    character_screen.visible = false


func _hide_locked_resources_and_stats() -> void:
    if ability_points_label != null:
        ability_points_label.visible = false

    if endurance_label != null:
        endurance_label.visible = false

    if focus_label != null:
        focus_label.visible = false

    if add_endurance_button != null:
        add_endurance_button.visible = false
        add_endurance_button.disabled = true

    if add_focus_button != null:
        add_focus_button.visible = false
        add_focus_button.disabled = true


func _connect_buttons() -> void:
    if not equip_weapon_button.pressed.is_connected(_on_equip_weapon_button_pressed):
        equip_weapon_button.pressed.connect(_on_equip_weapon_button_pressed)

    if not equip_armor_button.pressed.is_connected(_on_equip_armor_button_pressed):
        equip_armor_button.pressed.connect(_on_equip_armor_button_pressed)

    if not equip_accessory_button.pressed.is_connected(_on_equip_accessory_button_pressed):
        equip_accessory_button.pressed.connect(_on_equip_accessory_button_pressed)

    if not close_button.pressed.is_connected(_on_close_button_pressed):
        close_button.pressed.connect(_on_close_button_pressed)

    if add_might_button != null and not add_might_button.pressed.is_connected(_on_add_might_button_pressed):
        add_might_button.pressed.connect(_on_add_might_button_pressed)

    if add_agility_button != null and not add_agility_button.pressed.is_connected(_on_add_agility_button_pressed):
        add_agility_button.pressed.connect(_on_add_agility_button_pressed)

    if add_toughness_button != null and not add_toughness_button.pressed.is_connected(_on_add_toughness_button_pressed):
        add_toughness_button.pressed.connect(_on_add_toughness_button_pressed)

    if add_speed_button != null and not add_speed_button.pressed.is_connected(_on_add_speed_button_pressed):
        add_speed_button.pressed.connect(_on_add_speed_button_pressed)


func _refresh_player_reference() -> void:
    if player != null:
        return

    player = get_tree().get_first_node_in_group("player")


func _get_stats() -> CharacterStats:
    _refresh_player_reference()

    if player == null:
        return null

    if not player.has_method("get_character_stats"):
        return null

    return player.get_character_stats()


func _update_hud() -> void:
    var stats := _get_stats()

    if stats == null:
        if hud_health_label != null:
            hud_health_label.text = "Health: -- / --"

        if hud_mana_label != null:
            hud_mana_label.visible = false
            hud_mana_label.text = ""

        if hud_stamina_label != null:
            hud_stamina_label.visible = false
            hud_stamina_label.text = ""

        return

    if hud_health_label != null:
        hud_health_label.text = "Health: %s / %s" % [stats.current_health, stats.max_health]

    if hud_mana_label != null:
        hud_mana_label.visible = stats.has_mana_resource

        if stats.has_mana_resource:
            hud_mana_label.text = "Mana: %s / %s" % [stats.current_mana, stats.max_mana]
        else:
            hud_mana_label.text = ""

    if hud_stamina_label != null:
        hud_stamina_label.visible = stats.has_stamina_resource

        if stats.has_stamina_resource:
            hud_stamina_label.text = "Stamina: %s / %s" % [stats.current_stamina, stats.max_stamina]
        else:
            hud_stamina_label.text = ""


func _update_character_screen() -> void:
    var stats := _get_stats()

    title_label.text = "Character Sheet"

    if stats == null:
        character_name_label.text = "No Character"
        level_label.text = "Level: --"
        xp_label.text = "XP: -- / --"

        if stat_points_label != null:
            stat_points_label.text = "Stat Points: --"

        _clear_sheet_resources()
        _clear_attributes_panel()
        _clear_combat_stats()

        weapon_slot_label.text = "Weapon: None"
        armor_slot_label.text = "Armor: None"
        accessory_slot_label.text = "Accessory: None"
        inventory_label.text = "Inventory:\nNone"

        equip_weapon_button.disabled = true
        equip_armor_button.disabled = true
        equip_accessory_button.disabled = true
        _set_stat_buttons_disabled(true)
        return

    character_name_label.text = stats.character_name
    level_label.text = "Level: " + str(stats.level)
    xp_label.text = "XP: %s / %s" % [stats.xp, stats.xp_to_next_level]

    if stat_points_label != null:
        stat_points_label.text = "Stat Points: " + str(stats.stat_points)

    if ability_points_label != null:
        ability_points_label.text = "Ability Points: " + str(stats.ability_points)
        ability_points_label.visible = false

    _update_sheet_resources(stats)
    _update_attributes_panel(stats)
    _update_combat_stats(stats)

    weapon_slot_label.text = "Weapon: " + stats.get_equipped_weapon_name()
    armor_slot_label.text = "Armor: " + stats.get_equipped_armor_name()
    accessory_slot_label.text = "Accessory: " + stats.get_equipped_accessory_name()

    inventory_label.text = _get_inventory_text()

    equip_weapon_button.disabled = not _player_has_item("club")
    equip_armor_button.disabled = true
    equip_accessory_button.disabled = true

    _set_stat_buttons_disabled(stats.stat_points <= 0)


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
        attack_label.text = "Attack: " + str(stats.get_attack())

    if defense_label != null:
        defense_label.text = "Defense: " + str(stats.get_defense())


func _set_stat_buttons_disabled(disabled: bool) -> void:
    if add_might_button != null:
        add_might_button.disabled = disabled

    if add_agility_button != null:
        add_agility_button.disabled = disabled

    if add_toughness_button != null:
        add_toughness_button.disabled = disabled

    if add_speed_button != null:
        add_speed_button.disabled = disabled

    if add_endurance_button != null:
        add_endurance_button.disabled = true
        add_endurance_button.visible = false

    if add_focus_button != null:
        add_focus_button.disabled = true
        add_focus_button.visible = false


func _get_inventory_text() -> String:
    if player == null:
        return "Inventory:\nNone"

    if not player.has_method("get_inventory_items"):
        return "Inventory:\nNone"

    var items: Array = player.get_inventory_items()

    if items.is_empty():
        return "Inventory:\nNone"

    var text := "Inventory:\n"

    for item in items:
        var item_name: String = item.get("name", "Unknown Item")
        text += "- " + item_name + "\n"

    return text.strip_edges()


func _player_has_item(item_id: String) -> bool:
    if player == null:
        return false

    if not player.has_method("has_inventory_item"):
        return false

    return player.has_inventory_item(item_id)


func _spend_stat_point(stat_id: String) -> void:
    if player == null:
        return

    if not player.has_method("spend_stat_point"):
        return

    var spent: bool = player.spend_stat_point(stat_id)

    if spent:
        _update_hud()
        _update_character_screen()


func _on_add_might_button_pressed() -> void:
    _spend_stat_point("might")


func _on_add_agility_button_pressed() -> void:
    _spend_stat_point("agility")


func _on_add_toughness_button_pressed() -> void:
    _spend_stat_point("toughness")


func _on_add_speed_button_pressed() -> void:
    _spend_stat_point("speed")


func _on_equip_weapon_button_pressed() -> void:
    if player == null:
        return

    if not player.has_method("equip_weapon"):
        return

    if not _player_has_item("club"):
        return

    player.equip_weapon("club")
    _update_hud()
    _update_character_screen()


func _on_equip_armor_button_pressed() -> void:
    print("Armor equipment is not active yet.")


func _on_equip_accessory_button_pressed() -> void:
    print("Accessory equipment is not active yet.")


func _on_close_button_pressed() -> void:
    close_character_screen()

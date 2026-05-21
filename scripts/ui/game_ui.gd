extends CanvasLayer

const HOTBAR_SLOT_COUNT: int = 5

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

@onready var attack_label: Label = find_child("atk_lbl", true, false) as Label
@onready var defense_label: Label = find_child("def_lbl", true, false) as Label

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

@onready var save_prompt: Control = get_node_or_null("SavePrompt") as Control
@onready var save_prompt_message_label: Label = get_node_or_null("SavePrompt/Panel/MessageLabel") as Label
@onready var save_yes_button: Button = get_node_or_null("SavePrompt/Panel/YesButton") as Button
@onready var save_no_button: Button = get_node_or_null("SavePrompt/Panel/NoButton") as Button

var player: Node = null
var pending_save_player: Node = null

var hud_hotbar_layer: Control = null
var hud_hotbar_container: HBoxContainer = null
var hud_hotbar_buttons: Array[Button] = []

var sheet_hotbar_container: VBoxContainer = null
var sheet_hotbar_option_buttons: Array[OptionButton] = []
var sheet_hotbar_clear_buttons: Array[Button] = []


func _ready() -> void:
    add_to_group("interaction_ui")

    player = get_tree().get_first_node_in_group("player")

    character_screen.visible = false
    interaction_prompt.visible = false

    if save_prompt != null:
        save_prompt.visible = false

    _create_hotbar_hud()
    _create_hotbar_assignment_panel()
    _hide_locked_resources_and_stats()
    _connect_buttons()
    _update_hud()
    _update_character_screen()


func _unhandled_input(event: InputEvent) -> void:
    if save_prompt != null and save_prompt.visible:
        return

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


func show_save_prompt(save_player: Node, message: String = "Do you want to save your game?") -> void:
    pending_save_player = save_player

    if save_prompt == null:
        print("Save prompt UI is missing.")
        return

    if save_prompt_message_label != null:
        save_prompt_message_label.text = message

    character_screen.visible = false
    interaction_prompt.visible = false
    save_prompt.visible = true


func hide_save_prompt() -> void:
    pending_save_player = null

    if save_prompt != null:
        save_prompt.visible = false


func toggle_character_screen() -> void:
    if save_prompt != null and save_prompt.visible:
        return

    character_screen.visible = not character_screen.visible

    if character_screen.visible:
        _refresh_player_reference()
        _update_character_screen()


func open_character_screen() -> void:
    if save_prompt != null and save_prompt.visible:
        return

    character_screen.visible = true
    _refresh_player_reference()
    _update_character_screen()


func close_character_screen() -> void:
    character_screen.visible = false


func _create_hotbar_hud() -> void:
    if hud_hotbar_container != null:
        return

    hud_hotbar_layer = Control.new()
    hud_hotbar_layer.name = "HotbarHudLayer"
    hud_hotbar_layer.anchor_left = 0.0
    hud_hotbar_layer.anchor_right = 1.0
    hud_hotbar_layer.anchor_top = 0.0
    hud_hotbar_layer.anchor_bottom = 1.0
    hud_hotbar_layer.offset_left = 0.0
    hud_hotbar_layer.offset_right = 0.0
    hud_hotbar_layer.offset_top = 0.0
    hud_hotbar_layer.offset_bottom = 0.0
    hud_hotbar_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

    add_child(hud_hotbar_layer)

    hud_hotbar_container = HBoxContainer.new()
    hud_hotbar_container.name = "HotbarPanel"

    hud_hotbar_container.anchor_left = 0.0
    hud_hotbar_container.anchor_right = 0.0
    hud_hotbar_container.anchor_top = 1.0
    hud_hotbar_container.anchor_bottom = 1.0

    hud_hotbar_container.offset_left = 16.0
    hud_hotbar_container.offset_right = 396.0
    hud_hotbar_container.offset_top = -72.0
    hud_hotbar_container.offset_bottom = -16.0

    hud_hotbar_container.alignment = BoxContainer.ALIGNMENT_BEGIN
    hud_hotbar_container.mouse_filter = Control.MOUSE_FILTER_STOP

    hud_hotbar_layer.add_child(hud_hotbar_container)

    hud_hotbar_buttons.clear()

    for slot_number in range(1, HOTBAR_SLOT_COUNT + 1):
        var button := Button.new()
        button.name = "HotbarSlot" + str(slot_number)
        button.custom_minimum_size = Vector2(68.0, 52.0)
        button.text = str(slot_number) + "\nEmpty"
        button.focus_mode = Control.FOCUS_NONE
        button.pressed.connect(_on_hud_hotbar_button_pressed.bind(slot_number))

        hud_hotbar_container.add_child(button)
        hud_hotbar_buttons.append(button)


func _create_hotbar_assignment_panel() -> void:
    if sheet_hotbar_container != null:
        return

    if character_panel == null:
        return

    sheet_hotbar_container = VBoxContainer.new()
    sheet_hotbar_container.name = "HotbarAssignmentPanel"

    sheet_hotbar_container.anchor_left = 1.0
    sheet_hotbar_container.anchor_right = 1.0
    sheet_hotbar_container.anchor_top = 1.0
    sheet_hotbar_container.anchor_bottom = 1.0

    sheet_hotbar_container.offset_left = -320.0
    sheet_hotbar_container.offset_right = -16.0
    sheet_hotbar_container.offset_top = -210.0
    sheet_hotbar_container.offset_bottom = -16.0

    sheet_hotbar_container.custom_minimum_size = Vector2(300.0, 190.0)

    var title := Label.new()
    title.name = "HotbarAssignmentTitle"
    title.text = "Hotbar Assignment"
    sheet_hotbar_container.add_child(title)

    sheet_hotbar_option_buttons.clear()
    sheet_hotbar_clear_buttons.clear()

    for slot_number in range(1, HOTBAR_SLOT_COUNT + 1):
        var row := HBoxContainer.new()
        row.name = "HotbarAssignRow" + str(slot_number)

        var slot_label := Label.new()
        slot_label.text = str(slot_number) + ":"
        slot_label.custom_minimum_size = Vector2(24.0, 24.0)
        row.add_child(slot_label)

        var option_button := OptionButton.new()
        option_button.name = "HotbarAssignOption" + str(slot_number)
        option_button.custom_minimum_size = Vector2(200.0, 24.0)
        option_button.item_selected.connect(_on_hotbar_assignment_selected.bind(slot_number))
        row.add_child(option_button)

        var clear_button := Button.new()
        clear_button.name = "HotbarClearButton" + str(slot_number)
        clear_button.text = "Clear"
        clear_button.focus_mode = Control.FOCUS_NONE
        clear_button.pressed.connect(_on_hotbar_clear_button_pressed.bind(slot_number))
        row.add_child(clear_button)

        sheet_hotbar_container.add_child(row)
        sheet_hotbar_option_buttons.append(option_button)
        sheet_hotbar_clear_buttons.append(clear_button)

    character_panel.add_child(sheet_hotbar_container)


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

    if save_yes_button != null and not save_yes_button.pressed.is_connected(_on_save_yes_button_pressed):
        save_yes_button.pressed.connect(_on_save_yes_button_pressed)

    if save_no_button != null and not save_no_button.pressed.is_connected(_on_save_no_button_pressed):
        save_no_button.pressed.connect(_on_save_no_button_pressed)


func _refresh_player_reference() -> void:
    var current_player := get_tree().get_first_node_in_group("player")

    if current_player != null:
        player = current_player
        return

    if player != null and not is_instance_valid(player):
        player = null


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

        _update_hotbar_hud()
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

    _update_hotbar_hud()


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
        _update_hotbar_assignment_panel()
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
    _update_hotbar_assignment_panel()


func _update_hotbar_hud() -> void:
    if hud_hotbar_buttons.is_empty():
        return

    _refresh_player_reference()

    var slots: Array = []

    if player != null and player.has_method("get_hotbar_slots"):
        slots = player.get_hotbar_slots()

    for index in range(HOTBAR_SLOT_COUNT):
        var button: Button = hud_hotbar_buttons[index]

        if index >= slots.size():
            button.text = str(index + 1) + "\nEmpty"
            button.disabled = true
            continue

        var slot: Dictionary = slots[index]
        var item_id: String = str(slot.get("item_id", ""))
        var cooldown_remaining: float = float(slot.get("cooldown_remaining", 0.0))

        if item_id.strip_edges() == "":
            button.text = str(index + 1) + "\nEmpty"
            button.disabled = true
            continue

        var item_name: String = ItemDatabase.get_item_name(item_id)

        if cooldown_remaining > 0.0:
            button.text = str(index + 1) + "\n" + item_name + "\n" + str(snappedf(cooldown_remaining, 0.1)) + "s"
            button.disabled = true
        else:
            button.text = str(index + 1) + "\n" + item_name
            button.disabled = false


func _update_hotbar_assignment_panel() -> void:
    if sheet_hotbar_option_buttons.is_empty():
        return

    _refresh_player_reference()

    var owned_hotbar_items: Array[Dictionary] = _get_owned_hotbar_usable_items()
    var slots: Array = []

    if player != null and player.has_method("get_hotbar_slots"):
        slots = player.get_hotbar_slots()

    for index in range(HOTBAR_SLOT_COUNT):
        var option_button: OptionButton = sheet_hotbar_option_buttons[index]
        option_button.clear()
        option_button.add_item("Empty")
        option_button.set_item_metadata(0, "")

        for item in owned_hotbar_items:
            var item_id: String = str(item.get("id", ""))
            var item_name: String = str(item.get("name", item_id))

            option_button.add_item(item_name)
            option_button.set_item_metadata(option_button.item_count - 1, item_id)

        var selected_item_id: String = ""

        if index < slots.size():
            var slot: Dictionary = slots[index]
            selected_item_id = str(slot.get("item_id", ""))

        var selected_index: int = 0

        if selected_item_id.strip_edges() != "":
            for option_index in range(option_button.item_count):
                var metadata: Variant = option_button.get_item_metadata(option_index)

                if str(metadata) == selected_item_id:
                    selected_index = option_index
                    break

        option_button.select(selected_index)


func _get_owned_hotbar_usable_items() -> Array[Dictionary]:
    var usable_items: Array[Dictionary] = []

    if player == null:
        return usable_items

    if not player.has_method("get_inventory_items"):
        return usable_items

    var items: Array = player.get_inventory_items()

    for item in items:
        if typeof(item) != TYPE_DICTIONARY:
            continue

        var item_id: String = str(item.get("id", ""))
        var item_name: String = str(item.get("name", item_id))

        if item_id.strip_edges() == "":
            continue

        if not ItemDatabase.is_hotbar_usable(item_id):
            continue

        usable_items.append({
            "id": item_id,
            "name": item_name
        })

    return usable_items


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


func _on_hud_hotbar_button_pressed(slot_number: int) -> void:
    _refresh_player_reference()

    if player == null:
        return

    if not player.has_method("use_hotbar_slot"):
        return

    player.use_hotbar_slot(slot_number)
    _update_hud()
    _update_character_screen()


func _on_hotbar_assignment_selected(selected_index: int, slot_number: int) -> void:
    _refresh_player_reference()

    if player == null:
        return

    if slot_number < 1 or slot_number > HOTBAR_SLOT_COUNT:
        return

    var option_button: OptionButton = sheet_hotbar_option_buttons[slot_number - 1]
    var metadata: Variant = option_button.get_item_metadata(selected_index)
    var item_id: String = str(metadata)

    if item_id.strip_edges() == "":
        if player.has_method("clear_hotbar_slot"):
            player.clear_hotbar_slot(slot_number)
    else:
        if player.has_method("assign_hotbar_slot"):
            player.assign_hotbar_slot(slot_number, item_id)

    _update_hud()
    _update_character_screen()


func _on_hotbar_clear_button_pressed(slot_number: int) -> void:
    _refresh_player_reference()

    if player == null:
        return

    if player.has_method("clear_hotbar_slot"):
        player.clear_hotbar_slot(slot_number)

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


func _on_save_yes_button_pressed() -> void:
    if pending_save_player == null:
        hide_save_prompt()
        return

    var saved := SaveManager.save_game(pending_save_player)

    if saved:
        if pending_save_player.has_method("show_dialogue"):
            pending_save_player.show_dialogue("Game saved.")
    else:
        if pending_save_player.has_method("show_dialogue"):
            pending_save_player.show_dialogue("Save failed.")

    hide_save_prompt()


func _on_save_no_button_pressed() -> void:
    hide_save_prompt()

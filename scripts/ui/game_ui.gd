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

@onready var close_button: Button = $CharacterScreen/Panel/CloseButton

@onready var save_prompt: Control = get_node_or_null("SavePrompt") as Control
@onready var save_prompt_message_label: Label = get_node_or_null("SavePrompt/Panel/MessageLabel") as Label
@onready var save_yes_button: Button = get_node_or_null("SavePrompt/Panel/YesButton") as Button
@onready var save_no_button: Button = get_node_or_null("SavePrompt/Panel/NoButton") as Button

var player: Node = null

var quest_tracker_ui: QuestTrackerUiController = null
var save_prompt_ui: SavePromptUiController = null
var shop_ui: ShopUiController = null
var dialogue_ui: DialogueUiController = null
var hud_ui: HudUiController = null
var character_sheet_list_ui: CharacterSheetListUiController = null
var hotbar_assignment_ui: HotbarAssignmentUiController = null

var equipment_slot_container: VBoxContainer = null
var equipment_slot_option_buttons: Dictionary = {}

var hud_refresh_timer: float = 0.0
var hud_refresh_interval: float = 0.25

var manual_pause_active: bool = false
var character_screen_pause_active: bool = false
var story_dialogue_pause_active: bool = false
var save_prompt_pause_active: bool = false
var shop_pause_active: bool = false


func _ready() -> void:
    add_to_group("interaction_ui")
    print("GameUi ready. Script path: ", get_script().resource_path)
    print("GameUi has show_story_dialogue: ", has_method("show_story_dialogue"))

    process_mode = Node.PROCESS_MODE_ALWAYS
    player = get_tree().get_first_node_in_group("player")
    _ensure_pause_input_action()

    character_screen.visible = false
    interaction_prompt.visible = false

    _create_save_prompt_ui()
    _create_hud_ui()
    _create_hud_quest_panel()
    _create_story_dialogue_panel()
    _create_shop_panel()
    _create_equipment_slot_panel()
    _create_hotbar_assignment_ui()
    _create_character_sheet_list_ui()
    _position_character_sheet_header_labels()
    _hide_locked_resources_and_stats()
    _connect_buttons()
    _update_hud()
    _update_character_screen()
    refresh_quest_display()


func _process(delta: float) -> void:
    if dialogue_ui != null:
        dialogue_ui.process(delta)

    hud_refresh_timer -= delta

    if hud_refresh_timer > 0.0:
        return

    hud_refresh_timer = hud_refresh_interval
    _refresh_player_reference()
    _update_hud()


func _input(event: InputEvent) -> void:
    if _event_is_pause_pressed(event):
        _toggle_manual_pause()
        get_viewport().set_input_as_handled()
        return

    if dialogue_ui != null and dialogue_ui.handle_input(event):
        get_viewport().set_input_as_handled()
        return

    if is_save_prompt_visible():
        return

    if is_shop_visible():
        if event.is_action_pressed("ui_cancel") or event.is_action_pressed("character_screen"):
            hide_shop()
            get_viewport().set_input_as_handled()

        return

    if event.is_action_pressed("character_screen"):
        toggle_character_screen()
        get_viewport().set_input_as_handled()
        return


func _event_is_pause_pressed(event: InputEvent) -> bool:
    if event.is_action_pressed("pause_game"):
        return true

    if event is InputEventKey:
        var key_event := event as InputEventKey

        if not key_event.pressed or key_event.echo:
            return false

        return key_event.keycode == KEY_P or key_event.physical_keycode == KEY_P

    return false


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


func _ensure_pause_input_action() -> void:
    if InputMap.has_action("pause_game"):
        return

    InputMap.add_action("pause_game")

    var pause_key := InputEventKey.new()
    pause_key.physical_keycode = KEY_P

    InputMap.action_add_event("pause_game", pause_key)

    print("Created missing input action: pause_game bound to P")


func _toggle_manual_pause() -> void:
    manual_pause_active = not manual_pause_active
    _refresh_pause_state()

    if manual_pause_active:
        print("Game manually paused.")
    else:
        print("Manual pause cleared.")


func _refresh_pause_state() -> void:
    var should_pause := manual_pause_active \
        or character_screen_pause_active \
        or story_dialogue_pause_active \
        or save_prompt_pause_active \
        or shop_pause_active

    get_tree().paused = should_pause
    print("Pause state refreshed. Paused: ", should_pause)


func _set_character_screen_pause(active: bool) -> void:
    character_screen_pause_active = active
    _refresh_pause_state()


func _set_story_dialogue_pause(active: bool) -> void:
    story_dialogue_pause_active = active
    _refresh_pause_state()


func _set_save_prompt_pause(active: bool) -> void:
    save_prompt_pause_active = active
    _refresh_pause_state()


func _set_shop_pause(active: bool) -> void:
    shop_pause_active = active
    _refresh_pause_state()


func show_prompt(key_text: String = "E") -> void:
    interaction_label.text = key_text
    interaction_prompt.visible = true


func hide_prompt() -> void:
    interaction_prompt.visible = false


func show_story_message(message: String, speaker_name: String = "Echo Spirit") -> void:
    if dialogue_ui == null:
        _create_story_dialogue_panel()

    dialogue_ui.show_story_message(message, speaker_name)


func show_story_dialogue(lines: Array, speaker_name: String = "Echo Spirit") -> void:
    if dialogue_ui == null:
        _create_story_dialogue_panel()

    dialogue_ui.show_story_dialogue(lines, speaker_name)


func hide_story_dialogue() -> void:
    if dialogue_ui == null:
        return

    dialogue_ui.hide_story_dialogue()


func _create_story_dialogue_panel() -> void:
    if dialogue_ui != null:
        return

    dialogue_ui = DialogueUiController.new()
    dialogue_ui.setup(self)


func _create_shop_panel() -> void:
    if shop_ui != null:
        return

    shop_ui = ShopUiController.new()
    shop_ui.setup(self, Callable(self, "_get_player_for_ui_controller"))


func show_shop(shop_keeper: Node, shop_data: Dictionary) -> void:
    if shop_ui == null:
        _create_shop_panel()

    shop_ui.show_shop(shop_keeper, shop_data)


func hide_shop() -> void:
    if shop_ui == null:
        return

    shop_ui.hide_shop()


func is_story_dialogue_active() -> bool:
    if dialogue_ui == null:
        return false

    return dialogue_ui.is_active()


func is_shop_visible() -> bool:
    if shop_ui == null:
        return false

    return shop_ui.is_visible()


func is_save_prompt_visible() -> bool:
    if save_prompt_ui == null:
        return false

    return save_prompt_ui.is_visible()


func should_block_player_interact() -> bool:
    if is_story_dialogue_active():
        return true

    if dialogue_ui != null and dialogue_ui.was_recently_closed():
        return true

    if is_shop_visible():
        return true

    if is_save_prompt_visible():
        return true

    if character_screen != null and character_screen.visible:
        return true

    return false


func refresh_character_display() -> void:
    _refresh_player_reference()
    _update_hud()
    _update_character_screen()
    refresh_quest_display()


func show_save_prompt(save_player: Node, message: String = "Do you want to save your game?") -> void:
    if save_prompt_ui == null:
        _create_save_prompt_ui()

    save_prompt_ui.show_save_prompt(save_player, message)


func hide_save_prompt() -> void:
    if save_prompt_ui == null:
        return

    save_prompt_ui.hide_save_prompt()


func toggle_character_screen() -> void:
    if is_save_prompt_visible():
        return

    if is_shop_visible():
        return

    character_screen.visible = not character_screen.visible
    _set_character_screen_pause(character_screen.visible)

    if character_screen.visible:
        _refresh_player_reference()
        _update_character_screen()
    else:
        _hide_sheet_list()


func open_character_screen() -> void:
    if is_save_prompt_visible():
        return

    if is_shop_visible():
        return

    character_screen.visible = true
    _set_character_screen_pause(true)
    _refresh_player_reference()
    _update_character_screen()


func close_character_screen() -> void:
    character_screen.visible = false
    _hide_sheet_list()
    _set_character_screen_pause(false)


func _create_hud_ui() -> void:
    if hud_ui != null:
        return

    hud_ui = HudUiController.new()
    hud_ui.setup(
        self,
        Callable(self, "_get_player_for_ui_controller"),
        hud_health_label,
        hud_mana_label,
        hud_stamina_label
    )


func _create_save_prompt_ui() -> void:
    if save_prompt_ui != null:
        return

    save_prompt_ui = SavePromptUiController.new()
    save_prompt_ui.setup(
        self,
        save_prompt,
        save_prompt_message_label,
        save_yes_button,
        save_no_button
    )


func _create_hud_quest_panel() -> void:
    if quest_tracker_ui != null:
        return

    quest_tracker_ui = QuestTrackerUiController.new()
    quest_tracker_ui.setup(self)


func _create_character_sheet_list_ui() -> void:
    if character_sheet_list_ui != null:
        return

    character_sheet_list_ui = CharacterSheetListUiController.new()
    character_sheet_list_ui.setup(
        self,
        character_panel,
        Callable(self, "_get_player_for_ui_controller")
    )


func _create_hotbar_assignment_ui() -> void:
    if hotbar_assignment_ui != null:
        return

    hotbar_assignment_ui = HotbarAssignmentUiController.new()
    hotbar_assignment_ui.setup(
        self,
        character_panel,
        Callable(self, "_get_player_for_ui_controller")
    )


func refresh_quest_display() -> void:
    if quest_tracker_ui == null:
        return

    quest_tracker_ui.refresh_quest_display()


func _create_equipment_slot_panel() -> void:
    if equipment_slot_container != null:
        return

    if character_panel == null:
        return

    equipment_slot_container = VBoxContainer.new()
    equipment_slot_container.name = "EquipmentSlotPanel"

    equipment_slot_container.anchor_left = 0.0
    equipment_slot_container.anchor_right = 0.0
    equipment_slot_container.anchor_top = 1.0
    equipment_slot_container.anchor_bottom = 1.0

    equipment_slot_container.offset_left = 24.0
    equipment_slot_container.offset_right = 380.0
    equipment_slot_container.offset_top = -250.0
    equipment_slot_container.offset_bottom = -24.0

    equipment_slot_container.custom_minimum_size = Vector2(350.0, 220.0)

    var title := Label.new()
    title.name = "EquipmentSlotTitle"
    title.text = "Equipment Slots"
    equipment_slot_container.add_child(title)

    equipment_slot_option_buttons.clear()

    _add_equipment_slot_row("Melee Weapon", "melee_weapon")
    _add_equipment_slot_row("Ranged Weapon", "ranged_weapon")
    _add_equipment_slot_row("Armor", "armor")
    _add_equipment_slot_row("Accessory 1", "accessory_1")
    _add_equipment_slot_row("Accessory 2", "accessory_2")

    character_panel.add_child(equipment_slot_container)


func _add_equipment_slot_row(label_text: String, slot_key: String) -> void:
    var row := HBoxContainer.new()
    row.name = "EquipmentRow_" + slot_key

    var label := Label.new()
    label.text = label_text + ":"
    label.custom_minimum_size = Vector2(100.0, 24.0)
    row.add_child(label)

    var option_button := OptionButton.new()
    option_button.name = "EquipmentOption_" + slot_key
    option_button.custom_minimum_size = Vector2(200.0, 24.0)
    option_button.item_selected.connect(_on_equipment_slot_selected.bind(slot_key))
    row.add_child(option_button)

    equipment_slot_container.add_child(row)
    equipment_slot_option_buttons[slot_key] = option_button


func _hide_sheet_list() -> void:
    if character_sheet_list_ui == null:
        return

    character_sheet_list_ui.hide_sheet_list()


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
    if close_button != null and not close_button.pressed.is_connected(_on_close_button_pressed):
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
    var current_player := get_tree().get_first_node_in_group("player")

    if current_player != null:
        player = current_player
        return

    if player != null and not is_instance_valid(player):
        player = null


func _get_player_for_ui_controller() -> Node:
    _refresh_player_reference()
    return player


func _get_stats() -> CharacterStats:
    _refresh_player_reference()

    if player == null:
        return null

    if not player.has_method("get_character_stats"):
        return null

    return player.get_character_stats()


func _update_hud() -> void:
    if hud_ui == null:
        return

    hud_ui.update_hud()


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
        _set_stat_buttons_disabled(true)
        _update_equipment_slot_panel()
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
    _set_stat_buttons_disabled(stats.stat_points <= 0)
    _update_equipment_slot_panel()
    _update_hotbar_assignment_panel()


func _update_equipment_slot_panel() -> void:
    if equipment_slot_option_buttons.is_empty():
        return

    _refresh_player_reference()

    _update_equipment_option_button("melee_weapon", ItemDatabase.EQUIPMENT_SLOT_MELEE_WEAPON, _get_equipped_item_id_for_slot("melee_weapon"))
    _update_equipment_option_button("ranged_weapon", ItemDatabase.EQUIPMENT_SLOT_RANGED_WEAPON, _get_equipped_item_id_for_slot("ranged_weapon"))
    _update_equipment_option_button("armor", ItemDatabase.EQUIPMENT_SLOT_ARMOR, _get_equipped_item_id_for_slot("armor"))
    _update_equipment_option_button("accessory_1", ItemDatabase.EQUIPMENT_SLOT_ACCESSORY, _get_equipped_item_id_for_slot("accessory_1"))
    _update_equipment_option_button("accessory_2", ItemDatabase.EQUIPMENT_SLOT_ACCESSORY, _get_equipped_item_id_for_slot("accessory_2"))


func _update_equipment_option_button(slot_key: String, equipment_slot: String, selected_item_id: String) -> void:
    if not equipment_slot_option_buttons.has(slot_key):
        return

    var option_button: OptionButton = equipment_slot_option_buttons[slot_key]
    option_button.clear()
    option_button.add_item("None")
    option_button.set_item_metadata(0, "")

    var owned_items: Array[Dictionary] = _get_owned_equipment_items_for_slot(equipment_slot)

    for item in owned_items:
        var item_id: String = str(item.get("id", ""))
        var item_name: String = str(item.get("name", item_id))

        option_button.add_item(item_name)
        option_button.set_item_metadata(option_button.item_count - 1, item_id)

    var selected_index: int = 0

    if selected_item_id.strip_edges() != "":
        for option_index in range(option_button.item_count):
            var metadata: Variant = option_button.get_item_metadata(option_index)

            if str(metadata) == selected_item_id:
                selected_index = option_index
                break

    option_button.select(selected_index)


func _get_owned_equipment_items_for_slot(equipment_slot: String) -> Array[Dictionary]:
    var matching_items: Array[Dictionary] = []

    if player == null:
        return matching_items

    if not player.has_method("get_inventory_items"):
        return matching_items

    var items: Array = player.get_inventory_items()

    for item in items:
        if typeof(item) != TYPE_DICTIONARY:
            continue

        var item_id: String = str(item.get("id", ""))
        var item_name: String = str(item.get("name", item_id))

        if item_id.strip_edges() == "":
            continue

        if ItemDatabase.get_equipment_slot(item_id) != equipment_slot:
            continue

        matching_items.append({
            "id": item_id,
            "name": item_name
        })

    return matching_items


func _get_equipped_item_id_for_slot(slot_key: String) -> String:
    var stats := _get_stats()

    if stats == null:
        return ""

    match slot_key:
        "melee_weapon":
            return stats.equipped_melee_weapon_id
        "ranged_weapon":
            return stats.equipped_ranged_weapon_id
        "armor":
            return stats.equipped_armor_id
        "accessory_1":
            return stats.equipped_accessory_1_id
        "accessory_2":
            return stats.equipped_accessory_2_id

    return ""


func _update_hotbar_assignment_panel() -> void:
    if hotbar_assignment_ui == null:
        return

    hotbar_assignment_ui.update_hotbar_assignment_panel()


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


func _on_equipment_slot_selected(selected_index: int, slot_key: String) -> void:
    _refresh_player_reference()

    if player == null:
        return

    if not equipment_slot_option_buttons.has(slot_key):
        return

    var option_button: OptionButton = equipment_slot_option_buttons[slot_key]
    var metadata: Variant = option_button.get_item_metadata(selected_index)
    var item_id: String = str(metadata)

    match slot_key:
        "melee_weapon":
            if player.has_method("equip_melee_weapon"):
                player.equip_melee_weapon(item_id)

        "ranged_weapon":
            if player.has_method("equip_ranged_weapon"):
                player.equip_ranged_weapon(item_id)

        "armor":
            if player.has_method("equip_armor"):
                player.equip_armor(item_id)

        "accessory_1":
            if player.has_method("equip_accessory_1"):
                player.equip_accessory_1(item_id)

        "accessory_2":
            if player.has_method("equip_accessory_2"):
                player.equip_accessory_2(item_id)

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


func _on_close_button_pressed() -> void:
    close_character_screen()

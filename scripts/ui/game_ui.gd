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

var hud_hotbar_layer: Control = null
var hud_hotbar_container: HBoxContainer = null
var hud_hotbar_buttons: Array[Button] = []

var hud_info_panel: VBoxContainer = null
var hud_name_label: Label = null
var hud_level_label: Label = null
var hud_resource_row: HBoxContainer = null

var quest_tracker_ui: QuestTrackerUiController = null
var save_prompt_ui: SavePromptUiController = null
var shop_ui: ShopUiController = null

var equipment_slot_container: VBoxContainer = null
var equipment_slot_option_buttons: Dictionary = {}

var sheet_hotbar_container: VBoxContainer = null
var sheet_hotbar_option_buttons: Array[OptionButton] = []
var sheet_hotbar_clear_buttons: Array[Button] = []

var sheet_list_button_container: HBoxContainer = null
var inventory_list_button: Button = null
var currency_list_button: Button = null
var faction_list_button: Button = null
var active_sheet_list_title: String = ""

var sheet_list_panel: Panel = null
var sheet_list_title_label: Label = null
var sheet_list_content_label: Label = null
var sheet_list_close_button: Button = null

var hud_refresh_timer: float = 0.0
var hud_refresh_interval: float = 0.25

var story_dialogue_layer: Control = null
var story_dialogue_panel: Panel = null
var story_dialogue_speaker_label: Label = null
var story_dialogue_message_label: Label = null
var story_dialogue_continue_label: Label = null

var story_dialogue_lines: Array[String] = []
var story_dialogue_index: int = 0
var story_dialogue_speaker_name: String = ""
var story_dialogue_active: bool = false
var story_dialogue_recently_closed_timer: float = 0.0

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
    _create_hotbar_hud()
    _create_hud_info_panel()
    _create_hud_quest_panel()
    _create_story_dialogue_panel()
    _create_shop_panel()
    _create_equipment_slot_panel()
    _create_hotbar_assignment_panel()
    _create_character_sheet_list_buttons()
    _create_character_sheet_list_panel()
    _position_character_sheet_header_labels()
    _hide_old_equipment_controls()
    _hide_locked_resources_and_stats()
    _connect_buttons()
    _update_hud()
    _update_character_screen()
    refresh_quest_display()


func _process(delta: float) -> void:
    if story_dialogue_recently_closed_timer > 0.0:
        story_dialogue_recently_closed_timer -= delta

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

    if story_dialogue_active:
        if event is InputEventKey:
            var key_event := event as InputEventKey

            if key_event.pressed and not key_event.echo:
                print("Story dialogue key pressed: ", key_event.keycode)

        if _event_is_dialogue_continue_pressed(event):
            print("Advancing story dialogue.")
            _advance_story_dialogue()
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


func _event_is_dialogue_continue_pressed(event: InputEvent) -> bool:
    if event.is_action_pressed("dialogue_continue"):
        return true

    if event.is_action_pressed("interact"):
        return true

    if event.is_action_pressed("ui_accept"):
        return true

    if event is InputEventKey:
        var key_event := event as InputEventKey

        if not key_event.pressed or key_event.echo:
            return false

        if key_event.keycode == KEY_E or key_event.physical_keycode == KEY_E:
            return true

        if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
            return true

        if key_event.keycode == KEY_SPACE:
            return true

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
    show_story_dialogue([message], speaker_name)


func show_story_dialogue(lines: Array, speaker_name: String = "Echo Spirit") -> void:
    if is_save_prompt_visible():
        return

    if is_shop_visible():
        hide_shop()

    story_dialogue_lines.clear()

    for line in lines:
        var clean_line := str(line).strip_edges()

        if clean_line == "":
            continue

        story_dialogue_lines.append(clean_line)

    if story_dialogue_lines.is_empty():
        return

    story_dialogue_speaker_name = speaker_name
    story_dialogue_index = 0
    story_dialogue_active = true
    story_dialogue_recently_closed_timer = 0.0
    _set_story_dialogue_pause(true)

    print("Story dialogue opened. Line count: ", story_dialogue_lines.size())

    if character_screen != null:
        character_screen.visible = false
        _set_character_screen_pause(false)

    if interaction_prompt != null:
        interaction_prompt.visible = false

    if story_dialogue_layer != null:
        story_dialogue_layer.visible = true

    _display_current_story_dialogue_line()


func hide_story_dialogue() -> void:
    story_dialogue_active = false
    story_dialogue_lines.clear()
    story_dialogue_index = 0
    story_dialogue_speaker_name = ""

    if story_dialogue_layer != null:
        story_dialogue_layer.visible = false

    _set_story_dialogue_pause(false)
    story_dialogue_recently_closed_timer = 0.25

    print("Story dialogue closed.")


func _create_story_dialogue_panel() -> void:
    if story_dialogue_layer != null:
        return

    story_dialogue_layer = Control.new()
    story_dialogue_layer.name = "StoryDialogueLayer"
    story_dialogue_layer.anchor_left = 0.0
    story_dialogue_layer.anchor_right = 1.0
    story_dialogue_layer.anchor_top = 0.0
    story_dialogue_layer.anchor_bottom = 1.0
    story_dialogue_layer.offset_left = 0.0
    story_dialogue_layer.offset_right = 0.0
    story_dialogue_layer.offset_top = 0.0
    story_dialogue_layer.offset_bottom = 0.0
    story_dialogue_layer.mouse_filter = Control.MOUSE_FILTER_STOP
    story_dialogue_layer.visible = false

    add_child(story_dialogue_layer)

    story_dialogue_panel = Panel.new()
    story_dialogue_panel.name = "StoryDialoguePanel"

    story_dialogue_panel.anchor_left = 0.5
    story_dialogue_panel.anchor_right = 0.5
    story_dialogue_panel.anchor_top = 1.0
    story_dialogue_panel.anchor_bottom = 1.0

    story_dialogue_panel.offset_left = -360.0
    story_dialogue_panel.offset_right = 360.0
    story_dialogue_panel.offset_top = -180.0
    story_dialogue_panel.offset_bottom = -32.0

    story_dialogue_panel.custom_minimum_size = Vector2(720.0, 148.0)
    story_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP

    story_dialogue_layer.add_child(story_dialogue_panel)

    var margin := MarginContainer.new()
    margin.name = "StoryDialogueMargin"
    margin.anchor_left = 0.0
    margin.anchor_right = 1.0
    margin.anchor_top = 0.0
    margin.anchor_bottom = 1.0
    margin.offset_left = 16.0
    margin.offset_right = -16.0
    margin.offset_top = 12.0
    margin.offset_bottom = -12.0

    story_dialogue_panel.add_child(margin)

    var vbox := VBoxContainer.new()
    vbox.name = "StoryDialogueVBox"
    margin.add_child(vbox)

    story_dialogue_speaker_label = Label.new()
    story_dialogue_speaker_label.name = "SpeakerLabel"
    story_dialogue_speaker_label.text = "Echo Spirit"
    story_dialogue_speaker_label.add_theme_font_size_override("font_size", 18)
    vbox.add_child(story_dialogue_speaker_label)

    story_dialogue_message_label = Label.new()
    story_dialogue_message_label.name = "MessageLabel"
    story_dialogue_message_label.text = ""
    story_dialogue_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    story_dialogue_message_label.custom_minimum_size = Vector2(680.0, 72.0)
    story_dialogue_message_label.add_theme_font_size_override("font_size", 16)
    vbox.add_child(story_dialogue_message_label)

    story_dialogue_continue_label = Label.new()
    story_dialogue_continue_label.name = "ContinueLabel"
    story_dialogue_continue_label.text = "Press E to continue"
    story_dialogue_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    story_dialogue_continue_label.add_theme_font_size_override("font_size", 12)
    vbox.add_child(story_dialogue_continue_label)


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
    return story_dialogue_active


func is_shop_visible() -> bool:
    if shop_ui == null:
        return false

    return shop_ui.is_visible()


func is_save_prompt_visible() -> bool:
    if save_prompt_ui == null:
        return false

    return save_prompt_ui.is_visible()


func should_block_player_interact() -> bool:
    if story_dialogue_active:
        return true

    if story_dialogue_recently_closed_timer > 0.0:
        return true

    if is_shop_visible():
        return true

    if is_save_prompt_visible():
        return true

    if character_screen != null and character_screen.visible:
        return true

    return false


func _advance_story_dialogue() -> void:
    if not story_dialogue_active:
        return

    story_dialogue_index += 1

    if story_dialogue_index >= story_dialogue_lines.size():
        hide_story_dialogue()
        return

    _display_current_story_dialogue_line()


func _display_current_story_dialogue_line() -> void:
    if not story_dialogue_active:
        return

    if story_dialogue_index < 0 or story_dialogue_index >= story_dialogue_lines.size():
        hide_story_dialogue()
        return

    if story_dialogue_speaker_label != null:
        story_dialogue_speaker_label.text = story_dialogue_speaker_name

    if story_dialogue_message_label != null:
        story_dialogue_message_label.text = story_dialogue_lines[story_dialogue_index]

    if story_dialogue_continue_label != null:
        if story_dialogue_index >= story_dialogue_lines.size() - 1:
            story_dialogue_continue_label.text = "Press E to close"
        else:
            story_dialogue_continue_label.text = "Press E to continue"


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


func _create_hud_info_panel() -> void:
    if hud_info_panel != null:
        return

    var hud_parent := get_node_or_null("HUD") as Control

    if hud_parent == null:
        push_warning("Cannot create HUD info panel. HUD node is missing.")
        return

    hud_info_panel = VBoxContainer.new()
    hud_info_panel.name = "HudInfoPanel"

    hud_info_panel.anchor_left = 0.0
    hud_info_panel.anchor_right = 0.0
    hud_info_panel.anchor_top = 0.0
    hud_info_panel.anchor_bottom = 0.0

    hud_info_panel.offset_left = 16.0
    hud_info_panel.offset_top = 12.0
    hud_info_panel.offset_right = 520.0
    hud_info_panel.offset_bottom = 120.0

    hud_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

    hud_parent.add_child(hud_info_panel)

    hud_name_label = Label.new()
    hud_name_label.name = "HudNameLabel"
    hud_name_label.text = "Gene Ambrose"
    hud_name_label.add_theme_font_size_override("font_size", 18)
    hud_info_panel.add_child(hud_name_label)

    hud_level_label = Label.new()
    hud_level_label.name = "HudLevelLabel"
    hud_level_label.text = "Level 0"
    hud_level_label.add_theme_font_size_override("font_size", 14)
    hud_info_panel.add_child(hud_level_label)

    hud_resource_row = HBoxContainer.new()
    hud_resource_row.name = "HudResourceRow"
    hud_resource_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_info_panel.add_child(hud_resource_row)

    _move_existing_resource_label_to_hud_row(hud_health_label)
    _move_existing_resource_label_to_hud_row(hud_mana_label)
    _move_existing_resource_label_to_hud_row(hud_stamina_label)


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


func _move_existing_resource_label_to_hud_row(label: Label) -> void:
    if label == null:
        return

    if hud_resource_row == null:
        return

    var current_parent := label.get_parent()

    if current_parent != null:
        current_parent.remove_child(label)

    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.custom_minimum_size = Vector2(130.0, 24.0)

    hud_resource_row.add_child(label)


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

    sheet_hotbar_container.offset_left = -340.0
    sheet_hotbar_container.offset_right = -16.0
    sheet_hotbar_container.offset_top = -210.0
    sheet_hotbar_container.offset_bottom = -16.0

    sheet_hotbar_container.custom_minimum_size = Vector2(320.0, 190.0)

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
        option_button.custom_minimum_size = Vector2(210.0, 24.0)
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


func _create_character_sheet_list_buttons() -> void:
    if sheet_list_button_container != null:
        return

    if character_panel == null:
        return

    sheet_list_button_container = HBoxContainer.new()
    sheet_list_button_container.name = "SheetListButtonPanel"

    sheet_list_button_container.anchor_left = 1.0
    sheet_list_button_container.anchor_right = 1.0
    sheet_list_button_container.anchor_top = 0.0
    sheet_list_button_container.anchor_bottom = 0.0

    sheet_list_button_container.offset_left = -360.0
    sheet_list_button_container.offset_right = -40.0
    sheet_list_button_container.offset_top = 72.0
    sheet_list_button_container.offset_bottom = 112.0

    sheet_list_button_container.custom_minimum_size = Vector2(320.0, 36.0)

    inventory_list_button = Button.new()
    inventory_list_button.name = "InventoryListButton"
    inventory_list_button.text = "Inventory"
    inventory_list_button.custom_minimum_size = Vector2(100.0, 32.0)
    inventory_list_button.focus_mode = Control.FOCUS_NONE
    inventory_list_button.pressed.connect(_on_inventory_list_button_pressed)
    sheet_list_button_container.add_child(inventory_list_button)

    currency_list_button = Button.new()
    currency_list_button.name = "CurrencyListButton"
    currency_list_button.text = "Currency"
    currency_list_button.custom_minimum_size = Vector2(100.0, 32.0)
    currency_list_button.focus_mode = Control.FOCUS_NONE
    currency_list_button.pressed.connect(_on_currency_list_button_pressed)
    sheet_list_button_container.add_child(currency_list_button)

    faction_list_button = Button.new()
    faction_list_button.name = "FactionListButton"
    faction_list_button.text = "Faction"
    faction_list_button.custom_minimum_size = Vector2(100.0, 32.0)
    faction_list_button.focus_mode = Control.FOCUS_NONE
    faction_list_button.visible = false
    faction_list_button.disabled = true
    sheet_list_button_container.add_child(faction_list_button)

    character_panel.add_child(sheet_list_button_container)


func _create_character_sheet_list_panel() -> void:
    if sheet_list_panel != null:
        return

    if character_panel == null:
        return

    sheet_list_panel = Panel.new()
    sheet_list_panel.name = "SheetListPanel"

    sheet_list_panel.anchor_left = 1.0
    sheet_list_panel.anchor_right = 1.0
    sheet_list_panel.anchor_top = 0.0
    sheet_list_panel.anchor_bottom = 0.0

    sheet_list_panel.offset_left = -360.0
    sheet_list_panel.offset_right = -40.0
    sheet_list_panel.offset_top = 116.0
    sheet_list_panel.offset_bottom = 455.0

    sheet_list_panel.visible = false
    sheet_list_panel.custom_minimum_size = Vector2(320.0, 330.0)

    character_panel.add_child(sheet_list_panel)

    var margin := MarginContainer.new()
    margin.name = "SheetListMargin"
    margin.anchor_left = 0.0
    margin.anchor_right = 1.0
    margin.anchor_top = 0.0
    margin.anchor_bottom = 1.0
    margin.offset_left = 10.0
    margin.offset_right = -10.0
    margin.offset_top = 10.0
    margin.offset_bottom = -10.0
    sheet_list_panel.add_child(margin)

    var vbox := VBoxContainer.new()
    vbox.name = "SheetListVBox"
    margin.add_child(vbox)

    sheet_list_title_label = Label.new()
    sheet_list_title_label.name = "SheetListTitleLabel"
    sheet_list_title_label.text = "List"
    sheet_list_title_label.add_theme_font_size_override("font_size", 16)
    vbox.add_child(sheet_list_title_label)

    var scroll := ScrollContainer.new()
    scroll.name = "SheetListScroll"
    scroll.custom_minimum_size = Vector2(290.0, 255.0)
    vbox.add_child(scroll)

    sheet_list_content_label = Label.new()
    sheet_list_content_label.name = "SheetListContentLabel"
    sheet_list_content_label.text = ""
    sheet_list_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    sheet_list_content_label.custom_minimum_size = Vector2(270.0, 245.0)
    scroll.add_child(sheet_list_content_label)

    sheet_list_close_button = Button.new()
    sheet_list_close_button.name = "SheetListCloseButton"
    sheet_list_close_button.text = "Close"
    sheet_list_close_button.focus_mode = Control.FOCUS_NONE
    sheet_list_close_button.pressed.connect(_on_sheet_list_close_button_pressed)
    vbox.add_child(sheet_list_close_button)


func _show_sheet_list(title: String, content: String) -> void:
    if sheet_list_panel == null:
        return

    active_sheet_list_title = title

    if sheet_list_title_label != null:
        sheet_list_title_label.text = title

    if sheet_list_content_label != null:
        sheet_list_content_label.text = content

    sheet_list_panel.visible = true


func _hide_sheet_list() -> void:
    active_sheet_list_title = ""

    if sheet_list_panel != null:
        sheet_list_panel.visible = false


func _get_inventory_list_text() -> String:
    if player == null:
        return "No inventory items."

    if not player.has_method("get_inventory_items"):
        return "No inventory items."

    var items: Array = player.get_inventory_items()

    if items.is_empty():
        return "No inventory items."

    var text := ""

    for item in items:
        if typeof(item) != TYPE_DICTIONARY:
            continue

        var item_name: String = str(item.get("name", "Unknown Item"))
        var quantity: int = int(item.get("quantity", 1))

        if quantity > 1:
            text += "- " + item_name + " x" + str(quantity) + "\n"
        else:
            text += "- " + item_name + "\n"

    return text.strip_edges()


func _get_currency_list_text() -> String:
    if player == null:
        return "No currencies discovered."

    if not player.has_method("get_discovered_currency_rows"):
        return "No currencies discovered."

    var currency_rows: Array = player.get_discovered_currency_rows()

    if currency_rows.is_empty():
        return "No currencies discovered."

    var text := ""

    for row in currency_rows:
        if typeof(row) != TYPE_DICTIONARY:
            continue

        var currency_name: String = str(row.get("name", "Unknown Currency"))
        var currency_amount: int = int(row.get("amount", 0))

        text += "- " + currency_name + ": " + str(currency_amount) + "\n"

    return text.strip_edges()


func _hide_old_equipment_controls() -> void:
    if weapon_slot_label != null:
        weapon_slot_label.visible = false

    if armor_slot_label != null:
        armor_slot_label.visible = false

    if accessory_slot_label != null:
        accessory_slot_label.visible = false

    if equip_weapon_button != null:
        equip_weapon_button.visible = false
        equip_weapon_button.disabled = true

    if equip_armor_button != null:
        equip_armor_button.visible = false
        equip_armor_button.disabled = true

    if equip_accessory_button != null:
        equip_accessory_button.visible = false
        equip_accessory_button.disabled = true


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
    var stats := _get_stats()

    if stats == null:
        if hud_name_label != null:
            hud_name_label.text = "No Character"

        if hud_level_label != null:
            hud_level_label.text = "Level --"

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

    if hud_name_label != null:
        hud_name_label.text = stats.character_name

    if hud_level_label != null:
        hud_level_label.text = "Level " + str(stats.level)

    if hud_health_label != null:
        hud_health_label.visible = true
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

        if inventory_label != null:
            inventory_label.text = "Inventory:\nNone"
            inventory_label.visible = false

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

    if inventory_label != null:
        inventory_label.text = _get_inventory_text()
        inventory_label.visible = false

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
        if typeof(item) != TYPE_DICTIONARY:
            continue

        var item_name: String = str(item.get("name", "Unknown Item"))
        var quantity: int = int(item.get("quantity", 1))

        if quantity > 1:
            text += "- " + item_name + " x" + str(quantity) + "\n"
        else:
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


func _on_inventory_list_button_pressed() -> void:
    _refresh_player_reference()

    if sheet_list_panel != null and sheet_list_panel.visible and active_sheet_list_title == "Inventory":
        _hide_sheet_list()
        return

    _show_sheet_list("Inventory", _get_inventory_list_text())


func _on_currency_list_button_pressed() -> void:
    _refresh_player_reference()

    if sheet_list_panel != null and sheet_list_panel.visible and active_sheet_list_title == "Currency":
        _hide_sheet_list()
        return

    _show_sheet_list("Currency", _get_currency_list_text())


func _on_sheet_list_close_button_pressed() -> void:
    _hide_sheet_list()


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
    print("Old equip weapon button is hidden. Use equipment slot dropdowns.")


func _on_equip_armor_button_pressed() -> void:
    print("Old equip armor button is hidden. Use equipment slot dropdowns.")


func _on_equip_accessory_button_pressed() -> void:
    print("Old equip accessory button is hidden. Use equipment slot dropdowns.")


func _on_close_button_pressed() -> void:
    close_character_screen()

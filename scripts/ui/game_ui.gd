extends CanvasLayer

@onready var hud_health_label: Label = get_node_or_null("HUD/Health") as Label
@onready var hud_mana_label: Label = get_node_or_null("HUD/Mana") as Label
@onready var hud_stamina_label: Label = get_node_or_null("HUD/Stamina") as Label

@onready var character_screen: Control = $CharacterScreen
@onready var character_panel: Panel = $CharacterScreen/Panel

var player: Node = null

var quest_tracker_ui: QuestTrackerUiController = null
var save_prompt_ui: SavePromptUiController = null
var shop_ui: ShopUiController = null
var dialogue_ui: DialogueUiController = null
var hud_ui: HudUiController = null
var character_sheet_list_ui: CharacterSheetListUiController = null
var hotbar_assignment_ui: HotbarAssignmentUiController = null
var equipment_slot_ui: EquipmentSlotUiController = null
var character_sheet_stats_ui: CharacterSheetStatsUiController = null
var character_sheet_buttons_ui: CharacterSheetButtonsUiController = null
var interaction_prompt_ui: InteractionPromptUiController = null

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

    _create_interaction_prompt_ui()
    _create_save_prompt_ui()
    _create_hud_ui()
    _create_hud_quest_panel()
    _create_story_dialogue_panel()
    _create_shop_panel()
    _create_character_sheet_stats_ui()
    _create_character_sheet_buttons_ui()
    _create_equipment_slot_ui()
    _create_hotbar_assignment_ui()
    _create_character_sheet_list_ui()
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
    if interaction_prompt_ui == null:
        _create_interaction_prompt_ui()

    interaction_prompt_ui.show_prompt(key_text)


func hide_prompt() -> void:
    if interaction_prompt_ui == null:
        return

    interaction_prompt_ui.hide_prompt()


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


func _create_interaction_prompt_ui() -> void:
    if interaction_prompt_ui != null:
        return

    interaction_prompt_ui = InteractionPromptUiController.new()
    interaction_prompt_ui.setup(self)


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
    save_prompt_ui.setup(self)


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


func _create_equipment_slot_ui() -> void:
    if equipment_slot_ui != null:
        return

    equipment_slot_ui = EquipmentSlotUiController.new()
    equipment_slot_ui.setup(
        self,
        character_panel,
        Callable(self, "_get_player_for_ui_controller")
    )


func _create_character_sheet_stats_ui() -> void:
    if character_sheet_stats_ui != null:
        return

    character_sheet_stats_ui = CharacterSheetStatsUiController.new()
    character_sheet_stats_ui.setup(character_panel)


func _create_character_sheet_buttons_ui() -> void:
    if character_sheet_buttons_ui != null:
        return

    character_sheet_buttons_ui = CharacterSheetButtonsUiController.new()
    character_sheet_buttons_ui.setup(
        self,
        character_panel,
        Callable(self, "_get_player_for_ui_controller")
    )


func refresh_quest_display() -> void:
    if quest_tracker_ui == null:
        return

    quest_tracker_ui.refresh_quest_display()


func _hide_sheet_list() -> void:
    if character_sheet_list_ui == null:
        return

    character_sheet_list_ui.hide_sheet_list()


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

    if character_sheet_stats_ui != null:
        character_sheet_stats_ui.update_character_sheet(stats)

    if character_sheet_buttons_ui != null:
        character_sheet_buttons_ui.update_stat_buttons(stats)

    _update_equipment_slot_panel()
    _update_hotbar_assignment_panel()


func _update_equipment_slot_panel() -> void:
    if equipment_slot_ui == null:
        return

    equipment_slot_ui.update_equipment_slot_panel()


func _update_hotbar_assignment_panel() -> void:
    if hotbar_assignment_ui == null:
        return

    hotbar_assignment_ui.update_hotbar_assignment_panel()

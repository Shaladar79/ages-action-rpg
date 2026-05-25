extends RefCounted
class_name DialogueUiController

var root_ui: CanvasLayer = null

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


func setup(ui_root: CanvasLayer) -> void:
    root_ui = ui_root
    _create_story_dialogue_panel()


func process(delta: float) -> void:
    if story_dialogue_recently_closed_timer > 0.0:
        story_dialogue_recently_closed_timer -= delta


func handle_input(event: InputEvent) -> bool:
    if not story_dialogue_active:
        return false

    if event is InputEventKey:
        var key_event := event as InputEventKey

        if key_event.pressed and not key_event.echo:
            print("Story dialogue key pressed: ", key_event.keycode)

    if _event_is_dialogue_continue_pressed(event):
        print("Advancing story dialogue.")
        _advance_story_dialogue()
        return true

    return true


func show_story_message(message: String, speaker_name: String = "Echo Spirit") -> void:
    show_story_dialogue([message], speaker_name)


func show_story_dialogue(lines: Array, speaker_name: String = "Echo Spirit") -> void:
    if root_ui != null:
        if root_ui.has_method("is_save_prompt_visible") and root_ui.is_save_prompt_visible():
            return

        if root_ui.has_method("is_shop_visible") and root_ui.is_shop_visible():
            if root_ui.has_method("hide_shop"):
                root_ui.hide_shop()

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

    if root_ui != null:
        if root_ui.has_method("_set_story_dialogue_pause"):
            root_ui._set_story_dialogue_pause(true)

        if root_ui.has_method("close_character_screen"):
            root_ui.close_character_screen()

        if root_ui.has_method("hide_prompt"):
            root_ui.hide_prompt()

    print("Story dialogue opened. Line count: ", story_dialogue_lines.size())

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

    if root_ui != null and root_ui.has_method("_set_story_dialogue_pause"):
        root_ui._set_story_dialogue_pause(false)

    story_dialogue_recently_closed_timer = 0.25

    print("Story dialogue closed.")


func is_active() -> bool:
    return story_dialogue_active


func was_recently_closed() -> bool:
    return story_dialogue_recently_closed_timer > 0.0


func _create_story_dialogue_panel() -> void:
    if story_dialogue_layer != null:
        return

    if root_ui == null:
        push_warning("Cannot create story dialogue panel. Root UI is null.")
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

    root_ui.add_child(story_dialogue_layer)

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

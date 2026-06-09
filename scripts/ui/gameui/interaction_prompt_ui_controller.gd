extends RefCounted
class_name InteractionPromptUiController

const DEFAULT_INTERACTION_PROMPT: String = "🖱 Right Mouse / Alt"

var root_ui: CanvasLayer = null

var interaction_prompt: Control = null
var interaction_panel: Panel = null
var interaction_label: Label = null


func setup(ui_root: CanvasLayer) -> void:
    root_ui = ui_root

    if root_ui == null:
        push_warning("InteractionPromptUiController setup failed. Root UI is null.")
        return

    _hide_legacy_interaction_prompt()
    _create_interaction_prompt()
    hide_prompt()


func show_prompt(key_text: String = DEFAULT_INTERACTION_PROMPT) -> void:
    if interaction_prompt == null:
        _create_interaction_prompt()

    var clean_text := key_text.strip_edges()

    if clean_text == "":
        clean_text = DEFAULT_INTERACTION_PROMPT

    if interaction_label != null:
        interaction_label.text = clean_text

    if interaction_prompt != null:
        interaction_prompt.visible = true


func hide_prompt() -> void:
    if interaction_prompt != null:
        interaction_prompt.visible = false


func is_visible() -> bool:
    if interaction_prompt == null:
        return false

    return interaction_prompt.visible


func _create_interaction_prompt() -> void:
    if interaction_prompt != null:
        return

    if root_ui == null:
        return

    interaction_prompt = Control.new()
    interaction_prompt.name = "CodeBuiltInteractionPrompt"
    interaction_prompt.anchor_left = 0.5
    interaction_prompt.anchor_right = 0.5
    interaction_prompt.anchor_top = 1.0
    interaction_prompt.anchor_bottom = 1.0
    interaction_prompt.offset_left = -170.0
    interaction_prompt.offset_right = 170.0
    interaction_prompt.offset_top = -120.0
    interaction_prompt.offset_bottom = -80.0
    interaction_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
    interaction_prompt.visible = false

    root_ui.add_child(interaction_prompt)

    interaction_panel = Panel.new()
    interaction_panel.name = "InteractionPromptPanel"
    interaction_panel.anchor_left = 0.0
    interaction_panel.anchor_right = 1.0
    interaction_panel.anchor_top = 0.0
    interaction_panel.anchor_bottom = 1.0
    interaction_panel.offset_left = 0.0
    interaction_panel.offset_right = 0.0
    interaction_panel.offset_top = 0.0
    interaction_panel.offset_bottom = 0.0
    interaction_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

    interaction_prompt.add_child(interaction_panel)

    interaction_label = Label.new()
    interaction_label.name = "InteractionLabel"
    interaction_label.text = DEFAULT_INTERACTION_PROMPT
    interaction_label.anchor_left = 0.0
    interaction_label.anchor_right = 1.0
    interaction_label.anchor_top = 0.0
    interaction_label.anchor_bottom = 1.0
    interaction_label.offset_left = 8.0
    interaction_label.offset_right = -8.0
    interaction_label.offset_top = 4.0
    interaction_label.offset_bottom = -4.0
    interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    interaction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    interaction_label.add_theme_font_size_override("font_size", 16)
    interaction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

    interaction_panel.add_child(interaction_label)


func _hide_legacy_interaction_prompt() -> void:
    if root_ui == null:
        return

    var legacy_prompt := root_ui.get_node_or_null("InteractionPrompt") as CanvasItem

    if legacy_prompt != null:
        legacy_prompt.visible = false

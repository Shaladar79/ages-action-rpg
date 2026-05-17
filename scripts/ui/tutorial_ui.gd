extends CanvasLayer

@onready var tutorial_panel: Panel = $TutorialPanel
@onready var message_label: RichTextLabel = $TutorialPanel/MessageLabel

var message_active: bool = false
var movement_tutorial_active: bool = false
var movement_step_index: int = 0

var movement_steps: Array[Dictionary] = [
    {
        "text": "To move up, press the W key or the Up Arrow.",
        "actions": ["move_up", "ui_up"]
    },
    {
        "text": "To move down, press the S key or the Down Arrow.",
        "actions": ["move_down", "ui_down"]
    },
    {
        "text": "To move left, press the A key or the Left Arrow.",
        "actions": ["move_left", "ui_left"]
    },
    {
        "text": "To move right, press the D key or the Right Arrow.",
        "actions": ["move_right", "ui_right"]
    }
]


func _ready() -> void:
    tutorial_panel.visible = false
    tutorial_panel.modulate.a = 1.0
    message_label.text = ""


func _unhandled_input(event: InputEvent) -> void:
    if movement_tutorial_active:
        _handle_movement_tutorial_input(event)
        return

    if not message_active:
        return

    if event.is_action_pressed("ui_accept"):
        hide_message()
        get_viewport().set_input_as_handled()


func show_message(message: String) -> void:
    movement_tutorial_active = false
    message_label.text = message
    tutorial_panel.modulate.a = 1.0
    tutorial_panel.visible = true
    message_active = true


func hide_message() -> void:
    tutorial_panel.visible = false
    tutorial_panel.modulate.a = 1.0
    message_active = false


func start_movement_tutorial() -> void:
    message_active = true
    movement_tutorial_active = true
    movement_step_index = 0

    tutorial_panel.modulate.a = 1.0
    tutorial_panel.visible = true

    _update_movement_tutorial_text()


func _handle_movement_tutorial_input(event: InputEvent) -> void:
    if movement_step_index >= movement_steps.size():
        return

    var current_step: Dictionary = movement_steps[movement_step_index]
    var actions: Array = current_step.get("actions", [])

    for action_name in actions:
        if event.is_action_pressed(action_name):
            movement_step_index += 1
            _update_movement_tutorial_text()
            get_viewport().set_input_as_handled()
            return


func _update_movement_tutorial_text() -> void:
    if movement_step_index >= movement_steps.size():
        _finish_movement_tutorial()
        return

    var tutorial_text := ""

    for i in range(movement_steps.size()):
        var step_text: String = movement_steps[i]["text"]

        if i < movement_step_index:
            tutorial_text += "[color=gray]✓ " + step_text + "[/color]\n"
        elif i == movement_step_index:
            tutorial_text += step_text + "\n"
            break

    message_label.text = tutorial_text.strip_edges()


func _finish_movement_tutorial() -> void:
    movement_tutorial_active = false
    message_active = false

    var tween := create_tween()
    tween.tween_property(tutorial_panel, "modulate:a", 0.0, 0.75)
    tween.finished.connect(_on_movement_tutorial_fade_finished)


func _on_movement_tutorial_fade_finished() -> void:
    tutorial_panel.visible = false
    tutorial_panel.modulate.a = 1.0
    message_label.text = ""

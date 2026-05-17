extends Node2D

@onready var dialogue_panel: Panel = $DialoguePanel
@onready var dialogue_label: RichTextLabel = $DialoguePanel/DialogueLabel

var dialogue_active: bool = false


func _ready() -> void:
    hide_dialogue()


func show_dialogue(message: String) -> void:
    dialogue_label.text = message
    visible = true
    dialogue_panel.visible = true
    dialogue_active = true


func hide_dialogue() -> void:
    visible = false
    dialogue_active = false


func is_dialogue_active() -> bool:
    return dialogue_active

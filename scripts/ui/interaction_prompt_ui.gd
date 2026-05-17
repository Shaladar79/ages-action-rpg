extends CanvasLayer

@onready var prompt_panel: Panel = $InteractionPromptPanel
@onready var prompt_label: Label = $InteractionPromptPanel/InteractionPromptLabel


func _ready() -> void:
    hide_prompt()


func show_prompt(prompt_text: String = "E") -> void:
    prompt_label.text = prompt_text
    prompt_panel.visible = true


func hide_prompt() -> void:
    prompt_panel.visible = false

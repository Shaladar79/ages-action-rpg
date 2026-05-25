extends RefCounted
class_name NotificationUiController

var root_ui: CanvasLayer = null
var notification_layer: Control = null
var notification_stack: VBoxContainer = null


func setup(ui_root: CanvasLayer) -> void:
    root_ui = ui_root

    if root_ui == null:
        push_warning("NotificationUiController setup failed. Root UI is null.")
        return

    _create_notification_layer()


func show_notification(message: String, duration: float = 2.4) -> void:
    var clean_message := message.strip_edges()

    if clean_message == "":
        return

    if notification_stack == null:
        _create_notification_layer()

    if notification_stack == null:
        return

    var panel := Panel.new()
    panel.name = "NotificationPanel"
    panel.custom_minimum_size = Vector2(320.0, 42.0)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.modulate.a = 0.0

    var margin := MarginContainer.new()
    margin.name = "NotificationMargin"
    margin.anchor_left = 0.0
    margin.anchor_right = 1.0
    margin.anchor_top = 0.0
    margin.anchor_bottom = 1.0
    margin.offset_left = 10.0
    margin.offset_right = -10.0
    margin.offset_top = 6.0
    margin.offset_bottom = -6.0
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(margin)

    var label := Label.new()
    label.name = "NotificationLabel"
    label.text = clean_message
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 14)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_child(label)

    notification_stack.add_child(panel)
    notification_stack.move_child(panel, notification_stack.get_child_count() - 1)

    var safe_duration := maxf(0.5, duration)

    var tween := panel.create_tween()
    tween.tween_property(panel, "modulate:a", 1.0, 0.12)
    tween.tween_interval(safe_duration)
    tween.tween_property(panel, "modulate:a", 0.0, 0.25)
    tween.finished.connect(_on_notification_finished.bind(panel))


func _create_notification_layer() -> void:
    if notification_layer != null:
        return

    if root_ui == null:
        return

    notification_layer = Control.new()
    notification_layer.name = "CodeBuiltNotificationLayer"
    notification_layer.anchor_left = 0.0
    notification_layer.anchor_right = 1.0
    notification_layer.anchor_top = 0.0
    notification_layer.anchor_bottom = 1.0
    notification_layer.offset_left = 0.0
    notification_layer.offset_right = 0.0
    notification_layer.offset_top = 0.0
    notification_layer.offset_bottom = 0.0
    notification_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

    root_ui.add_child(notification_layer)

    notification_stack = VBoxContainer.new()
    notification_stack.name = "NotificationStack"
    notification_stack.anchor_left = 1.0
    notification_stack.anchor_right = 1.0
    notification_stack.anchor_top = 1.0
    notification_stack.anchor_bottom = 1.0
    notification_stack.offset_left = -360.0
    notification_stack.offset_right = -16.0
    notification_stack.offset_top = -150.0
    notification_stack.offset_bottom = -4.0
    notification_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE

    notification_layer.add_child(notification_stack)


func _on_notification_finished(panel: Panel) -> void:
    if panel == null:
        return

    if not is_instance_valid(panel):
        return

    panel.queue_free()

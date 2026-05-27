extends RefCounted
class_name NotificationUiController

const MAX_VISIBLE_NOTIFICATIONS: int = 3

var root_ui: CanvasLayer = null
var notification_layer: Control = null
var notification_stack: VBoxContainer = null

var notification_queue: Array[Dictionary] = []
var visible_notification_count: int = 0


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

    var safe_duration := maxf(0.5, duration)

    if visible_notification_count >= MAX_VISIBLE_NOTIFICATIONS:
        notification_queue.append({
            "message": clean_message,
            "duration": safe_duration
        })
        return

    _display_notification(clean_message, safe_duration)


func _display_notification(message: String, duration: float) -> void:
    if notification_stack == null:
        return

    visible_notification_count += 1

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
    label.text = message
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 14)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_child(label)

    notification_stack.add_child(panel)
    notification_stack.move_child(panel, notification_stack.get_child_count() - 1)

    var tween := panel.create_tween()
    tween.tween_property(panel, "modulate:a", 1.0, 0.12)
    tween.tween_interval(duration)
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
    if panel != null and is_instance_valid(panel):
        panel.queue_free()

    visible_notification_count = maxi(0, visible_notification_count - 1)

    call_deferred("_show_next_queued_notification")


func _show_next_queued_notification() -> void:
    if notification_queue.is_empty():
        return

    if visible_notification_count >= MAX_VISIBLE_NOTIFICATIONS:
        return

    var queued_notification: Dictionary = notification_queue.pop_front()
    var message: String = str(queued_notification.get("message", "")).strip_edges()
    var duration: float = float(queued_notification.get("duration", 2.4))

    if message == "":
        _show_next_queued_notification()
        return

    _display_notification(message, duration)

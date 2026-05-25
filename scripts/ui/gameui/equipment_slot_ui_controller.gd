extends RefCounted
class_name EquipmentSlotUiController

var root_ui: CanvasLayer = null
var character_panel: Panel = null
var player_getter: Callable = Callable()

var equipment_slot_container: VBoxContainer = null
var equipment_slot_option_buttons: Dictionary = {}
var _updating_options: bool = false


func setup(ui_root: CanvasLayer, panel_node: Panel, get_player_callable: Callable) -> void:
    root_ui = ui_root
    character_panel = panel_node
    player_getter = get_player_callable

    _create_equipment_slot_panel()
    update_equipment_slot_panel()


func update_equipment_slot_panel() -> void:
    if equipment_slot_option_buttons.is_empty():
        return

    _updating_options = true

    _update_equipment_option_button("melee_weapon", ItemDatabase.EQUIPMENT_SLOT_MELEE_WEAPON, _get_equipped_item_id_for_slot("melee_weapon"))
    _update_equipment_option_button("ranged_weapon", ItemDatabase.EQUIPMENT_SLOT_RANGED_WEAPON, _get_equipped_item_id_for_slot("ranged_weapon"))
    _update_equipment_option_button("armor", ItemDatabase.EQUIPMENT_SLOT_ARMOR, _get_equipped_item_id_for_slot("armor"))
    _update_equipment_option_button("accessory_1", ItemDatabase.EQUIPMENT_SLOT_ACCESSORY, _get_equipped_item_id_for_slot("accessory_1"))
    _update_equipment_option_button("accessory_2", ItemDatabase.EQUIPMENT_SLOT_ACCESSORY, _get_equipped_item_id_for_slot("accessory_2"))

    _updating_options = false


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
    var player := _get_player()

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


func _on_equipment_slot_selected(selected_index: int, slot_key: String) -> void:
    if _updating_options:
        return

    var player := _get_player()

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

    if root_ui != null and root_ui.has_method("refresh_character_display"):
        root_ui.refresh_character_display()


func _get_stats() -> CharacterStats:
    var player := _get_player()

    if player == null:
        return null

    if not player.has_method("get_character_stats"):
        return null

    return player.get_character_stats()


func _get_player() -> Node:
    if player_getter.is_valid():
        return player_getter.call()

    return null

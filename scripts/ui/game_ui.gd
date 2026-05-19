extends CanvasLayer

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

@onready var sheet_health_label: Label = get_node_or_null("CharacterScreen/Panel/Health") as Label
@onready var sheet_mana_label: Label = get_node_or_null("CharacterScreen/Panel/Mana") as Label
@onready var sheet_stamina_label: Label = get_node_or_null("CharacterScreen/Panel/Stamina") as Label

@onready var attack_label: Label = get_node_or_null("CharacterScreen/Panel/atk_lbl") as Label
@onready var defense_label: Label = get_node_or_null("CharacterScreen/Panel/def_lbl") as Label

@onready var attributes_label: Label = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/AttributesLabel") as Label
@onready var might_label: Label = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/Might") as Label
@onready var agility_label: Label = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/Agility") as Label
@onready var toughness_label: Label = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/Toughness") as Label
@onready var endurance_label: Label = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/Endurance") as Label
@onready var focus_label: Label = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/Focus") as Label
@onready var speed_label: Label = get_node_or_null("CharacterScreen/Panel/AttributesPanel_base/Attribute_panel_att/Speed") as Label

@onready var weapon_slot_label: Label = $CharacterScreen/Panel/WeaponSlotLabel
@onready var armor_slot_label: Label = $CharacterScreen/Panel/ArmorSlotLabel
@onready var accessory_slot_label: Label = $CharacterScreen/Panel/AccessorySlotLabel
@onready var inventory_label: Label = $CharacterScreen/Panel/InventoryLabel

@onready var equip_weapon_button: Button = $CharacterScreen/Panel/EquipWeaponButton
@onready var equip_armor_button: Button = $CharacterScreen/Panel/EquipArmorButton
@onready var equip_accessory_button: Button = $CharacterScreen/Panel/EquipAccessoryButton
@onready var close_button: Button = $CharacterScreen/Panel/CloseButton

var player: Node = null

var character_name: String = "Gene Ambrose"
var character_level: int = 1
var character_xp: int = 0
var character_xp_to_next_level: int = 100

var max_health: int = 10
var current_health: int = 10

var has_mana_resource: bool = false
var max_mana: int = 0
var current_mana: int = 0

var has_stamina_resource: bool = false
var max_stamina: int = 0
var current_stamina: int = 0

var might: int = 1
var agility: int = 1
var toughness: int = 1
var endurance: int = 1
var focus: int = 1
var speed: int = 1

var attack: int = 1
var defense: int = 1

var equipped_armor_name: String = "Grass Tunic"
var equipped_accessory_name: String = "None"


func _ready() -> void:
    add_to_group("interaction_ui")

    player = get_tree().get_first_node_in_group("player")

    character_screen.visible = false
    interaction_prompt.visible = false

    _connect_buttons()
    _update_hud()
    _update_character_screen()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("character_screen"):
        toggle_character_screen()
        get_viewport().set_input_as_handled()


func show_prompt(key_text: String = "E") -> void:
    interaction_label.text = key_text
    interaction_prompt.visible = true


func hide_prompt() -> void:
    interaction_prompt.visible = false


func toggle_character_screen() -> void:
    character_screen.visible = not character_screen.visible

    if character_screen.visible:
        _refresh_player_reference()
        _update_character_screen()


func open_character_screen() -> void:
    character_screen.visible = true
    _refresh_player_reference()
    _update_character_screen()


func close_character_screen() -> void:
    character_screen.visible = false


func _connect_buttons() -> void:
    if not equip_weapon_button.pressed.is_connected(_on_equip_weapon_button_pressed):
        equip_weapon_button.pressed.connect(_on_equip_weapon_button_pressed)

    if not equip_armor_button.pressed.is_connected(_on_equip_armor_button_pressed):
        equip_armor_button.pressed.connect(_on_equip_armor_button_pressed)

    if not equip_accessory_button.pressed.is_connected(_on_equip_accessory_button_pressed):
        equip_accessory_button.pressed.connect(_on_equip_accessory_button_pressed)

    if not close_button.pressed.is_connected(_on_close_button_pressed):
        close_button.pressed.connect(_on_close_button_pressed)


func _refresh_player_reference() -> void:
    if player != null:
        return

    player = get_tree().get_first_node_in_group("player")


func _update_hud() -> void:
    if hud_health_label != null:
        hud_health_label.text = "Health: %s / %s" % [current_health, max_health]

    if hud_mana_label != null:
        hud_mana_label.visible = has_mana_resource
        if has_mana_resource:
            hud_mana_label.text = "Mana: %s / %s" % [current_mana, max_mana]
        else:
            hud_mana_label.text = ""

    if hud_stamina_label != null:
        hud_stamina_label.visible = has_stamina_resource
        if has_stamina_resource:
            hud_stamina_label.text = "Stamina: %s / %s" % [current_stamina, max_stamina]
        else:
            hud_stamina_label.text = ""


func _update_character_screen() -> void:
    title_label.text = "Character Sheet"
    character_name_label.text = character_name
    level_label.text = "Level: " + str(character_level)
    xp_label.text = "XP: %s / %s" % [character_xp, character_xp_to_next_level]

    _update_sheet_resources()
    _update_attributes_panel()
    _update_combat_stats()

    weapon_slot_label.text = "Weapon: " + _get_equipped_weapon_name()
    armor_slot_label.text = "Armor: " + equipped_armor_name
    accessory_slot_label.text = "Accessory: " + equipped_accessory_name

    inventory_label.text = _get_inventory_text()

    equip_weapon_button.disabled = not _player_has_item("club")
    equip_armor_button.disabled = true
    equip_accessory_button.disabled = true


func _update_sheet_resources() -> void:
    if sheet_health_label != null:
        sheet_health_label.text = "Health: %s / %s" % [current_health, max_health]

    if sheet_mana_label != null:
        sheet_mana_label.visible = has_mana_resource
        if has_mana_resource:
            sheet_mana_label.text = "Mana: %s / %s" % [current_mana, max_mana]
        else:
            sheet_mana_label.text = ""

    if sheet_stamina_label != null:
        sheet_stamina_label.visible = has_stamina_resource
        if has_stamina_resource:
            sheet_stamina_label.text = "Stamina: %s / %s" % [current_stamina, max_stamina]
        else:
            sheet_stamina_label.text = ""


func _update_attributes_panel() -> void:
    if attributes_label != null:
        attributes_label.text = "Attributes"

    if might_label != null:
        might_label.text = "Might: " + str(might)

    if agility_label != null:
        agility_label.text = "Agility: " + str(agility)

    if toughness_label != null:
        toughness_label.text = "Toughness: " + str(toughness)

    if endurance_label != null:
        endurance_label.text = "Endurance: " + str(endurance)

    if focus_label != null:
        focus_label.text = "Focus: " + str(focus)

    if speed_label != null:
        speed_label.text = "Speed: " + str(speed)


func _update_combat_stats() -> void:
    if attack_label != null:
        attack_label.text = "Attack: " + str(attack)

    if defense_label != null:
        defense_label.text = "Defense: " + str(defense)


func _get_equipped_weapon_name() -> String:
    if player == null:
        return "None"

    if player.has_method("get_equipped_weapon_name"):
        return player.get_equipped_weapon_name()

    return "None"


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
        var item_name: String = item.get("name", "Unknown Item")
        text += "- " + item_name + "\n"

    return text.strip_edges()


func _player_has_item(item_id: String) -> bool:
    if player == null:
        return false

    if not player.has_method("has_inventory_item"):
        return false

    return player.has_inventory_item(item_id)


func _on_equip_weapon_button_pressed() -> void:
    if player == null:
        return

    if not player.has_method("equip_weapon"):
        return

    if not _player_has_item("club"):
        return

    player.equip_weapon("club")
    _update_character_screen()


func _on_equip_armor_button_pressed() -> void:
    print("Armor equipment is not active yet.")


func _on_equip_accessory_button_pressed() -> void:
    print("Accessory equipment is not active yet.")


func _on_close_button_pressed() -> void:
    close_character_screen()

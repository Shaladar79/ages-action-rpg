extends Area2D
class_name LootContainer

@export var persistent_id: String = ""

@export_group("Visuals")
@export var closed_texture: Texture2D = null
@export var opened_texture: Texture2D = null
@export var icon_scale: Vector2 = Vector2(1.0, 1.0)

@export_group("Interaction")
@export var interaction_prompt_text: String = "E"
@export var opened_message: String = "You opened the container."
@export var empty_message: String = "The container is empty."
@export var disappear_on_open: bool = false

@export_group("Item Drop")
@export var drop_item_id: String = ""
@export_range(0.0, 100.0, 0.1) var drop_item_chance_percent: float = 100.0
@export var drop_item_quantity: int = 1

@export_group("Currency Drop")
@export_enum(
    "none",
    "shines",
    "fire_essence",
    "ice_essence",
    "lightning_essence",
    "acid_essence",
    "light_essence",
    "shadow_essence",
    "primal_essence"
)
var drop_currency_id: String = ""

@export_range(0.0, 100.0, 0.1) var drop_currency_chance_percent: float = 100.0
@export var drop_currency_min_amount: int = 1
@export var drop_currency_max_amount: int = 1

@export_group("Debug")
@export var debug_prints: bool = true

@onready var sprite_2d: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D

var is_opened: bool = false
var player_in_range: Node = null


func _ready() -> void:
    print("LootContainer ready: ", name, " persistent_id: ", persistent_id)

    if persistent_id.strip_edges() == "":
        persistent_id = name

    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

    if SaveManager.is_collectable_collected(persistent_id):
        print("LootContainer already collected: ", persistent_id)
        is_opened = true

        if disappear_on_open:
            queue_free()
            return

    _refresh_visual()


func interact(player: Node) -> void:
    if player == null:
        return

    if is_opened:
        _show_player_message(player, empty_message)
        return

    _open_container(player)


func _open_container(player: Node) -> void:
    is_opened = true
    SaveManager.mark_collectable_collected(persistent_id)

    var received_anything := false

    if _try_give_item(player):
        received_anything = true

    if _try_give_currency(player):
        received_anything = true

    _hide_interaction_prompt()

    if received_anything:
        _show_player_message(player, opened_message)
    else:
        _show_player_message(player, empty_message)

    if debug_prints:
        print("Loot container opened: ", persistent_id)

    if disappear_on_open:
        queue_free()
        return

    _refresh_visual()


func _try_give_item(player: Node) -> bool:
    var clean_item_id := drop_item_id.strip_edges()

    if clean_item_id == "":
        return false

    if drop_item_chance_percent <= 0.0:
        return false

    var roll := randf_range(0.0, 100.0)

    if roll > drop_item_chance_percent:
        if debug_prints:
            print("Container item roll failed. Roll: ", roll, " Chance: ", drop_item_chance_percent)
        return false

    if not player.has_method("add_inventory_item"):
        push_warning("Player cannot receive container item. Missing add_inventory_item().")
        return false

    var item_name := ItemDatabase.get_item_name(clean_item_id)
    var quantity := maxi(1, drop_item_quantity)

    player.add_inventory_item(clean_item_id, item_name, quantity)

    if debug_prints:
        print("Container gave item: ", item_name, " x", quantity)

    return true


func _try_give_currency(player: Node) -> bool:
    var clean_currency_id := drop_currency_id.strip_edges()

    if clean_currency_id == "" or clean_currency_id == "none":
        return false

    if drop_currency_chance_percent <= 0.0:
        return false

    var roll := randf_range(0.0, 100.0)

    if roll > drop_currency_chance_percent:
        if debug_prints:
            print("Container currency roll failed. Roll: ", roll, " Chance: ", drop_currency_chance_percent)
        return false

    if not player.has_method("add_currency"):
        push_warning("Player cannot receive container currency. Missing add_currency().")
        return false

    var min_amount := maxi(0, drop_currency_min_amount)
    var max_amount := maxi(min_amount, drop_currency_max_amount)

    if max_amount <= 0:
        return false

    var amount := randi_range(min_amount, max_amount)

    if amount <= 0:
        return false
    print("Trying to give currency to player.")
    print("Currency ID: ", clean_currency_id)
    print("Amount: ", amount)
    print("Player has add_currency: ", player.has_method("add_currency"))
    player.add_currency(clean_currency_id, amount)

    if debug_prints:
        print("Container gave currency: ", clean_currency_id, " x", amount)

    return true


func _refresh_visual() -> void:
    var sprite := get_node_or_null("Sprite2D") as Sprite2D

    if sprite == null:
        push_warning("LootContainer missing child Sprite2D: " + name)
        return

    sprite.visible = true
    sprite.z_index = 50
    sprite.z_as_relative = false
    sprite.scale = icon_scale

    if is_opened and opened_texture != null:
        sprite.texture = opened_texture
        print("LootContainer using opened texture: ", name)
        return

    if closed_texture != null:
        sprite.texture = closed_texture
        print("LootContainer using closed texture: ", name)
        return

    push_warning("LootContainer has no closed_texture set: " + name)


func _show_player_message(player: Node, message: String) -> void:
    if message.strip_edges() == "":
        return

    if player.has_method("show_dialogue"):
        player.show_dialogue(message)


func _show_interaction_prompt() -> void:
    var interaction_ui := get_tree().get_first_node_in_group("interaction_ui")

    if interaction_ui == null:
        return

    if interaction_ui.has_method("show_prompt"):
        interaction_ui.show_prompt(interaction_prompt_text)


func _hide_interaction_prompt() -> void:
    var interaction_ui := get_tree().get_first_node_in_group("interaction_ui")

    if interaction_ui == null:
        return

    if interaction_ui.has_method("hide_prompt"):
        interaction_ui.hide_prompt()


func _on_body_entered(body: Node) -> void:
    if body == null:
        return

    if not body.is_in_group("player"):
        return

    player_in_range = body

    if body.has_method("set_nearby_interactable"):
        body.set_nearby_interactable(self)
    else:
        _show_interaction_prompt()


func _on_body_exited(body: Node) -> void:
    if body != player_in_range:
        return

    if body.has_method("clear_nearby_interactable"):
        body.clear_nearby_interactable(self)
    else:
        _hide_interaction_prompt()

    player_in_range = null

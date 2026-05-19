extends Interactable
class_name CollectableObject

@export var persistent_id: String = ""

@export var item_id: String = ""
@export var item_name: String = ""
@export var item_type: String = "misc"
@export var quantity: int = 1

@export var auto_equip_on_pickup: bool = false
@export var destroy_on_collect: bool = true

@export var pickup_prompt: String = "Press E to pick up."
@export var pickup_message: String = ""

@export var show_dialogue_on_collect: bool = false
@export_multiline var collect_dialogue: String = "Put story here."


func _ready() -> void:
    if _should_remove_because_collected_in_save():
        queue_free()
        return

    interaction_id = item_id
    interaction_prompt = pickup_prompt
    one_shot = destroy_on_collect

    super._ready()


func _should_remove_because_collected_in_save() -> bool:
    if persistent_id.strip_edges() == "":
        return false

    if not SaveManager.is_collectable_collected(persistent_id):
        return false

    print("Collectable removed because already collected: ", persistent_id)
    return true


func _on_interact(player: Node2D) -> void:
    if player == null:
        return

    if item_id.strip_edges() == "":
        push_warning("CollectableObject has no item_id set: " + name)
        return

    if item_name.strip_edges() == "":
        push_warning("CollectableObject has no item_name set: " + name)
        return

    if quantity <= 0:
        push_warning("CollectableObject quantity must be 1 or higher: " + name)
        return

    if not player.has_method("add_inventory_item"):
        push_warning("Player does not have add_inventory_item(). Cannot collect: " + item_name)
        return

    player.add_inventory_item(item_id, item_name)

    if persistent_id.strip_edges() != "":
        SaveManager.mark_collectable_collected(persistent_id)

    if auto_equip_on_pickup:
        _try_auto_equip(player)

    _print_pickup_message()
    _show_collect_dialogue(player)

    if destroy_on_collect:
        queue_free()


func _try_auto_equip(player: Node2D) -> void:
    match item_type:
        "weapon":
            if player.has_method("equip_weapon"):
                player.equip_weapon(item_id)
        _:
            pass


func _print_pickup_message() -> void:
    if pickup_message.strip_edges() != "":
        print(pickup_message)
        return

    if quantity > 1:
        print("Collected: ", item_name, " x", quantity)
    else:
        print("Collected: ", item_name)


func _show_collect_dialogue(player: Node2D) -> void:
    if not show_dialogue_on_collect:
        return

    if collect_dialogue.strip_edges() == "":
        return

    if player.has_method("show_dialogue"):
        player.show_dialogue(collect_dialogue)

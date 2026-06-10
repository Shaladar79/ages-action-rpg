extends RefCounted
class_name PlayerCurrencyComponent

const CURRENCY_MARKS: String = "marks"

var player: Node = null


func setup(owner_player: Node) -> void:
    player = owner_player
    initialize_currencies()


func initialize_currencies() -> void:
    if player == null:
        return

    var currencies: Dictionary = player.get("currencies")
    var discovered_currency_ids: Array = player.get("discovered_currency_ids")

    if not currencies.has(CURRENCY_MARKS):
        currencies[CURRENCY_MARKS] = 0

    if not discovered_currency_ids.has(CURRENCY_MARKS):
        discovered_currency_ids.append(CURRENCY_MARKS)

    player.set("currencies", currencies)
    player.set("discovered_currency_ids", discovered_currency_ids)


func get_currency_display_name(_currency_id: String = CURRENCY_MARKS) -> String:
    return "Marks"


func add_marks(amount: int) -> bool:
    if player == null:
        return false

    if bool(player.get("is_defeated")):
        return false

    if amount <= 0:
        return false

    initialize_currencies()

    var currencies: Dictionary = player.get("currencies")
    var current_amount: int = int(currencies.get(CURRENCY_MARKS, 0))
    currencies[CURRENCY_MARKS] = current_amount + amount
    player.set("currencies", currencies)

    discover_currency(CURRENCY_MARKS)

    print("Added Marks: +", amount)
    print("Marks total: ", currencies[CURRENCY_MARKS])

    _show_reward_notification("Received: " + str(amount) + " Marks")
    _notify_ui_stats_changed()

    return true


func spend_marks(amount: int) -> bool:
    if amount <= 0:
        return false

    initialize_currencies()

    if player == null:
        return false

    var currencies: Dictionary = player.get("currencies")
    var current_amount: int = int(currencies.get(CURRENCY_MARKS, 0))

    if current_amount < amount:
        return false

    currencies[CURRENCY_MARKS] = current_amount - amount
    player.set("currencies", currencies)

    print("Spent Marks: -", amount)
    print("Marks total: ", currencies[CURRENCY_MARKS])

    _notify_ui_stats_changed()

    return true


func get_marks() -> int:
    initialize_currencies()

    if player == null:
        return 0

    var currencies: Dictionary = player.get("currencies")
    return int(currencies.get(CURRENCY_MARKS, 0))


func add_currency(_currency_id: String, amount: int) -> bool:
    return add_marks(amount)


func spend_currency(_currency_id: String, amount: int) -> bool:
    return spend_marks(amount)


func get_currency_amount(_currency_id: String = CURRENCY_MARKS) -> int:
    return get_marks()


func is_currency_discovered(_currency_id: String = CURRENCY_MARKS) -> bool:
    initialize_currencies()
    return true


func discover_currency(_currency_id: String) -> void:
    initialize_currencies()

    if player == null:
        return

    var discovered_currency_ids: Array = player.get("discovered_currency_ids")

    if discovered_currency_ids.has(CURRENCY_MARKS):
        return

    discovered_currency_ids.append(CURRENCY_MARKS)
    player.set("discovered_currency_ids", discovered_currency_ids)

    print("Currency discovered: Marks")


func get_discovered_currency_rows() -> Array[Dictionary]:
    initialize_currencies()

    return [
        {
            "id": CURRENCY_MARKS,
            "name": "Marks",
            "amount": get_marks()
        }
    ]


func get_currency_save_data() -> Dictionary:
    initialize_currencies()

    if player == null:
        return {
            "currencies": {},
            "discovered_currency_ids": []
        }

    var currencies: Dictionary = player.get("currencies")
    var discovered_currency_ids: Array = player.get("discovered_currency_ids")

    return {
        "currencies": currencies.duplicate(true),
        "discovered_currency_ids": discovered_currency_ids.duplicate()
    }


func set_currency_save_data(saved_currency_data: Dictionary) -> void:
    if player == null:
        return

    var currencies: Dictionary = {}
    var discovered_currency_ids: Array[String] = []

    var total_marks: int = 0
    var saved_currencies: Dictionary = saved_currency_data.get("currencies", {})

    for currency_id in saved_currencies.keys():
        total_marks += int(saved_currencies.get(currency_id, 0))

    currencies[CURRENCY_MARKS] = maxi(0, total_marks)
    discovered_currency_ids.append(CURRENCY_MARKS)

    player.set("currencies", currencies)
    player.set("discovered_currency_ids", discovered_currency_ids)

    print("Currency save data loaded as Marks. Total Marks: ", currencies[CURRENCY_MARKS])
    _notify_ui_stats_changed()


func _show_reward_notification(message: String) -> void:
    if player != null and player.has_method("_show_reward_notification"):
        player._show_reward_notification(message)


func _notify_ui_stats_changed() -> void:
    if player != null and player.has_method("_notify_ui_stats_changed"):
        player._notify_ui_stats_changed()

extends Resource
class_name ShopStockEntry

@export_group("Item")
@export var item_id: String = ""

# How many items the player receives per purchase.
# Example: sling_ammo quantity 5 means buying once gives 5 ammo.
@export var quantity: int = 1

@export_group("Buy Price")
@export var buy_price: int = 1

@export_group("Sell Price")
@export var shop_will_buy_item: bool = false

# Price paid per single item sold to the shop.
# Example: sell_price 1 means selling 5 sling_ammo gives 5 Marks.
@export var sell_price: int = 0

@export_group("Requirements")
@export var required_flag: String = ""

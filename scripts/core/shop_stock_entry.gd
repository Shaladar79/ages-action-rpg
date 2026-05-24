extends Resource
class_name ShopStockEntry

@export var item_id: String = ""
@export var quantity: int = 1
@export var price_currency: String = "shines"
@export var price_amount: int = 1

# Optional.
# Blank means this item is always available.
# Filled means the item only appears if SaveManager.is_flag_set(required_flag) is true.
@export var required_flag: String = ""

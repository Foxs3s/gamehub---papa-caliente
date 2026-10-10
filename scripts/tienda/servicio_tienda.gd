extends RefCounted

const HEART_PRICE: int = 40
const SWORD_PRICE: int = 55
const PAPAMAX_PRICE: int = 20
const MAX_HEART_UPGRADES: int = 3


static func get_price(item_id: String) -> int:
	match item_id:
		"corazon":
			return HEART_PRICE + GameState.heart_upgrades * 15
		"espada":
			return SWORD_PRICE
		"papamax":
			return PAPAMAX_PRICE
		_:
			return 0


static func can_purchase(item_id: String) -> bool:
	var price := get_price(item_id)
	if price <= 0 or GameState.coins < price:
		return false

	match item_id:
		"corazon":
			return GameState.heart_upgrades < MAX_HEART_UPGRADES
		"espada":
			return not GameState.sword_owned
		"papamax":
			return true
		_:
			return false


static func purchase(item_id: String, player: CharacterBody2D) -> bool:
	if not is_instance_valid(player) or not can_purchase(item_id):
		return false
	if not GameState.spend_coins(get_price(item_id)):
		return false

	match item_id:
		"corazon":
			GameState.heart_upgrades += 1
		"espada":
			GameState.sword_owned = true
		"papamax":
			GameState.papamax_count += 1
		_:
			push_error("Producto de tienda desconocido: %s" % item_id)
			return false

	GameState.apply_player_upgrades(player, item_id == "corazon")
	GameState.inventory_changed.emit()
	return true

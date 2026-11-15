extends Node
 
signal item_changed(item_name: String, new_amount: int)
 
var items: Dictionary = {} 
 
func add_item(item_name: String, amount: int = 1) -> void:
	items[item_name] = get_amount(item_name) + amount
	item_changed.emit(item_name, items[item_name])
 
func remove_item(item_name: String, amount: int = 1) -> bool:
	if get_amount(item_name) < amount:
		return false
	items[item_name] -= amount
	item_changed.emit(item_name, items[item_name])
	return true
 
 
func get_amount(item_name: String) -> int:
	return items.get(item_name, 0)


## Vacía el inventario (al reiniciar la partida)
func clear() -> void:
	for item_name in items.keys():
		item_changed.emit(item_name, 0)
	items.clear()

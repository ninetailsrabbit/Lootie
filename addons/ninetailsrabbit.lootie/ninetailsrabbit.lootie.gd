@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("LootItem", "Resource", preload("src/loot_item.gd"), null)
	add_custom_type("LootItemRarity", "Resource", preload("src/probability_modes/loot_item_rarity.gd"), null)
	add_custom_type("LootItemWeight", "Resource", preload("src/probability_modes/loot_item_weight.gd"), null)
	add_custom_type("LootItemChance", "Resource", preload("src/probability_modes/loot_item_chance.gd"), null)
	add_custom_type("LootTableData", "Resource", preload("src/loot_table_data.gd"), null)
	
	add_custom_type("LootieTable", "Node", preload("src/loot_table.gd"), preload("assets/lootie.svg"))
	add_autoload_singleton("LootieGlobal", "src/lootie_global.gd")
	

func _exit_tree() -> void:
	remove_autoload_singleton("LootieGlobal")
	
	remove_custom_type("LootTableData")
	
	remove_custom_type("LootItemRarity")
	remove_custom_type("LootItemWeight")
	remove_custom_type("LootItemChance")
	remove_custom_type("LootItem")
	
	remove_custom_type("LootieTable")

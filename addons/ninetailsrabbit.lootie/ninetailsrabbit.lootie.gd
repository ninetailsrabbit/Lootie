@tool
extends EditorPlugin

const UpdateNotifyToolScene = preload("updater/update_notify_tool.tscn")

var update_notify_tool_instance: Node

func _enter_tree() -> void:
	MyPluginSettings.set_update_notification()
	_setup_updater()
	
	if not DirAccess.dir_exists_absolute(MyPluginSettings.PluginTemporaryReleaseUpdateDirectoryPath):
		DirAccess.make_dir_recursive_absolute(MyPluginSettings.PluginTemporaryReleaseUpdateDirectoryPath)
	
	add_custom_type("LootItem", "Resource", preload("src/loot_item.gd"), null)
	add_custom_type("LootItemRarity", "Resource", preload("src/probability_modes/loot_item_rarity.gd"), null)
	add_custom_type("LootItemWeight", "Resource", preload("src/probability_modes/loot_item_weight.gd"), null)
	add_custom_type("LootItemChance", "Resource", preload("src/probability_modes/loot_item_chance.gd"), null)
	add_custom_type("LootTableData", "Resource", preload("src/loot_table_data.gd"), null)
	
	add_custom_type("LootieTable", "Node", preload("src/loot_table.gd"), preload("assets/lootie.svg"))
	add_autoload_singleton("LootieGlobal", "src/lootie_global.gd")
	

func _exit_tree() -> void:
	MyPluginSettings.remove_settings()
	
	if update_notify_tool_instance:
		update_notify_tool_instance.free()
		update_notify_tool_instance = null
		
	remove_autoload_singleton("LootieGlobal")
	
	remove_custom_type("LootTableData")
	
	remove_custom_type("LootItemRarity")
	remove_custom_type("LootItemWeight")
	remove_custom_type("LootItemChance")
	remove_custom_type("LootItem")
	
	remove_custom_type("LootieTable")

## Update tool referenced from https://github.com/MikeSchulze/gdUnit4/blob/master/addons/gdUnit4
func _setup_updater() -> void:
	if MyPluginSettings.is_update_notification_enabled():
		update_notify_tool_instance = UpdateNotifyToolScene.instantiate()
		Engine.get_main_loop().root.add_child.call_deferred(update_notify_tool_instance)

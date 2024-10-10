class_name LootieTable extends Node


@export var loot_table_data: LootTableData


var mirrored_items: Array[LootItem] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	mirrored_items.clear()
	mirrored_items = loot_table_data.available_items.duplicate()
	
	_prepare_random_number_generator()

		
func roll(times: int = loot_table_data.default_roll_times_each_generation, except: Array[LootItem] = []) -> Array[LootItem]:
	var items_rolled: Array[LootItem] = []
	var max_picks: int = min(loot_table_data.items_limit_per_loot, mirrored_items.size())
	times = max(1, abs(times))
	
	for exception_items: LootItem in except:
		mirrored_items.erase(exception_items)
	
	if mirrored_items.size() > 0:
		match loot_table_data.probability_type:
			LootTableData.ProbabilityMode.Weight:
				for i in range(times):
					items_rolled.append_array(roll_items_by_weight())

					if items_rolled.size() >= max_picks:
						break
					
				if loot_table_data.fixed_items_per_loot > 0:
					while items_rolled.size() < loot_table_data.fixed_items_per_loot and mirrored_items.size() >= (loot_table_data.fixed_items_per_loot - items_rolled.size()):
						items_rolled.append_array(roll_items_by_weight())
			
			LootTableData.ProbabilityMode.RollTier:
				for i in range(times):
					items_rolled.append_array(roll_items_by_tier())
				
					if items_rolled.size() >= max_picks:
							break
					
				if loot_table_data.fixed_items_per_loot > 0 and loot_table_data.items_with_rarity_available().size() >= loot_table_data.fixed_items_per_loot:
					while items_rolled.size() < loot_table_data.fixed_items_per_loot and (not mirrored_items.is_empty() or mirrored_items.size() >= loot_table_data.fixed_items_per_loot):
						items_rolled.append_array(roll_items_by_tier())
			
			LootTableData.ProbabilityMode.PercentageProbability:
				for i in range(times):
					items_rolled.append_array(roll_items_by_percentage())
				
					if items_rolled.size() >= max_picks:
							break
					
				if loot_table_data.fixed_items_per_loot > 0 and loot_table_data.items_with_valid_chance().size() >= loot_table_data.fixed_items_per_loot:
					while items_rolled.size() < loot_table_data.fixed_items_per_loot and (not mirrored_items.is_empty() or mirrored_items.size() >= loot_table_data.fixed_items_per_loot):
						items_rolled.append_array(roll_items_by_percentage())
			
	## Reset the mirrored items after the multiple shuffles or erased items
		mirrored_items = loot_table_data.available_items.duplicate()
		
		items_rolled.shuffle()
	
	return items_rolled.slice(0, max_picks)


func roll_items_by_weight() -> Array[LootItem]:
	var items_rolled: Array[LootItem] = []
	var total_weight: float = 0.0

	total_weight = _prepare_weight_on_items(mirrored_items)
	mirrored_items.shuffle()
	
	var roll_result: float = snappedf(rng.randf_range(0, total_weight), 0.01)
	
	for looted_item: LootItem in mirrored_items.filter(func(item: LootItem): return roll_result <= item.accum_weight):
		items_rolled.append(looted_item.duplicate())
		
	if loot_table_data.choose_all_possible_candidates_each_roll_weight:
		if not loot_table_data.allow_duplicates:
			for looted_item: LootItem in items_rolled:
				mirrored_items.erase(looted_item)
			
		return items_rolled
	else:
		## The assign method allow to keep the types of the original array so we avoid the type error on return
		var result: Array[LootItem] = []
		result.assign(PluginUtilities.pick_random_values(items_rolled, loot_table_data.number_of_items_that_can_be_selected_per_roll_weight))
		
		if not loot_table_data.allow_duplicates:
			for looted_item: LootItem in result:
				mirrored_items.erase(looted_item)
				
		return result
		
		
func roll_items_by_tier(selected_min_roll_tier: float = loot_table_data.min_roll_tier, selected_max_roll_tier: float = loot_table_data.max_roll_tier) -> Array[LootItem]:
	var items_rolled: Array[LootItem] = []
	var item_rarity_roll = randf_range(
		selected_min_roll_tier, 
		clampf(selected_max_roll_tier, 0, loot_table_data.max_current_rarity_roll()) if loot_table_data.limit_max_roll_tier_to_maximum_from_available_items else selected_max_roll_tier
		)
	
	var current_roll_items = loot_table_data.items_with_rarity_available(mirrored_items).filter(
		func(item: LootItem):
			return PluginUtilities.decimal_value_is_between(snappedf(item_rarity_roll, 0.01), item.rarity.min_roll, item.rarity.max_roll)
			)
	
	
	current_roll_items.shuffle()
	
	items_rolled.append_array(current_roll_items)

	if loot_table_data.choose_all_possible_candidates_each_roll_tier:
		if not loot_table_data.allow_duplicates:
			for looted_item: LootItem in items_rolled:
				mirrored_items.erase(looted_item)
			
		return items_rolled
	else:
		## The assign method allow to keep the types of the original array so we avoid the type error on return
		var result: Array[LootItem] = []
		result.assign(PluginUtilities.pick_random_values(items_rolled, loot_table_data.number_of_items_that_can_be_selected_per_roll_tier))
		
		if not loot_table_data.allow_duplicates:
			for looted_item: LootItem in result:
				mirrored_items.erase(looted_item)
				
		return result


func roll_items_by_percentage() -> Array[LootItem]:
	var items_rolled: Array[LootItem] = []
	var chance_result: float = rng.randf_range(0.0, 1.0)
	
	var current_roll_items = loot_table_data.items_with_valid_chance().filter(func(item: LootItem): PluginUtilities.chance(rng, item.chance))
	current_roll_items.shuffle()
	
	items_rolled.append_array(current_roll_items)
	
	if loot_table_data.choose_all_possible_candidates_each_chance:
		if not loot_table_data.allow_duplicates:
			for looted_item: LootItem in items_rolled:
				mirrored_items.erase(looted_item)
			
		return items_rolled
	
	else:
		## The assign method allow to keep the types of the original array so we avoid the type error on return
		var result: Array[LootItem] = []
		result.assign(PluginUtilities.pick_random_values(items_rolled, loot_table_data.number_of_items_that_can_be_selected_per_chance))
		
		if not loot_table_data.allow_duplicates:
			for looted_item: LootItem in result:
				mirrored_items.erase(looted_item)
				
		return result


func change_probability_type(new_type: LootTableData.ProbabilityMode) -> void:
	loot_table_data.probability_type = new_type


func add_items(items: Array[LootItem] = []) -> void:
	loot_table_data.available_items.append_array(items)
	mirrored_items = loot_table_data.available_items.duplicate()


func add_item(item: LootItem) -> void:
	loot_table_data.available_items.append(item)
	loot_table_data.available_items = loot_table_data.available_items
	mirrored_items = loot_table_data.available_items.duplicate()
	

func remove_items(items: Array[LootItem] = []) -> void:
	loot_table_data.available_items = loot_table_data.available_items.filter(func(item: LootItem): return not item in items)
	mirrored_items = loot_table_data.available_items.duplicate()
	

func remove_item(item: LootItem) -> void:
	loot_table_data.available_items.erase(item)
	mirrored_items = loot_table_data.available_items.duplicate()
	
	
func remove_items_by_id(item_ids: Array[StringName] = []) -> void:
	loot_table_data.available_items = loot_table_data.available_items.filter(func(item: LootItem): return not item.id in item_ids)
	mirrored_items = loot_table_data.available_items.duplicate()


func remove_item_by_id(item_id: StringName) -> void:
	loot_table_data.available_items  = loot_table_data.available_items.filter(func(item: LootItem): return not item.id == item_id)
	mirrored_items = loot_table_data.available_items.duplicate()


func _prepare_weight_on_items(target_items: Array[LootItem] = mirrored_items) -> float:
	var total_weight: float = 0.0
	
	for item: LootItem in target_items:
		item.reset_accum_weight()
		total_weight += item.weight
		item.accum_weight = total_weight
	
	return total_weight + loot_table_data.extra_weight_bias

		
func _prepare_random_number_generator() -> void:
	if loot_table_data.seed_value > 0:
		rng.seed = loot_table_data.seed_value
	elif not loot_table_data.seed_string.is_empty():
		rng.seed = loot_table_data.seed_string.hash()
		

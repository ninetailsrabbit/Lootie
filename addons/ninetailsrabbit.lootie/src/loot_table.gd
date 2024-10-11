class_name LootieTable extends Node


@export var loot_table_data: LootTableData


var mirrored_items: Array[LootItem] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	mirrored_items.clear()
	mirrored_items = loot_table_data.available_items.duplicate()
	
	_prepare_random_number_generator()


func generate(times: int = 1) -> Array[LootItem]:
	mirrored_items = loot_table_data.available_items.duplicate() if mirrored_items.is_empty() else mirrored_items
	
	var items_looted: Array[LootItem] = []
	var max_picks: int = min(loot_table_data.items_limit_per_loot, mirrored_items.size())
	var size_that_does_not_count_on_loot_limit: int = 0

	times = max(1, abs(times))
	
	if not mirrored_items.is_empty():
		## Filter only items that are enabled for loot
		mirrored_items = mirrored_items.filter(func(item: LootItem): return item.is_enabled)
		## Append always the items that always should drop from this loot table
		items_looted.append_array(mirrored_items.filter(func(item: LootItem): return item.should_drop_always))
		
		if loot_table_data.always_drop_items_count_on_limit and items_looted.size() >= max_picks:
			return items_looted.slice(0, max_picks)
			
		size_that_does_not_count_on_loot_limit += items_looted.size()
		
		for i in times:
			items_looted.append_array(_generate_loot_by_mode())
			
			if not loot_table_data.allow_duplicates:
				items_looted.assign(PluginUtilities.remove_duplicates(items_looted))
		
	
	return items_looted.slice(0, max_picks + size_that_does_not_count_on_loot_limit)


func roll_items_by_weight() -> Array[LootItem]:
	var items_rolled: Array[LootItem] = []
	var total_weight: float = 0.0

	total_weight = _prepare_weight_on_items(mirrored_items)
	var valid_items: Array[LootItem] = loot_table_data.items_with_weight_available(mirrored_items)
	valid_items.shuffle()
	
	if loot_table_data.roll_per_item:
		items_rolled.append_array(valid_items.filter(func(item: LootItem): return item.weight.roll(rng, total_weight)))
	else:
		var roll_result: float = snappedf(rng.randf_range(0, total_weight), 0.01)
		
		items_rolled.append_array(valid_items.filter(func(item: LootItem): return item.weight.roll_overcome(roll_result)))

	return items_rolled
		
		
func roll_items_by_tier(selected_min_roll_tier: float = loot_table_data.min_roll_tier, selected_max_roll_tier: float = loot_table_data.max_roll_tier) -> Array[LootItem]:
	var items_rolled: Array[LootItem] = []

	var valid_items: Array[LootItem] = loot_table_data.items_with_rarity_available(mirrored_items)
	valid_items.shuffle()
	
	selected_max_roll_tier = clampf(selected_max_roll_tier, 0, loot_table_data.max_current_rarity_roll()) if loot_table_data.limit_max_roll_tier_from_available_items else selected_max_roll_tier

	if loot_table_data.roll_per_item:
		items_rolled.append_array(valid_items.filter(func(item: LootItem): return item.rarity.roll(rng, selected_min_roll_tier, selected_max_roll_tier)))
	
	else:
		var roll_result: float = rng.randf_range(selected_min_roll_tier, selected_max_roll_tier)
		
		items_rolled.append_array(valid_items.filter(func(item: LootItem): return item.rarity.roll_overcome(roll_result)))
	
	return items_rolled
		


func roll_items_by_percentage() -> Array[LootItem]:
	var items_rolled: Array[LootItem] = []

	var valid_items: Array[LootItem] = loot_table_data.items_with_valid_chance(mirrored_items)
	valid_items.shuffle()
	
	if loot_table_data.roll_per_item:
		items_rolled.append_array(valid_items.filter(func(item: LootItem): return item.chance.roll(rng)))
	
	else:
		var roll_result: float = rng.randf()
		
		items_rolled.append_array(valid_items.filter(func(item: LootItem): return item.chance.roll_overcome(roll_result)))
	
	return items_rolled


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


func _generate_loot_by_mode(mode: LootTableData.ProbabilityMode = loot_table_data.probability_mode) -> Array[LootItem]:
	var items_looted: Array[LootItem] = []
	
	match loot_table_data.probability_mode:
			loot_table_data.ProbabilityMode.Weight:
				items_looted.append_array(roll_items_by_weight())
				
			loot_table_data.ProbabilityMode.RollTier:
				items_looted.append_array(roll_items_by_tier())
				
			loot_table_data.ProbabilityMode.PercentageProbability:
				items_looted.append_array(roll_items_by_percentage())
				
			loot_table_data.ProbabilityMode.WeightRollTierCombined:
				var weight_items_looted: Array[LootItem] = roll_items_by_weight()
				var tier_items_looted: Array[LootItem] = roll_items_by_tier()
			
				items_looted.append_array(PluginUtilities.intersected_elements(weight_items_looted, tier_items_looted))
			
			loot_table_data.ProbabilityMode.WeightPercentageCombined:
				var weight_items_looted: Array[LootItem] = roll_items_by_weight()
				var percentage_items_looted: Array[LootItem] = roll_items_by_percentage()
			
				items_looted.append_array(PluginUtilities.intersected_elements(weight_items_looted, percentage_items_looted))
			
			loot_table_data.ProbabilityMode.RollTierPercentageCombined:
				var tier_items_looted: Array[LootItem] = roll_items_by_tier()
				var percentage_items_looted: Array[LootItem] = roll_items_by_percentage()
			
				items_looted.append_array(PluginUtilities.intersected_elements(tier_items_looted, percentage_items_looted))
			
			loot_table_data.ProbabilityMode.WeightPercentageRollTierCombined:
				var weight_items_looted: Array[LootItem] = roll_items_by_weight()
				var tier_items_looted: Array[LootItem] = roll_items_by_tier()
				var percentage_items_looted: Array[LootItem] = roll_items_by_percentage()
				
				var weight_tier_intersects: bool = PluginUtilities.intersects(weight_items_looted, tier_items_looted)
				var weight_percentage_intersects: bool = PluginUtilities.intersects(weight_items_looted, percentage_items_looted)
				
				if weight_tier_intersects and weight_percentage_intersects:
					items_looted.append_array(PluginUtilities.intersected_elements(weight_items_looted, tier_items_looted))
				
	return items_looted
	
	
func _prepare_weight_on_items(target_items: Array[LootItem] = mirrored_items) -> float:
	var total_weight: float = 0.0
	
	for item: LootItem in target_items:
		item.reset_accum_weight()
		total_weight += item.weight.value
		item.accum_weight = total_weight
	
	return total_weight + loot_table_data.extra_weight_bias

		
func _prepare_random_number_generator() -> void:
	if loot_table_data.seed_value > 0:
		rng.seed = loot_table_data.seed_value
	elif not loot_table_data.seed_string.is_empty():
		rng.seed = loot_table_data.seed_string.hash()
		

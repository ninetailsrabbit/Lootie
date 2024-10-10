class_name LootTableData extends Resource

enum ProbabilityMode {
	Weight, ## The type of probability technique to apply on a loot, weight is the common case and generate random decimals while each time sum the weight of the next item
	RollTier, ##  The roll tier uses a max roll number and define a number range for each tier.
	PercentageProbability ## A standard chance based on percentages
}

## The available items that will be used on a roll for this loot table
@export var available_items: Array[LootItem] = []
@export var probability_type: ProbabilityMode = ProbabilityMode.Weight:
	set(value):
		probability_type = value
		notify_property_list_changed()
## When this is enabled items can be repeated for multiple rolls on this generation
@export var allow_duplicates: bool = false
## Max items that this loot table can generate on multiple rolls
@export var items_limit_per_loot: int = 3:
	set(value):
		items_limit_per_loot = value
		fixed_items_per_loot = min(fixed_items_per_loot, items_limit_per_loot)
## The minimum amount of items will be generated on each roll, it cannot be greater than items_limit_per_loot
@export var fixed_items_per_loot: int = 1:
	set(value):
		fixed_items_per_loot = min(value, items_limit_per_loot)
## Each time the a roll/generate function is called, if no number of times is specified, this value will be used.
@export var default_roll_times_each_generation: int = 2
## Set to zero to not use it. This has priority over seed_string. Define a seed for this loot table. Doing so will give you deterministic results across runs
@export var seed_value: int = 0
## Set it to empty to not use it. Define a seed string that will be hashed to use for deterministic results
@export var seed_string: String = ""
@export_group("Weight")
## In each roll, all the items that meet the requirements of the roll will be added to the loot.
@export var choose_all_possible_candidates_each_roll_weight: bool = false
## When choose_all_possible_candidates_each_roll is false, in each roll, this is the maximum number of items that can be added to the loot
@export var number_of_items_that_can_be_selected_per_roll_weight: int = 1
## A little bias that is added to the total weight to increase the difficulty to drop more items
@export var extra_weight_bias: float = 0.0
@export_group("Roll Tier")
## In each roll, all the items that meet the requirements of the roll will be added to the loot.
@export var choose_all_possible_candidates_each_roll_tier: bool = false
## When choose_all_possible_candidates_each_roll is false, in each roll, this is the maximum number of items that can be added to the loot
@export var number_of_items_that_can_be_selected_per_roll_tier: int = 1
## The max roll value will be clamped to the maximum that can be found in the items available for this loot table. 
## So if you set this value to 100 and in the items the maximun found it's 80, this last will be used instead of 100
@export var limit_max_roll_tier_to_maximum_from_available_items: bool = false:
	set(value):
		if value != limit_max_roll_tier_to_maximum_from_available_items:
			limit_max_roll_tier_to_maximum_from_available_items = value
			
			if value:
				max_roll_tier = max_current_rarity_roll()
@export_group("Probability Percentage")
@export var choose_all_possible_candidates_each_chance: bool = false
## When choose_all_possible_candidates_each_chance is false, in each chance, this is the maximum number of items that can be added to the loot
@export var number_of_items_that_can_be_selected_per_chance: int = 1


## Each time a random number between min_roll_tier and max roll will be generated, based on this result if the number
## fits on one of the rarity roll ranges, items of this rarity will be picked randomly
@export var min_roll_tier: float = 0.0:
	set(value):
		min_roll_tier = absf(value)
## Each time a random number between min_roll_tier and max roll will be generated, based on this result if the number
## fits on one of the rarity roll ranges, items of this rarity will be picked randomly
@export var max_roll_tier: float = 100.0:
	set(value):
		if limit_max_roll_tier_to_maximum_from_available_items:
			var max_available_roll = max_current_rarity_roll()
			
			if max_available_roll:
				max_roll_tier = clampf(absf(value), 0.0, max_available_roll)
		else:
			max_roll_tier = absf(value)


func _init(items: Array[Variant] = []) -> void:
	if not items.is_empty():
		if typeof(items.front()) == TYPE_DICTIONARY:
			_create_from_dictionary(items)
		elif items.front() is LootItem:
			available_items.append_array(items)
	

func items_with_rarity_available(items: Array[LootItem] = available_items) -> Array[LootItem]:
	return items.filter(func(item: LootItem): return item.rarity is LootItemRarity)


func items_with_valid_chance(items: Array[LootItem] = available_items) -> Array[LootItem]:
	return items.filter(func(item: LootItem): return item.chance > 0)


func max_current_rarity_roll() -> float:
	var max_available_roll = items_with_rarity_available(available_items)\
		.map(func(item: LootItem): return item.rarity.max_roll).max()
	

	if max_available_roll:
		return max_available_roll
		
	return max_roll_tier


func _create_from_dictionary(items: Array[Dictionary]= []) -> void:
	if not items.is_empty():
		for item: Dictionary in items:
			available_items.append(LootItem.create_from(item))

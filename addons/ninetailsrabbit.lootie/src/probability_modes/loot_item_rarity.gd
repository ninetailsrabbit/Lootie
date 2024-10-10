class_name LootItemRarity extends Resource

## Expand here as to adjust it to your game requirements
enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC, ETERNAL, ABYSSAL, COSMIC, DIVINE} 

@export var rarity: ItemRarity = ItemRarity.COMMON
## The minimum value in range to be available on the roll pick
@export var min_roll: float
## The maximum value in range to be available on the roll pick
@export var max_roll: float


func roll(selected_min_roll_tier: float, selected_max_roll_tier: float) -> bool:
	var item_rarity_roll = randf_range(selected_min_roll_tier, selected_max_roll_tier)
	
	return decimal_value_is_between(snappedf(item_rarity_roll, 0.01), min_roll, max_roll)


func decimal_value_is_between(number: float, min_value: float, max_value: float, inclusive: = true, precision: float = 0.00001) -> bool:
	if inclusive:
		min_value -= precision
		max_value += precision

	return number >= min(min_value, max_value) and number <= max(min_value, max_value)

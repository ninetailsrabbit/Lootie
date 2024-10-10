class_name LootItemWeight extends Resource

## The weight value for this items to appear in a loot, the more the weight, more the chance to be looted
@export var value: float = 1.0

var accum_weight: float = 0.0

func reset_accum_weight() -> void:
	accum_weight = 0.0

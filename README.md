<div align="center">
	<img src="icon.svg" alt="Logo" width="160" height="160">

<h3 align="center">Lootie</h3>

  <p align="center">
  	Portable loot table for Godot Games
	<br />
	·
	<a href="https://github.com/ninetailsrabbit/lootie/issues/new?assignees=ninetailsrabbit&labels=%F0%9F%90%9B+bug&projects=&template=bug_report.md&title=">Report Bug</a>
	·
	<a href="https://github.com/ninetailsrabbit/lootie/issues/new?assignees=ninetailsrabbit&labels=%E2%AD%90+feature&projects=&template=feature_request.md&title=">Request Features</a>
  </p>
</div>

<br>
<br>

`Lootie` serves as a tool for game developers to define and manage the random generation of loot items within their games. It allows specifying a list of available items with their respective weights or rarity tiers, enabling the generation of loot with controlled probabilities. The class offers various methods for adding, removing, and manipulating the loot items, along with two primary generation methods: `weight-based` and `roll-tier based`

- [📦 Installation](#-installation)
- [Getting started](#getting-started)
	- [Creating a new loot table.](#creating-a-new-loot-table)
		- [LootTableData](#loottabledata)
		- [LootItem](#lootitem)
		- [LootItemRarity](#lootitemrarity)
	- [Adding items to a LootieTable](#adding-items-to-a-lootietable)
	- [🎲 Generating loot](#-generating-loot)
		- [Using Weight mode](#using-weight-mode)
		- [Using RollTier mode](#using-rolltier-mode)

# 📦 Installation

1. [Download Latest Release](https://github.com/ninetailsrabbit/lootie/releases/latest)
2. Unpack the `addons/ninetailsrabbit.lootie` folder into your `/addons` folder within the Godot project
3. Enable this addon within the Godot settings: `Project > Project Settings > Plugins`

To better understand what branch to choose from for which Godot version, please refer to this table:
|Godot Version|Lootie Branch|Lootie Version|
|---|---|--|
|[![GodotEngine](https://img.shields.io/badge/Godot_4.3.x_stable-blue?logo=godotengine&logoColor=white)](https://godotengine.org/)|`main`|`1.x`|

# Getting started

Once the plugin it's enabled you have access to `LootieTable` and `LootieGlobal`. The `LootieGlobal` autoload works to manage loot tables that needs to be accessed globally so you can create tables for a specific map or put all the items in it, the decision is yours.

## Creating a new loot table.

To create a new table it's simple to add the node in the desired scene via editor:

![lootie_search](images/lootie_table_search.png)

---

![lootie_search](images/lootie_table_node.png)

### LootTableData

This resource allows you to set the parameters for the `LootieTable` needs to generate the loot. As resource it can be reused so you can create it once and save it in your project.

```swift
class_name LootTableData extends Resource

enum ProbabilityMode {
	Weight, // The type of probability technique to apply on a loot, weight is the common case and generate random decimals while each time sum the weight of the next item
	RollTier //  The roll tier uses a max roll number and define a number range for each tier.
}

// The available items that will be used on a roll for this loot table
@export var available_items: Array[LootItem] = []

@export var probability_type: ProbabilityMode = ProbabilityMode.Weight

// When this is enabled items can be repeated for multiple rolls on this generation
@export var allow_duplicates: bool = false

// Max items that this loot table can generate on multiple rolls
@export var items_limit_per_loot: int = 3

// The minimum amount of items will be generated on each roll, it cannot be greater than items_limit_per_loot
@export var fixed_items_per_loot: int = 1

// Each time the a roll/generate function is called, if no number of times is specified, this value will be used.
@export var default_roll_times_each_generation: int = 2

// Set to zero to not use it. This has priority over seed_string. Define a seed for this loot table. Doing so will give you deterministic results across runs
@export var seed_value: int = 0

// Set it to empty to not use it. Define a seed string that will be hashed to use for deterministic results
@export var seed_string: String = ""

@export_group("Weight")
// In each roll, all the items that meet the requirements of the roll will be added to the loot.
@export var choose_all_possible_candidates_each_roll_weight: bool = false

// When choose_all_possible_candidates_each_roll is false, in each roll, this is the maximum number of items that can be added to the loot
@export var number_of_items_that_can_be_selected_per_roll_weight: int = 1

// A little bias that is added to the total weight to increase the difficulty to drop more items
@export var extra_weight_bias: float = 0.0

@export_group("Roll tier")
// In each roll, all the items that meet the requirements of the roll will be added to the loot.
@export var choose_all_possible_candidates_each_roll_tier: bool = false

// When choose_all_possible_candidates_each_roll is false, in each roll, this is the maximum number of items that can be added to the loot
@export var number_of_items_that_can_be_selected_per_roll_tier: int = 1

// The max roll value will be clamped to the maximum that can be found in the items available for this loot table.
// So if you set this value to 100 and in the items the maximun found it's 80, this last will be used instead of 100
@export var limit_max_roll_tier_to_maximum_from_available_items: bool = false

// Each time a random number between min_roll_tier and max roll will be generated, based on this result if the number
// fits on one of the rarity roll ranges, items of this rarity will be picked randomly
@export var min_roll_tier: float = 0.0:
@export var max_roll_tier: float = 100.0


// You can set items when creating this resource via GDScript, it accept an array of Dictionaries that represent an item or the LootItem resource
// LootTableData.new([...])
func _init(items: Array[Variant] = []) -> void

```

### LootItem

This is a resource that act as a wrapper for your original items in-game, provides a series of parameters that will be important for the `LootieTable` to perform the calculations and obtain this items.

The `LootieTable` returns this resource in all generations so extracting the item information depends on the logic of your game.

- When the `ProbabilityMode` is set to `Weight` the `weight` value needs to be greater than zero
- When the `ProbabilityMode` is set to `RollTier` the `rarity` resource needs to be set _(if you want that item to be obtainable by rarity)_

This resource **can be created from a dictionary**, all values are optional and invalid keys will be ignored. The keys are converted to `snake_case` in the process so `"iD"` will still be valid

```swift
LootItem.create_from({"id": "sword_1", "name": "Sword", "weight": 1.5 })
LootItem.create_from({"iD": "potion", "rarity": LootItemRarity.new(LootItemRarity.ItemRarity.Common, 0, 50) })
```

---

```swift
class_name LootItem extends Resource

// Unique identifier for this item
@export var id: String = ""

// An optional file path that represents this item
@export_file var file

// An optional scene that represents this item
@export var scene: PackedScene

// The name of the item
@export var name : String

// A shortcut to display the name in short form for limited ui in screen
@export var abbreviation : String

// A description more detailed about this item
@export_multiline var description : String

// The weight value for this items to appear in a loot, the more the weight, more the chance to be looted
@export var weight: float = 1.0

// The grade of rarity for this item
@export var rarity: LootItemRarity

static func create_from(data: Dictionary = {}) -> LootItem:

```

### LootItemRarity

This is a simple resource to set the rules for the rarity of an item. The `min_roll` and `max_roll` is the range where this item can be obtained when the LootieTable makes a roll and generates a random value. This will be explained later but simply if it is between the `min_roll = 1` and `max_roll= 5`, a result of `3.5` would be valid to obtain this item and a `5.1` would not.

```swift
class_name LootItemRarity extends Resource

// Expand here as to adjust it to your game requirements
enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC, ETERNAL, ABYSSAL, COSMIC, DIVINE}

// The rarity definition
@export var rarity: ItemRarity = ItemRarity.COMMON
// The minimum value in range to be available on the roll pick
@export var min_roll: float
// The maximum value in range to be available on the roll pick
@export var max_roll: float
```

## Adding items to a LootieTable

This operation can be done **from the editor** or via script

**_From the editor:_**

![add_loot_item_editor](images/add_loot_item.png)

---

**_From a script_**:

```swift
extends Node

@onready var lootie_table: LootieTable = $LootieTable

func _ready() -> void:
	// Multiple items at once
	lootie_table.add_items([LootItem.new(...), LootItem.new(...), LootItem.new(...)])

	// Individually
	lootie_table.add_item(LootItem.new(...))

	// The not recommended way to add new items
	lootie_table.loot_table_data.available_items.append(LootItem.new(...))
	lootie_table.loot_table_data.available_items.append_array([LootItem.new(...), LootItem.new(...), LootItem.new(...)])

	//Remove items by passing an Array of resources or ids
	lootie_table.remove_items([LootItem1, LootItem2])
	lootie_table.remove_items_by_id("sword_1", "basic_potion")

	//Remove item by passing the resource or the id
	lootie_table.remove_item(LootItem)
	lootie_table.remove_item_by_id("sword_1")
```

## 🎲 Generating loot

The function `roll()` it's the only thing you need, it accepts a number of `times` to roll and `except` optional items that you do not want to appear in loot.

The `LootieTable` uses the `LootTableData` that it uses as rules to generate loot based on the selected mode, **depending on your rules** it is possible for a roll **to return an empty array.** To avoid this you can define a `fixed_items_per_loot` that you always want to return.

`func roll(times: int = loot_table_data.default_roll_times_each_generation, except: Array[LootItem] = []) -> Array[LootItem]:`

```swift
var items_rolled: Array[LootItem] = lootie_table.roll() // Roll times set on default value
// Or
var items_rolled: Array[LootItem] = lootie_table.roll(10) // Roll 10 times so they are more chances to appear items in the loot

// You can change the probability type before rolling again
lootie_table.change_probability_type(LootTableData.ProbabilityMode.RollTier)

var items_rolled: Array[LootItem] = lootie_table.roll(3)

```

### Using Weight mode

`weight` needs to be greater than zero on each `LootItem` to be valid for this roll

This method iterates through the available items, calculating their accumulative weights and randomly selecting items based on the accumulated weight values. It repeats this process for the specified `times` parameter, potentially returning up to `items_limit_per_loot` items while considering the `allow_duplicates` flag.

**The more the weight of the item, the more chances to appear in the loot**.

You can set the `extra_weight_bias` to increase the difficulty to generate the loot using `weight_mode`, this could be used to start with a high value and decrease it as the player progresses through the game e.g.

### Using RollTier mode

**The items needs to have a `LootItemRarity` set to be valid for this roll**

This method generates random numbers within the specified `max_roll` range and compares them to the defined rarity tiers of the available items. Based on the roll results, it randomly selects items corresponding to the matching rarity tiers, repeating for the specified times parameter and potentially returning up to `items_limit_per_loot` while considering the `allow_duplicates` flag

As you notice in `LootItemRarity` there are two properties that works as a range:

- `min_roll`: The minimum roll value to be valid as posibly generated
- `max_roll`: The maximum roll value to be valid as posibly generated.

So if my item has a `min_roll` of 5 and `max_roll` of 20. Only values between 5 and 20 in each roll tier generation will be valid to return this item.

Higher roll ranges for an item in `roll_tier` generations means more probabilities to be returned.

Imagine I defined a `LootTable` with a `max_roll` of 100, so in each generation a random number between 0-100 will be randomly calculated. If the number is 7.55, items where this number falls within the valid range will be candidates for return.

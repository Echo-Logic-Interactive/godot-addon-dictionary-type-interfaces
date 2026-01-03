# 🎯 Dictionary Type Interfaces for Godot

[![Godot](https://img.shields.io/badge/Godot-4.0+-blue.svg)](https://godotengine.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-orange.svg)]()

> **Structured, validated data objects for Godot games**
> Define schemas once, validate everywhere, eliminate runtime dictionary errors

---

## 📋 Table of Contents

- [Features](#-features)
- [Why TypedDict?](#-why-typeddict)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Core Concepts](#-core-concepts)
- [Creating Interfaces](#-creating-interfaces)
- [Usage Patterns](#-usage-patterns)
- [Extending for Mods](#-extending-for-mods)
- [Performance](#-performance)
- [API Reference](#-api-reference)
- [Examples](#-examples)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Features

✅ **Runtime Type Validation** - Catch data structure errors before they cause crashes<br>
✅ **ORM-Style Data Objects** - Define schemas as classes, create validated instances<br>
✅ **IDE Autocomplete** - Full IntelliSense support with typed properties<br>
✅ **Zero Boilerplate** - Simple inheritance pattern, no manual validation calls<br>
✅ **Flexible Validation** - Strict or loose modes for different use cases<br>
✅ **Dictionary Compatible** - Easy conversion to/from dictionaries for save/load<br>
✅ **Mod-Friendly** - Extend and override interfaces for custom content<br>
✅ **Production Ready** - Validation can be stripped in release builds<br>

---

## 🤔 Why TypedDict?

### The Problem

```gdscript
# Traditional untyped dictionaries are error-prone
var player_data = {
    "name": "Hero",
    "lvl": 5,  # Typo! Should be "level"
    "health": "100"  # Wrong type! Should be float
}

# This fails at runtime... somewhere... maybe?
save_game(player_data)
```

### The Solution

```gdscript
# TypedDict catches errors immediately
var player = IPlayerData.new({
    "name": "Hero",
    "lvl": 5,  # ❌ Validation fails! Missing "level" field
    "health": "100"  # ❌ Type mismatch! Expected float
})
```

---

## 📦 Installation

### Method 1: Manual Installation

1. Download or clone this repository
2. Copy the `addons/godot-addon-dictionary-type-interfaces` folder to your project's `addons/` directory
3. Enable the plugin in **Project → Project Settings → Plugins → Dictionary Type Interfaces**
4. Restart Godot

### Method 2: AssetLib (Coming Soon)

Search for "TypedDict" or "Dictionary Type Interfaces" in Godot's AssetLib.

### Verify Installation

The `TypeInterfaces` singleton should be available globally. Test it:

```gdscript
func _ready():
    print(TypeInterfaces)  # Should print the singleton instance
```

---

## 🚀 Quick Start

### 1. Define an Interface

Create a new script that extends `TypedDict`:

```gdscript
# scripts/interfaces/player_interfaces.gd
class_name IPlayerData
extends TypedDict

func _get_schema() -> Dictionary:
    return {
        "name": "String",
        "level": "int",
        "health": "float",
        "position": "Vector2"
    }

# Optional: Add typed properties for IDE support
var name: String:
    get: return get_value("name", "")
    set(value): set_value("name", value)

var level: int:
    get: return get_value("level", 1)
    set(value): set_value("level", value)
```

### 2. Create Instances

```gdscript
# Create a validated player object
var player = IPlayerData.new({
    "name": "Hero",
    "level": 5,
    "health": 100.0,
    "position": Vector2(50, 100)
})

# Access with type safety
player.level += 1
print("Player: ", player.name, " - Level: ", player.level)
```

### 3. Convert to/from Dictionaries

```gdscript
# Save to file
func save_game(player: IPlayerData):
    var save_data = player.to_dict()
    var file = FileAccess.open("user://save.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data))

# Load from file
func load_game() -> IPlayerData:
    var file = FileAccess.open("user://save.json", FileAccess.READ)
    var json = JSON.parse_string(file.get_as_text())
    return IPlayerData.new(json)
```

---

## 🧠 Core Concepts

### TypedDict Base Class

All interfaces extend `TypedDict`, which provides:

- **`_get_schema()`** - Override to define your data structure
- **`to_dict()`** - Convert to a plain dictionary
- **`get_value(key, default)`** - Safe value access
- **`set_value(key, value)`** - Validated value setting

### Validation Happens Automatically

```gdscript
# On creation
var player = IPlayerData.new({...})  # Validates immediately

# On modification (if using set_value)
player.set_value("level", 10)  # Validates before setting
```

### Schema Types

Supported type strings in `_get_schema()`:

| Type String       | GDScript Type   | Example            |
| ----------------- | --------------- | ------------------ |
| `"String"`        | String          | `"hello"`          |
| `"int"`           | int             | `42`               |
| `"float"`         | float           | `3.14`             |
| `"bool"`          | bool            | `true`             |
| `"Dictionary"`    | Dictionary      | `{}`               |
| `"Array"`         | Array           | `[]`               |
| `"Array<String>"` | Typed Array     | `["a", "b"]`       |
| `Vector2`         | Vector2         | `Vector2(1, 2)`    |
| `Vector3`         | Vector3         | `Vector3(1, 2, 3)` |
| `Color`           | Color           | `Color.RED`        |
| `"String?"`       | Nullable String | `null` or `"text"` |

---

## 🏗️ Creating Interfaces

### Basic Interface

```gdscript
class_name IItem
extends TypedDict

func _get_schema() -> Dictionary:
    return {
        "id": "String",
        "name": "String",
        "quantity": "int",
        "value": "int"
    }
```

### Interface with Typed Properties

```gdscript
class_name IItem
extends TypedDict

func _get_schema() -> Dictionary:
    return {
        "id": "String",
        "name": "String",
        "quantity": "int",
        "value": "int"
    }

var id: String:
    get: return get_value("id", "")
    set(value): set_value("id", value)

var name: String:
    get: return get_value("name", "")
    set(value): set_value("name", value)

var quantity: int:
    get: return get_value("quantity", 1)
    set(value): set_value("quantity", value)

var value: int:
    get: return get_value("value", 0)
    set(value): set_value("value", value)
```

### Grouping Related Interfaces (Recommended)

```gdscript
# scripts/interfaces/player_interfaces.gd
# Groups player and inventory data structures

class_name IPlayerData
extends TypedDict

func _get_schema() -> Dictionary:
    return {
        "name": "String",
        "level": "int",
        "health": "float",
        "position": "Vector2"
    }

# Add typed properties...


class_name IItem
extends TypedDict

func _get_schema() -> Dictionary:
    return {
        "id": "String",
        "name": "String",
        "quantity": "int"
    }

# Add typed properties...
```

---

## 💡 Usage Patterns

### Pattern 1: Factory Functions

```gdscript
class PlayerFactory:
    static func create_warrior() -> IPlayerData:
        return IPlayerData.new({
            "name": "Warrior",
            "level": 1,
            "health": 150.0,
            "position": Vector2.ZERO
        })

    static func create_mage() -> IPlayerData:
        return IPlayerData.new({
            "name": "Mage",
            "level": 1,
            "health": 80.0,
            "position": Vector2.ZERO
        })
```

### Pattern 2: Builder Pattern

```gdscript
class QuestBuilder:
    var _data: Dictionary = {}

    func set_title(title: String) -> QuestBuilder:
        _data["title"] = title
        return self

    func set_description(desc: String) -> QuestBuilder:
        _data["description"] = desc
        return self

    func add_objective(obj: String) -> QuestBuilder:
        if not _data.has("objectives"):
            _data["objectives"] = []
        _data["objectives"].append(obj)
        return self

    func build() -> IQuest:
        _data["status"] = "active"
        _data["progress"] = 0.0
        return IQuest.new(_data)

# Usage
var quest = QuestBuilder.new() \
    .set_title("First Quest") \
    .set_description("Complete the tutorial") \
    .add_objective("Talk to NPC") \
    .build()
```

### Pattern 3: Repository Pattern

```gdscript
class PlayerRepository:
    var _storage: Dictionary = {}

    func save(id: String, player: IPlayerData) -> void:
        _storage[id] = player.to_dict()

    func load(id: String) -> IPlayerData:
        var data = _storage.get(id)
        return IPlayerData.new(data) if data else null

    func get_all() -> Array:
        var players: Array = []
        for data in _storage.values():
            players.append(IPlayerData.new(data))
        return players
```

### Pattern 4: Service Layer

```gdscript
class InventoryService:
    var _items: Array = []  # Array of IItem

    func add_item(item: IItem) -> void:
        # Check if item exists
        for existing in _items:
            if existing.id == item.id:
                existing.quantity += item.quantity
                return
        _items.append(item)

    func remove_item(item_id: String, amount: int = 1) -> bool:
        for item in _items:
            if item.id == item_id:
                if item.quantity >= amount:
                    item.quantity -= amount
                    if item.quantity <= 0:
                        _items.erase(item)
                    return true
        return false

    func get_total_value() -> int:
        var total = 0
        for item in _items:
            total += item.value * item.quantity
        return total
```

---

## 🔧 Extending for Mods

TypedDict is designed to be **mod-friendly**. Modders can extend your interfaces to add custom fields without breaking the base game.

### Base Game Interface

```gdscript
# scripts/interfaces/player_interfaces.gd
class_name IPlayerData
extends TypedDict

func _get_schema() -> Dictionary:
    return {
        "name": "String",
        "level": "int",
        "health": "float",
        "position": "Vector2"
    }

var name: String:
    get: return get_value("name", "")
    set(value): set_value("name", value)

var level: int:
    get: return get_value("level", 1)
    set(value): set_value("level", value)
```

### Mod Extension Pattern 1: Inheritance

Modders can extend your interface to add new fields:

```gdscript
# mods/magic_mod/player_data_extended.gd
class_name IPlayerDataExtended
extends IPlayerData

func _get_schema() -> Dictionary:
    var base_schema = super._get_schema()
    # Add mod-specific fields
    base_schema.merge({
        "mana": "float",
        "max_mana": "float",
        "spell_power": "int"
    })
    return base_schema

# Add typed properties for mod fields
var mana: float:
    get: return get_value("mana", 100.0)
    set(value): set_value("mana", value)

var max_mana: float:
    get: return get_value("max_mana", 100.0)
    set(value): set_value("max_mana", value)

var spell_power: int:
    get: return get_value("spell_power", 10)
    set(value): set_value("spell_power", value)
```

### Mod Extension Pattern 2: Composition

For more complex mods, use composition instead of inheritance:

```gdscript
# mods/class_system/class_data.gd
class_name IClassData
extends TypedDict

func _get_schema() -> Dictionary:
    return {
        "class_name": "String",
        "abilities": "Array<String>",
        "passive_bonuses": "Dictionary"
    }

# Mod's extended player data
class_name IModPlayerData
extends IPlayerData

func _get_schema() -> Dictionary:
    var base_schema = super._get_schema()
    base_schema["class_data"] = "Dictionary"  # Will contain IClassData
    return base_schema

var class_data: IClassData:
    get:
        var data = get_value("class_data", {})
        return IClassData.new(data) if data else null
    set(value):
        set_value("class_data", value.to_dict() if value else {})
```

### Mod Extension Pattern 3: Optional Fields

Make mod fields optional using nullable types:

```gdscript
# mods/reputation_mod/player_data_extended.gd
class_name IPlayerDataWithReputation
extends IPlayerData

func _get_schema() -> Dictionary:
    var base_schema = super._get_schema()
    # Optional fields - won't break base game saves
    base_schema.merge({
        "faction_reputation": "Dictionary?",  # Nullable
        "alignment": "String?"  # Nullable
    })
    return base_schema

var faction_reputation: Dictionary:
    get: return get_value("faction_reputation", {})
    set(value): set_value("faction_reputation", value)

var alignment: String:
    get: return get_value("alignment", "neutral")
    set(value): set_value("alignment", value)
```

### Best Practices for Mod Support

#### 1. **Use Loose Validation Mode**

Allow mods to add extra fields without breaking validation:

```gdscript
# Base game validation (loose mode - default)
var player_data = IPlayerData.new(loaded_data)  # Extra fields allowed

# Strict mode (not recommended for moddable games)
assert(TypeInterfaces.validate(loaded_data, schema, true))  # Fails if extra fields
```

#### 2. **Version Your Save Data**

```gdscript
class_name ISaveData
extends TypedDict

func _get_schema() -> Dictionary:
    return {
        "version": "String",
        "game_data": "Dictionary",
        "mod_data": "Dictionary?"  # Mods can store custom data here
    }

func save_game():
    var save = ISaveData.new({
        "version": "1.0.0",
        "game_data": {...},
        "mod_data": get_mod_data()  # Collect from all loaded mods
    })
```

#### 3. **Provide Migration Helpers**

```gdscript
class DataMigrator:
    static func migrate_player_data(old_data: Dictionary, from_version: String) -> Dictionary:
        match from_version:
            "1.0.0":
                # Add new fields with defaults
                old_data["new_field"] = "default_value"
            "1.1.0":
                # Transform data structure
                old_data["stats"] = _convert_old_stats(old_data.get("old_stats", {}))
        return old_data
```

#### 4. **Document Extension Points**

```gdscript
## Player Data Interface
##
## MODDERS: You can extend this interface to add custom player data.
## Example:
##   class_name IPlayerDataExtended extends IPlayerData
##   func _get_schema() -> Dictionary:
##       var schema = super._get_schema()
##       schema.merge({"custom_field": "String"})
##       return schema
##
class_name IPlayerData
extends TypedDict
```

### Example: Complete Mod Integration

```gdscript
# Base game
class_name GameManager

var player: IPlayerData

func create_player() -> IPlayerData:
    # Check if any mod has extended the player interface
    var player_class = _get_extended_player_class()
    return player_class.new({
        "name": "Hero",
        "level": 1,
        "health": 100.0,
        "position": Vector2.ZERO
    })

func _get_extended_player_class():
    # Let mods register their extended classes
    if ModLoader.has_extended_class("IPlayerData"):
        return ModLoader.get_extended_class("IPlayerData")
    return IPlayerData
```

---

## ⚡ Performance

### Runtime Validation Cost

Validation **only runs when you create or modify TypedDict instances**. It does NOT run on every property access.

```gdscript
# Validation happens here (once)
var player = IPlayerData.new({...})

# No validation - direct property access
print(player.name)  # Fast!
print(player.level)  # Fast!

# Validation happens here (if using set_value)
player.set_value("level", 10)  # Validates

# No validation - direct property setter
player.level = 10  # Fast! (if you defined the property)
```

### Production Builds

Validation uses `assert()` which is **automatically removed** in release builds by Godot. No manual changes needed!

```gdscript
# In TypedDict._init():
assert(TypeInterfaces.validate(initial_data, schema))
# ↑ This line disappears in release builds!
```

### Performance Tips

✅ **Cache interface instances** - Don't recreate on every frame
✅ **Use typed properties** - Faster than `get_value()` calls
✅ **Validate once** - Create validated objects, then pass them around
❌ **Don't validate in loops** - Create validated objects outside hot paths

---

## 📚 API Reference

### TypedDict Base Class

#### Methods

```gdscript
func _get_schema() -> Dictionary
```

**Override this** to define your interface structure. Return a dictionary mapping field names to type strings.

**Example:**

```gdscript
func _get_schema() -> Dictionary:
    return {
        "name": "String",
        "level": "int",
        "health": "float"
    }
```

---

```gdscript
func to_dict() -> Dictionary
```

Returns a duplicate of the internal dictionary data.

**Returns:** Dictionary containing all field data

**Example:**

```gdscript
var player = IPlayerData.new({...})
var save_data = player.to_dict()
```

---

```gdscript
func get_value(key: String, default = null) -> Variant
```

Safely get a value with an optional default.

**Parameters:**

- `key`: Field name to retrieve
- `default`: Value to return if key doesn't exist

**Returns:** Field value or default

**Example:**

```gdscript
var level = player.get_value("level", 1)
```

---

```gdscript
func set_value(key: String, value: Variant) -> void
```

Set a value with validation (asserts in debug builds).

**Parameters:**

- `key`: Field name to set
- `value`: New value for the field

**Example:**

```gdscript
player.set_value("level", 10)
```

---

```gdscript
func has_key(key: String) -> bool
```

Check if a key exists in the data.

**Returns:** `true` if key exists

---

```gdscript
func keys() -> Array
```

Get all keys in the data.

**Returns:** Array of all field names

---

```gdscript
func values() -> Array
```

Get all values in the data.

**Returns:** Array of all field values

---

```gdscript
func update(data: Dictionary) -> void
```

Merge multiple fields at once with validation.

**Parameters:**

- `data`: Dictionary of fields to merge

**Example:**

```gdscript
player.update({
    "level": 10,
    "health": 150.0
})
```

---

### TypeInterfaces Singleton

```gdscript
TypeInterfaces.validate(data: Dictionary, schema: Dictionary, strict: bool = false) -> bool
```

Manually validate a dictionary against a schema.

**Parameters:**

- `data`: Dictionary to validate
- `schema`: Schema definition (same format as `_get_schema()`)
- `strict`: If `true`, disallows extra fields not in schema

**Returns:** `true` if valid, `false` otherwise

**Example:**

```gdscript
var is_valid = TypeInterfaces.validate(
    {"name": "Hero", "level": 5},
    {"name": "String", "level": "int"}
)
```

---

## 📖 Examples

Check out the included example files:

- **`scripts/examples/basic_usage.gd`** - Creating, modifying, and converting TypedDicts
- **`scripts/examples/advanced_patterns.gd`** - Factory, Builder, Repository, and Service patterns

### Example: Complete Save/Load System

```gdscript
extends Node

var player: IPlayerData

func _ready():
    # Create new player
    player = IPlayerData.new({
        "name": "Hero",
        "level": 1,
        "health": 100.0,
        "position": Vector2.ZERO
    })

func save_game():
    var save_file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
    var save_data = {
        "player": player.to_dict(),
        "timestamp": Time.get_unix_time_from_system()
    }
    save_file.store_string(JSON.stringify(save_data))

func load_game():
    if not FileAccess.file_exists("user://savegame.json"):
        return

    var save_file = FileAccess.open("user://savegame.json", FileAccess.READ)
    var json = JSON.parse_string(save_file.get_as_text())

    # Validated automatically on creation
    player = IPlayerData.new(json["player"])
    print("Loaded player: ", player.name, " at level ", player.level)
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

1. Clone the repository
2. Open in Godot 4.0+
3. Enable the plugin in Project Settings → Plugins
4. Run the example scenes in `scripts/examples`

---

## 📄 License

This project is licensed under the MIT License.

---

## 🙏 Acknowledgments

- Inspired by TypeScript interfaces and Python ORMs
- Built for the Godot community
- Thanks to all contributors!

---

## 📞 Support

- **Issues**: Report bugs or request features via GitHub Issues
- **Discussions**: Share ideas and ask questions
- **Discord**: Join the Godot community on Discord

---

<p align="center">Made with ❤️ for Godot developers</p>

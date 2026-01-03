# 🎯 Dictionary Type Interfaces for Godot

[![Godot](https://img.shields.io/badge/Godot-4.0+-blue.svg)](https://godotengine.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-orange.svg)]()

> **Structured, validated data objects for Godot games**
> Define schemas once, validate everywhere, eliminate runtime dictionary errors

---

## 📋 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [What is TypedDict?](#-what-is-typeddict)
- [Core Concepts](#-core-concepts)
- [Creating Interfaces](#-creating-interfaces)
- [Schema Exporter/Viewer](#-schema-exporterviewer)
- [Usage Patterns](#-usage-patterns)
- [Extending for Mods](#-extending-for-mods)
- [Performance](#-performance)
- [API Reference](#-api-reference)
- [Examples](#-examples)
- [Contributing](#-contributing)

---

## ✨ Features

✅ **Runtime Type Validation** - Catch data structure errors before they cause crashes<br>
✅ **ORM-Style Data Objects** - Define schemas as classes, create validated instances<br>
✅ **IDE Autocomplete** - Full IntelliSense support with typed properties<br>
✅ **Simple Inheritance** - Extend `TypedDict` or `ExtendableInterface` base classes<br>
✅ **Flexible Validation** - Strict or loose modes for different use cases<br>
✅ **Dictionary Compatible** - Easy conversion to/from dictionaries for save/load<br>
✅ **Mod-Friendly** - Built-in `ExtendableInterface` for safe mod extensions<br>
✅ **Production Ready** - Validation uses `assert()` (auto-removed in release builds)<br>

---

## 📦 Installation

### Method 1: Manual Installation

1. Download or clone this repository
2. Copy the `addons/godot-addon-dictionary-type-interfaces` folder to your project's `addons/` directory
3. Enable the plugin in **Project → Project Settings → Plugins**
4. Restart Godot

### Verify Installation

The `TypeInterfaces` singleton should be available globally:

```gdscript
func _ready():
    print(TypeInterfaces)  # Should print the singleton instance
```

---

## 🚀 Quick Start

### 1. Choose Your Base Class

TypedDict provides two base classes:

| Base Class                | Use When                                          |
| ------------------------- | ------------------------------------------------- |
| **`TypedDict`**           | Simple data structures, no mod support needed     |
| **`ExtendableInterface`** | Data that mods might extend (player, items, etc.) |

### 2. Define an Interface

**Option A: TypedDict (Simple)**

```gdscript
# scripts/interfaces/item_data.gd
class_name IItem
extends TypedDict

func _get_schema() -> Dictionary:
    return {
        "id": "String",
        "name": "String",
        "quantity": "int",
        "value": "int"
    }

# Optional: Add typed properties
var id: String:
    get: return get_value("id", "")
    set(value): set_value("id", value)

var quantity: int:
    get: return get_value("quantity", 1)
    set(value): set_value("quantity", value)
```

**Option B: ExtendableInterface (Mod-Friendly)**

```gdscript
# scripts/interfaces/player_data.gd
class_name IPlayerData
extends ExtendableInterface

func _get_schema() -> Dictionary:
    return {
        "name": "String",
        "level": "int",
        "health": "float",
        "max_health": "float",
        "position": Vector2
    }

# Optional: Add typed properties
var name: String:
    get: return get_value("name", "")
    set(value): set_value("name", value)

var level: int:
    get: return get_value("level", 1)
    set(value): set_value("level", value)
```

### 3. Create Instances

```gdscript
# Create validated objects
var player = IPlayerData.new({
    "name": "Hero",
    "level": 5,
    "health": 100.0,
    "max_health": 100.0,
    "position": Vector2(50, 100)
})

# Access with type safety
player.level += 1
print("Player: ", player.name, " - Level: ", player.level)
```

### 4. Save/Load with Dictionaries

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

## 🤔 What is TypedDict?

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
    "lvl": 5,  # ❌ Assert fails! Missing "level" field
    "health": "100"  # ❌ Assert fails! Type mismatch
})
```

---

## 🧠 Core Concepts

### Base Classes

#### TypedDict

Basic validated dictionary wrapper. Use for simple data structures.

```gdscript
class ISimpleData extends TypedDict:
    func _get_schema() -> Dictionary:
        return {"field": "String"}
```

#### ExtendableInterface

Designed for mod support. Allows safe schema extension by mods.

```gdscript
class IModdableData extends ExtendableInterface:
    func _get_schema() -> Dictionary:
        return {"base_field": "String"}
```

**Key Difference:** `ExtendableInterface` provides additional helper methods for merging schemas safely when mods extend your interfaces.

### Validation Behavior

Validation uses **`assert()`** which has important characteristics:

```gdscript
# In debug builds (default when running from editor)
var player = IPlayerData.new({})  # ❌ Assert fails! Missing fields

# In release builds (when exported)
var player = IPlayerData.new({})  # ⚠️ No validation! Assert is removed
```

**Important:** Godot automatically strips all `assert()` calls from release builds for performance.

### Schema Types

| Type String    | GDScript Type | Example            | Nullable        |
| -------------- | ------------- | ------------------ | --------------- |
| `"String"`     | String        | `"hello"`          | `"String?"`     |
| `"int"`        | int           | `42`               | `"int?"`        |
| `"float"`      | float         | `3.14`             | `"float?"`      |
| `"bool"`       | bool          | `true`             | `"bool?"`       |
| `"Dictionary"` | Dictionary    | `{}`               | `"Dictionary?"` |
| `"Array"`      | Array         | `[]`               | `"Array?"`      |
| `Vector2`      | Vector2       | `Vector2(1, 2)`    | -               |
| `Vector3`      | Vector3       | `Vector3(1, 2, 3)` | -               |
| `Color`        | Color         | `Color.RED`        | -               |

**Nullable Example:**

```gdscript
func _get_schema() -> Dictionary:
    return {
        "required_field": "String",
        "optional_field": "String?"  # Can be null
    }
```

---

## 💡 Schema Exporter/Viewer

### Awaiting details and examples

---

## 🏗️ Creating Interfaces

### Basic Interface (TypedDict)

```gdscript
class_name IWeatherData
extends TypedDict

func _get_schema() -> Dictionary:
    return {
        "condition": "String",
        "temperature": "float",
        "wind_speed": "float",
        "precipitation": "float"
    }
```

### Interface with Typed Properties

```gdscript
class_name IWeatherData
extends TypedDict

func _get_schema() -> Dictionary:
    return {
        "condition": "String",
        "temperature": "float",
        "wind_speed": "float"
    }

var condition: String:
    get: return get_value("condition", "clear")
    set(value): set_value("condition", value)

var temperature: float:
    get: return get_value("temperature", 20.0)
    set(value): set_value("temperature", value)

var wind_speed: float:
    get: return get_value("wind_speed", 0.0)
    set(value): set_value("wind_speed", value)
```

### Mod-Friendly Interface (ExtendableInterface)

```gdscript
class_name IPlayerData
extends ExtendableInterface

func _get_schema() -> Dictionary:
    return {
        "name": "String",
        "level": "int",
        "health": "float",
        "max_health": "float",
        "position": Vector2,
        "inventory": "Array"
    }

# Add typed properties...
```

---

## 💡 Usage Patterns

### Pattern 1: Factory Functions

```gdscript
class PlayerFactory:
    static func create_new_player(player_name: String, player_class: String) -> IPlayerData:
        var base_health = {
            "warrior": 150.0,
            "mage": 80.0,
            "rogue": 100.0
        }

        var health = base_health.get(player_class, 100.0)

        return IPlayerData.new({
            "name": player_name,
            "level": 1,
            "health": health,
            "max_health": health,
            "position": Vector2.ZERO,
            "inventory": []
        })

# Usage
var warrior = PlayerFactory.create_new_player("Conan", "warrior")
var mage = PlayerFactory.create_new_player("Gandalf", "mage")
```

### Pattern 2: Builder Pattern

```gdscript
class QuestBuilder:
    var _data: Dictionary = {}

    func set_id(quest_id: String) -> QuestBuilder:
        _data["id"] = quest_id
        return self

    func set_title(title: String) -> QuestBuilder:
        _data["title"] = title
        return self

    func add_objective(objective: String) -> QuestBuilder:
        if not _data.has("objectives"):
            _data["objectives"] = []
        _data["objectives"].append(objective)
        return self

    func build() -> IQuest:
        # Set defaults
        _data.get_or_add("status", "active")
        _data.get_or_add("progress", 0.0)
        return IQuest.new(_data)

# Usage
var quest = QuestBuilder.new() \
    .set_id("first_fish") \
    .set_title("First Catch") \
    .add_objective("Catch any fish") \
    .build()
```

### Pattern 3: Repository Pattern

```gdscript
class PlayerRepository:
    var _players: Dictionary = {}  # id -> Dictionary

    func save(player_id: String, player: IPlayerData) -> void:
        _players[player_id] = player.to_dict()

    func load(player_id: String) -> IPlayerData:
        var data = _players.get(player_id)
        return IPlayerData.new(data) if data else null

    func delete(player_id: String) -> void:
        _players.erase(player_id)

    func find_by_level(min_level: int) -> Array[IPlayerData]:
        var results: Array[IPlayerData] = []
        for data in _players.values():
            var player = IPlayerData.new(data)
            if player.level >= min_level:
                results.append(player)
        return results
```

---

## 🔧 Extending for Mods

### Why ExtendableInterface?

`ExtendableInterface` is specifically designed for data that mods might want to extend. It provides safe schema merging and helper methods.

### Base Game: Use ExtendableInterface

```gdscript
# scripts/interfaces/player_data.gd
class_name IPlayerData
extends ExtendableInterface

func _get_schema() -> Dictionary:
    return {
        "name": "String",
        "level": "int",
        "health": "float",
        "max_health": "float",
        "position": Vector2,
        "inventory": "Array"
    }

var name: String:
    get: return get_value("name", "")
    set(value): set_value("name", value)

var level: int:
    get: return get_value("level", 1)
    set(value): set_value("level", value)

# ... other properties
```

### Mod: Extend the Interface

```gdscript
# mods/magic_system/extended_player_data.gd
class_name IPlayerDataMagic
extends IPlayerData

func _get_schema() -> Dictionary:
    var base_schema = super._get_schema()

    # Add mod-specific fields
    base_schema.merge({
        "mana": "float",
        "max_mana": "float",
        "spell_power": "int",
        "known_spells": "Array"
    })

    return base_schema

# Add mod-specific typed properties
var mana: float:
    get: return get_value("mana", 100.0)
    set(value): set_value("mana", value)

var max_mana: float:
    get: return get_value("max_mana", 100.0)
    set(value): set_value("max_mana", value)

var spell_power: int:
    get: return get_value("spell_power", 10)
    set(value): set_value("spell_power", value)

var known_spells: Array:
    get: return get_value("known_spells", [])
    set(value): set_value("known_spells", value)
```

### Using Extended Interfaces

```gdscript
# Base game code works with either base or extended interfaces
func save_player(player: IPlayerData) -> void:
    var save_data = player.to_dict()  # Contains all fields (base + mod)
    # Save to file...

func load_player(data: Dictionary) -> IPlayerData:
    # Determine which class to use
    if ModLoader.is_mod_active("magic_system"):
        return IPlayerDataMagic.new(data)  # Includes mod fields
    else:
        return IPlayerData.new(data)  # Base fields only
```

### Mod-Friendly Best Practices

#### 1. **Use Nullable Fields for Optional Mod Data**

```gdscript
class IPlayerDataWithOptionalMods
extends IPlayerData

func _get_schema() -> Dictionary:
    var schema = super._get_schema()
    schema.merge({
        "faction_reputation": "Dictionary?",  # Nullable - won't break base saves
        "custom_data": "Dictionary?"  # Mods can store arbitrary data here
    })
    return schema
```

#### 2. **Provide Default Values**

```gdscript
var faction_reputation: Dictionary:
    get: return get_value("faction_reputation", {})  # Empty dict if missing
    set(value): set_value("faction_reputation", value)
```

#### 3. **Version Your Save Data**

```gdscript
class_name ISaveData
extends ExtendableInterface

func _get_schema() -> Dictionary:
    return {
        "version": "String",
        "player": "Dictionary",
        "world": "Dictionary",
        "mod_data": "Dictionary?"  # Mods store their data here
    }
```

---

## ⚡ Performance

### Validation Cost

Validation happens **only during object creation** using `assert()`:

```gdscript
# Validation runs here (in debug builds only)
var player = IPlayerData.new({...})

# No validation - direct property access
print(player.name)  # ✅ Fast
print(player.level)  # ✅ Fast

# Validation runs here (in debug builds
```

### Debug vs Release Builds

| Build Type | Validation Behavior |
|-----------|-------------------|
| **Debug** (Editor) | ✅ Full validation with asserts |
| **Release** (Exported) | ❌ Asserts removed, no validation |

**This is automatic** - Godot strips `assert()` from release builds for you.

### Custom Validation Control

If you want **manual control** over validation:

**Option 1: Conditional Validation**
```gdscript
class_name IPlayerData
extends TypedDict

func _init(initial_data: Dictionary = {}) -> void:
    var schema = _get_schema()
    
    # Only validate in debug mode
    if OS.is_debug_build():
        assert(TypeInterfaces.validate(initial_data, schema), "Validation failed")
    
    _data = initial_data.duplicate()
```

**Option 2: Always Validate (Even in Release)**
```gdscript
class_name ICriticalData
extends TypedDict

func _init(initial_data: Dictionary = {}) -> void:
    var schema = _get_schema()
    
    # Validate in all builds
    if not TypeInterfaces.validate(initial_data, schema):
        push_error("Critical data validation failed!")
        # Handle error appropriately
    
    _data = initial_data.duplicate()
```

**Option 3: Never Validate (Maximum Performance)**
```gdscript
class_name IUnsafeData
extends RefCounted  # Don't extend TypedDict

var _data: Dictionary

func _init(initial_data: Dictionary = {}) -> void:
    _data = initial_data.duplicate()  # No validation at all
```

### Performance Tips

✅ **Use typed properties** - Faster than `get_value()` calls  <br>
✅ **Cache instances** - Don't recreate validated objects  <br>
✅ **Validate once** - Create validated objects, then pass references  <br>
✅ **Batch operations** - Use `to_dict()` for bulk modifications  <br>
❌ **Don't validate in loops** - Create objects outside hot paths  <br>

---

## 📚 API Reference

### TypedDict Base Class

```gdscript
class_name TypedDict
extends RefCounted
```

#### Constructor

```gdscript
func _init(initial_data: Dictionary = {}) -> void
```

Creates a new TypedDict instance with validation.

**Parameters:**
- `initial_data` - Dictionary to populate the instance

**Validation:** Uses `assert()` - only runs in debug builds

---

#### Methods

```gdscript
func _get_schema() -> Dictionary
```

**Override this method** to define your data structure.

**Returns:** Dictionary mapping field names to type strings

**Example:**
```gdscript
func _get_schema() -> Dictionary:
    return {
        "name": "String",
        "level": "int",
        "health": "float",
        "position": Vector2
    }
```

---

```gdscript
func to_dict() -> Dictionary
```

Convert to a plain dictionary (shallow copy).

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

Safely retrieve a field value.

**Parameters:**
- `key` - Field name
- `default` - Value to return if key doesn't exist

**Returns:** Field value or default

---

```gdscript
func set_value(key: String, value: Variant) -> void
```

Set a field value with validation (debug builds only).

**Parameters:**
- `key` - Field name
- `value` - New value

---

```gdscript
func has_key(key: String) -> bool
```

Check if a field exists.

---

```gdscript
func keys() -> Array
```

Get all field names.

---

```gdscript
func values() -> Array
```

Get all field values.

---

### ExtendableInterface

```gdscript
class_name ExtendableInterface
extends TypedDict
```

Designed for mod support. Provides the same API as TypedDict with additional schema merging capabilities.

**Use when:** Your data structures might be extended by mods

---

### TypeInterfaces Singleton

```gdscript
# Global singleton - available everywhere
TypeInterfaces
```

#### Methods

```gdscript
func validate(data: Dictionary, schema: Dictionary, strict: bool = false) -> bool
```

Manually validate a dictionary against a schema.

**Parameters:**
- `data` - Dictionary to validate
- `schema` - Schema definition (same format as `_get_schema()`)
- `strict` - If `true`, rejects extra fields not in schema

**Returns:** `true` if valid, `false` otherwise

**Example:**
```gdscript
var schema = {"name": "String", "level": "int"}
var data = {"name": "Hero", "level": 5}

if TypeInterfaces.validate(data, schema):
    print("Valid!")
```

---

## 📖 Examples

### Example 1: Simple Item System

```gdscript
# Define the interface
class_name IItem
extends TypedDict

func _get_schema() -> Dictionary:
    return {
        "id": "String",
        "name": "String",
        "description": "String",
        "quantity": "int",
        "value": "int",
        "weight": "float"
    }

var id: String:
    get: return get_value("id", "")
    set(value): set_value("id", value)

var name: String:
    get: return get_value("name", "Unknown Item")
    set(value): set_value("name", value)

var quantity: int:
    get: return get_value("quantity", 1)
    set(value): set_value("quantity", value)

# Usage
var sword = IItem.new({
    "id": "iron_sword",
    "name": "Iron Sword",
    "description": "A basic iron sword",
    "quantity": 1,
    "value": 50,
    "weight": 3.5
})

sword.quantity += 1  # Type-safe modification
print("You have ", sword.quantity, " ", sword.name)
```

### Example 2: Save/Load System

```gdscript
class_name SaveManager

const SAVE_PATH = "user://savegame.json"

func save_game(player: IPlayerData) -> bool:
    var save_data = {
        "version": "1.0.0",
        "player": player.to_dict(),
        "timestamp": Time.get_unix_time_from_system()
    }
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if not file:
        push_error("Failed to open save file")
        return false
    
    file.store_string(JSON.stringify(save_data, "\t"))
    file.close()
    return true

func load_game() -> IPlayerData:
    if not FileAccess.file_exists(SAVE_PATH):
        return null
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    var json_string = file.get_as_text()
    file.close()
    
    var save_data = JSON.parse_string(json_string)
    if not save_data:
        push_error("Failed to parse save file")
        return null
    
    # Automatically validates on creation
    return IPlayerData.new(save_data["player"])
```

### Example 3: Inventory System

```gdscript
class_name Inventory

var _items: Array[IItem] = []
var _max_weight: float = 50.0

func add_item(item: IItem) -> bool:
    # Check weight limit
    var total_weight = get_total_weight()
    if total_weight + item.weight > _max_weight:
        return false
    
    # Stack with existing items
    for existing in _items:
        if existing.id == item.id:
            existing.quantity += item.quantity
            return true
    
    _items.append(item)
    return true

func remove_item(item_id: String, amount: int = 1) -> IItem:
    for item in _items:
        if item.id == item_id and item.quantity >= amount:
            item.quantity -= amount
            
            if item.quantity == 0:
                _items.erase(item)
            
            # Return what was removed
            var removed = IItem.new(item.to_dict())
            removed.quantity = amount
            return removed
    
    return null

func get_total_weight() -> float:
    var total = 0.0
    for item in _items:
        total += item.weight * item.quantity
    return total

func get_total_value() -> int:
    var total = 0
    for item in _items:
        total += item.value * item.quantity
    return total
```

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository<br>
2. Create a feature branch (`git checkout -b feature/amazing-feature`)<br>
3. Commit your changes (`git commit -m 'Add amazing feature'`)<br>
4. Push to the branch (`git push origin feature/amazing-feature`)<br>
5. Open a Pull Request<br>

### Development Guidelines

- Maintain backward compatibility<br>
- Add tests for new features<br>
- Update documentation<br>
- Follow GDScript style guide<br>

---

## 📄 License

This project is licensed under the MIT License.

---

<p align="center">Made with ❤️ for the Godot community</p>



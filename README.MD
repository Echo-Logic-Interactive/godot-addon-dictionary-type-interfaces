# Type Interfaces for Godot 4.x

> **Runtime type validation and structured data objects for GDScript with full modding support**

![Godot](https://img.shields.io/badge/Godot-4.x-478cbf?logo=godot-engine&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue)
![Status](https://img.shields.io/badge/Status-Testing_Phase-yellow)
![Modding](https://img.shields.io/badge/Modding-Friendly-ff69b4)

I recently started the journey of making a game. I am an experienced web application engineer in the Typespace
and Javascript world. I love Godot so far and the general transition has been super easy but the one thing
that kept bugging me was the lack of object interfaces, or dictionary interfaces to use the Godot nomenclature.

So what started as bit of a dig around for existing solutions turned into a side-project really quickly.

Introducing Godot Dictionary Interfaces, a lightweight addon that brings **TypeScript-style interfaces** to Godot projects with **built-in modding support**. Define typed data schemas, validate at runtime, and allow third-party mods to extend your data structures safely.

**Perfect for:** Save systems, inventory data, player stats, quest tracking, or any structured data that needs validation and mod extensibility.

---

## 📢 Project Status

> **Testing Phase** - This addon is almost production-ready and actively maintained. We're testing actual implementation and resolving last minute bugs. Be careful implementing this into existing projects just yet.

---

## ✨ Features

- 🎯 **Runtime type validation** - Catch data structure errors during development
- ✨ **Full IDE autocomplete** - Typed properties give you IntelliSense
- 🔌 **Mod-friendly architecture** - Namespace isolation and schema extension for third-party content
- 🚀 **Zero runtime overhead** - Validation removed in release builds via `assert()`
- 📦 **Nested interfaces** - Support for complex data structures with validated sub-objects
- 🛡️ **STRICT/LOOSE modes** - Choose validation strictness per instance
- 🔄 **Seamless serialization** - Easy dictionary conversion for save/load
- 📝 **Self-documenting** - Schema exports to JSON/TypeScript for documentation

---

## 📋 Table of Contents

- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Core Concepts](#-core-concepts)
- [Usage Guide](#-usage-guide)
- [API Reference](#-api-reference)
- [Modding Support](#-modding-support)
- [Performance](#-performance)
- [Contributing](#-contributing)

---

## 🚀 Installation

### Method 1: AssetLib (Recommended)

1. Open Godot Editor
2. Go to **AssetLib** tab
3. Search for "Type Interfaces"
4. Click **Download** → **Install**
5. Enable in **Project Settings → Plugins**

### Method 2: Manual Installation

1. Download or clone this repository

   `git clone git@github.com:Echo-Logic-Interactive/godot-addon-dictionary-type-interfaces.git`

2. Copy `addons/type_interfaces/` into your project's `addons/` directory
3. Enable the plugin in **Project Settings → Plugins → Type Interfaces**
4. The `TypeInterfaces` singleton will be available automatically

---

## ⚡ Quick Start

### Step 1: Define Your Interface

```gdscript
# scripts/interfaces/IPlayerData.gd
class_name IPlayerData
extends ExtendableInterface

## Player character data - mod-friendly by default

# Typed property accessors for IDE support
var name: String:
    get: return get_value("name", "")
    set(value): set_value("name", value)

var level: int:
    get: return get_value("level", 1)
    set(value): set_value("level", value)

var health: float:
    get: return get_value("health", 100.0)
    set(value): set_value("health", value)

# Define the schema (what fields are valid and their types)
func _get_base_schema() -> Dictionary:
    return {
        "name": "String",
        "level": "int",
        "health": "float",
        "max_health": "float",
        "position": "Vector2"
    }
```

### Step 2: Use Your Interface

```gdscript
# Create and validate player data
var player = IPlayerData.new({
    "name": "Hero",
    "level": 5,
    "health": 80.0,
    "max_health": 100.0,
    "position": Vector2(100, 200)
})

# Type-safe property access with autocomplete
player.name = "New Hero"
player.level = 6

# Save to dictionary (includes all data + mod data)
var save_dict = player.to_dict()
var json = JSON.stringify(save_dict)

# Load from dictionary
var loaded_player = IPlayerData.new(JSON.parse_string(json))
```

### Step 3: Enable Modding (Optional)

```gdscript
# Mods can safely add custom data
player.set_mod_data("com.coolmod.rpg", "stamina", 100.0)
player.set_mod_data("com.coolmod.rpg", "mana", 50.0)

# Or extend the schema for validated fields
player.extend_schema({
    "stamina": "float",
    "mana": "float"
})
player.set_value("stamina", 100.0)  # Now type-validated!

# Retrieve mod data
var stamina = player.get_mod_data("com.coolmod.rpg", "stamina", 100.0)
```

---

## 🔧 Core Concepts

### TypedDict vs ExtendableInterface

**TypedDict** - Base class for strict, non-moddable data:

```gdscript
class_name SaveData extends TypedDict

func _get_schema() -> Dictionary:
    return {"name": "String", "level": "int"}
```

**ExtendableInterface** - Extends TypedDict with mod support:

```gdscript
class_name IPlayerData extends ExtendableInterface

func _get_base_schema() -> Dictionary:  # Note: _get_base_schema, not _get_schema
    return {"name": "String", "level": "int"}
```

| Feature              | TypedDict             | ExtendableInterface           |
| -------------------- | --------------------- | ----------------------------- |
| Type validation      | ✅                    | ✅                            |
| Property accessors   | ✅                    | ✅                            |
| Mod data namespacing | ❌                    | ✅                            |
| Schema extension     | ❌                    | ✅                            |
| Default validation   | STRICT                | LOOSE                         |
| Use case             | Save files, core data | Player data, moddable systems |

### Validation Modes

```gdscript
# STRICT - No extra fields allowed (default for TypedDict)
var save = SaveData.new(data, TypeInterfaces.ValidationMode.STRICT)

# LOOSE - Allows extra fields (default for ExtendableInterface)
var player = IPlayerData.new(data, TypeInterfaces.ValidationMode.LOOSE)
```

### Supported Type Syntax

| Type String         | Description         | Example                          |
| ------------------- | ------------------- | -------------------------------- |
| `"String"`          | Basic type          | `"name": "String"`               |
| `"int?"`            | Nullable type       | `"age": "int?"`                  |
| `"Array<String>"`   | Generic array       | `"tags": "Array<String>"`        |
| `"ICustomStats"`    | Nested interface    | `"stats": "ICustomStats"`        |
| `"Array<IAbility>"` | Array of interfaces | `"abilities": "Array<IAbility>"` |
| `"Dictionary"`      | Unvalidated dict    | `"metadata": "Dictionary"`       |

### Nested Interfaces

Create complex validated structures:

```gdscript
# Define a nested interface
class_name ICustomStats extends ExtendableInterface

func _get_base_schema() -> Dictionary:
    return {
        "strength": "float",
        "intelligence": "float",
        "dexterity": "float"
    }

# Use it in parent interface
var player = IPlayerData.new()
player.extend_schema({
    "custom_stats": "ICustomStats"  # Nested interface
})

# Auto-converts Dictionary to ICustomStats
player.set_value("custom_stats", {
    "strength": 10.0,
    "intelligence": 15.0,
    "dexterity": 12.0
})

# Access typed nested interface
var stats = player.get_value("custom_stats") as ICustomStats
print(stats.strength)  # 10.0
```

---

## 📚 Usage Guide

### Creating an Interface

```gdscript
class_name IItem
extends ExtendableInterface

var id: String:
    get: return get_value("id", "")
    set(value): set_value("id", value)

var name: String:
    get: return get_value("name", "")
    set(value): set_value("name", value)

var quantity: int:
    get: return get_value("quantity", 1)
    set(value): set_value("quantity", value)

func _get_base_schema() -> Dictionary:
    return {
        "id": "String",
        "name": "String",
        "quantity": "int",
        "weight": "float?",  # Optional field
        "tags": "Array<String>"
    }
```

### Working with Data

```gdscript
# Create from dictionary
var item = IItem.new({
    "id": "sword_01",
    "name": "Iron Sword",
    "quantity": 1,
    "tags": ["weapon", "melee"]
})

# Access via properties (with autocomplete)
print(item.name)  # "Iron Sword"
item.quantity += 1

# Access via methods
var id = item.get_value("id")
item.set_value("weight", 5.0)

# Batch update
item.update({
    "quantity": 5,
    "weight": 4.5
})

# Serialize
var dict = item.to_dict()
FileAccess.open("save.json", FileAccess.WRITE).store_string(JSON.stringify(dict))

# Deserialize
var loaded_dict = JSON.parse_string(FileAccess.open("save.json", FileAccess.READ).get_as_text())
var loaded_item = IItem.new(loaded_dict)
```

### Schema Extension for Mods

```gdscript
# Mod extends player data with new validated fields
var player = IPlayerData.new()
player.extend_schema({
    "stamina": "float",
    "mana": "float",
    "custom_stats": "ICustomStats",  # Nested interface
    "abilities": "Array<IAbility>"   # Array of interfaces
})

# Set validated fields
player.set_value("stamina", 100.0)  # ✅ Type-checked
# player.set_value("stamina", "text")  # ❌ Fails validation in debug

# Nested interface auto-conversion
player.set_value("custom_stats", {
    "strength": 10.0,
    "intelligence": 15.0
})
# Dictionary automatically converts to ICustomStats instance
```

### Mod Data Namespacing

```gdscript
# Different mods can safely store data without conflicts
player.set_mod_data("com.modA.rpg", "custom_stat", 42)
player.set_mod_data("com.modB.magic", "custom_stat", 100)  # No conflict!

# Retrieve mod-specific data
var modA_stat = player.get_mod_data("com.modA.rpg", "custom_stat", 0)
var modB_stat = player.get_mod_data("com.modB.magic", "custom_stat", 0)

# Check what mods have added data
var registered_mods = player.get_registered_mods()
for mod_id in registered_mods:
    print("Mod: %s, Data: %s" % [mod_id, player.get_all_mod_data(mod_id)])

# Clear a mod's data
player.clear_mod_data("com.modA.rpg")
```

---

## 📖 API Reference

### ExtendableInterface

Extends `TypedDict` with modding support. Use this for any data that mods might extend.

#### Core Methods

**`new(data: Dictionary = {}, validation_mode = ValidationMode.LOOSE)`**

- Create a new instance with optional initial data
- Default validation mode is LOOSE (allows extra fields)

**`get_value(key: String, default = null) -> Variant`**

- Get a field value safely with fallback

**`set_value(key: String, value: Variant) -> void`**

- Set a field value with validation
- Auto-converts Dictionaries to nested interfaces

**`to_dict() -> Dictionary`**

- Convert to dictionary (includes mod data)
- Use for serialization

**`update(data: Dictionary) -> void`**

- Batch update multiple fields

#### Schema Methods

**`_get_base_schema() -> Dictionary`** _(override this)_

- Define core interface fields
- Returns `{"field_name": "Type"}` dictionary

**`extend_schema(additional_fields: Dictionary) -> void`**

- Add new validated fields at runtime
- Useful for mods adding typed fields

#### Mod Support Methods

**`set_mod_data(mod_id: String, key: String, value: Variant) -> void`**

- Store mod-specific data in isolated namespace
- Example: `set_mod_data("com.mymod", "stamina", 100.0)`

**`get_mod_data(mod_id: String, key: String, default = null) -> Variant`**

- Retrieve mod-specific data
- Returns default if not found

**`has_mod_data(mod_id: String) -> bool`**

- Check if a mod has stored any data

**`get_all_mod_data(mod_id: String) -> Dictionary`**

- Get all data for a specific mod

**`clear_mod_data(mod_id: String) -> void`**

- Remove all data for a mod

**`get_registered_mods() -> Array[String]`**

- Get list of all mod IDs that have stored data

### TypedDict

Base class for non-moddable data. Use for save files or core data that shouldn't be modified.

**`new(data: Dictionary = {}, validation_mode = ValidationMode.STRICT)`**

- Create instance with STRICT validation by default

**`_get_schema() -> Dictionary`** _(override this)_

- Define interface schema
- Note: Use `_get_base_schema()` for ExtendableInterface

All other methods same as ExtendableInterface (get_value, set_value, to_dict, update).

### TypeInterfaces Singleton

Provides manual validation utilities.

**`validate(data: Dictionary, schema: Dictionary, strict: bool = false) -> bool`**

- Manually validate a dictionary against a schema
- Used internally by TypedDict/ExtendableInterface

**ValidationMode Enum:**

```gdscript
enum ValidationMode {
    STRICT,  # No extra fields allowed
    LOOSE    # Allows additional fields
}
```

---

## 🎮 Modding Support

### For Game Developers

Enable modding by using `ExtendableInterface` for player-facing data:

```gdscript
# Use ExtendableInterface for moddable systems
class_name IPlayerData extends ExtendableInterface
# NOT: extends TypedDict

# Provide schema export for mod documentation
# In your game's debug menu or editor tool:
SchemaExporter.export_all_schemas("res://mod_docs/schemas.json")
SchemaExporter.export_typescript_definitions("res://mod_docs/schemas.d.ts")
```

### For Mod Developers

Two approaches to extending game data:

**Option 1: Mod Data Namespace (Recommended)**

```gdscript
# Safe - won't conflict with other mods
player.set_mod_data("com.yourname.modname", "custom_field", value)
```

**Option 2: Schema Extension (Advanced)**

```gdscript
# Adds validated fields - be careful of conflicts!
player.extend_schema({
    "your_custom_field": "Type"
})
player.set_value("your_custom_field", value)
```

**Dictionary vs Interface Types:**

When extending schemas, prefer interface types over Dictionary:

```gdscript
# ❌ Less recommended - no validation
player.extend_schema({"custom_data": "Dictionary"})

# ✅ Better - validated, extensible, autocomplete-friendly
player.extend_schema({"custom_stats": "ICustomStats"})
```

See [Example Game Interfaces](?tab=readme-ov-file#examples) for reference implementations.

---

## 🎯 Performance

### Zero Cost in Production

Validation uses `assert()` which **Godot automatically removes in release builds**:

```gdscript
# Development build:
var player = IPlayerData.new(data)
# Internally runs: assert(TypeInterfaces.validate(data, schema))
# ✅ Validates, catches errors during development

# Release build (exported game):
var player = IPlayerData.new(data)
# assert() is stripped out by Godot
# ✅ No validation overhead - just direct dictionary assignment!
```

**Benchmarks:**

- **Development:** ~0.1ms validation overhead per instance creation
- **Release:** 0ms overhead (assertions stripped)
- **Memory:** Same as raw Dictionary + small class overhead
- **Serialization:** Negligible - just returns internal dictionary

**Best Practices:**

- Use validation during development/testing
- Ship with validation removed automatically
- No need to disable the addon for release builds

---

## 🤝 Contributing

We welcome contributions! Here are some areas we'd love help with:

**Core Features:**

- Additional type checking functionality (Generics etc)
- Visual schema editor

**Modding Support:**

- Mod dependency resolution
- Conflict detection between mods
- Hot-reload for mod development
- Mod template generator

**Documentation:**

- More example interfaces
- Video tutorials
- Translation to other languages

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

MIT License - See LICENSE file for details

Use freely in commercial and non-commercial projects.
No attribution required (but appreciated!).

---

## 🙏 Acknowledgments

- Inspired by TypeScript interfaces and the need for better data validation in Godot
- Built for the Godot game dev & modding community
- Elements of this addon have been created with the help of AI tooling
  - Github Co-pilot running Claude Sonnet 4.5
  - Chat GPT 5.1 and 5.2
- Thanks to all contributors and users

---

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/type-interfaces/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/type-interfaces/discussions)

Made with ❤️ for the Godot community

# Dictionary-Type Interface Plugin for Godot 4.x

A lightweight, metadata-based interface system for GDScript that provides duck-typing validation without inheritance.

![Godot](https://img.shields.io/badge/Godot-4.x-478cbf?logo=godot-engine&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue)
![Status](https://img.shields.io/badge/Status-Released_1.0.0-brightgreen)
![Modding](https://img.shields.io/badge/Modding-Friendly-ff69b4)

## Features

- ✅ Zero boilerplate interface implementation
- ✅ Runtime interface validation
- ✅ Clear error messaging
- ✅ No performance overhead when not validating
- ✅ Works with any GDScript object

## Installation

1. Copy `addons/godot-addon-dictionary-type-interfaces/` to your project
2. Enable in Project Settings → Plugins

## Quick Start

### Define an Interface

```gdscript
# In addons/interface_plugin/Interface.gd
const IChunkProvider = {
    "required_methods": ["get_tile_data"]
}
```

### Implement an Interface

```gdscript
class_name MyChunkProvider extends Node2D

@export var _implements: Array[String] = ["IChunkProvider"]

func get_tile_data(x: int, y: int) -> Dictionary:
    return {"type": "grass"}
```

### Validate Interface Compliance

```gdscript
func set_chunk_provider(provider: Node) -> void:
    if not Interfaces.validate_interface(provider, "IChunkProvider"):
        push_error("Provider doesn't implement IChunkProvider")
        return
    chunk_provider = provider
```

## API Reference

### `Interfaces.validate_interface(obj: Object, interface_name: String) -> bool`

Validates that an object implements all required methods for an interface.

### `Interfaces.get_required_methods(interface_name: String) -> Array`

Returns list of method names required by an interface.

## License

MIT License - See LICENSE file

## Contributing

Issues and pull requests welcome!

# Copilot Instructions for Shop_WeaponColors

## Project Overview

This repository contains **Shop_WeaponColors**, a SourcePawn plugin for SourceMod that allows players to purchase colored weapon skins through an integrated shop system. The plugin integrates with the Shop-Core framework to provide purchasable weapon color modifications for Source engine games.

### Key Features
- Integration with Shop-Core system for item purchasing
- Real-time weapon color application using SourceMod SDK hooks
- Configuration-driven color definitions
- Temporary and permanent item support
- Automatic color reset on weapon drop

## Architecture & Dependencies

### Core Dependencies
- **SourceMod 1.11.0+** - Primary scripting platform
- **Shop-Core** - Shop framework integration (from srcdslab/sm-plugin-Shop-Core)
- **MultiColors** - Color utilities (from srcdslab/sm-plugin-MultiColors)

### Project Structure
```
addons/sourcemod/
├── scripting/
│   └── Shop_WeaponColors.sp    # Main plugin source
└── configs/
    └── weapon_colors.txt       # Color definitions and pricing
```

### Build System
- **SourceKnight** - Primary build tool (configured in `sourceknight.yaml`)
- **GitHub Actions** - CI/CD pipeline for automated building and releases
- **Output**: Compiled `.smx` files in `/addons/sourcemod/plugins/`

## Code Standards & Conventions

### SourcePawn Specific Guidelines
```cpp
#pragma semicolon 1
#pragma newdecls required
```

### Variable Naming
- **Global variables**: Prefix with `g_` (e.g., `g_bHasColor`, `g_iClientColor`)
- **Functions**: PascalCase (e.g., `OnEquipItem`, `WeaponColors_WeaponCanUse`)
- **Local variables**: camelCase (e.g., `iClient`, `weaponIndex`)

### Memory Management Rules
```cpp
// ❌ Legacy (avoid)
Handle g_hKv = INVALID_HANDLE;
CloseHandle(g_hKv);

// ✅ Modern approach
Handle g_hKv = null;
delete g_hKv;  // No null check needed
g_hKv = null;  // Set to null after delete
```

### Key Code Patterns

#### Plugin Lifecycle
```cpp
public void OnPluginStart()    // Initialization & Shop integration
public void OnMapStart()       // Config file loading
public void OnPluginEnd()      // Cleanup & unregistration
```

#### Shop Integration Pattern
```cpp
public void Shop_Started()     // Register categories and items
public ShopAction OnEquipItem() // Handle item equip/unequip
```

#### SDK Hooks Usage
```cpp
SDKHook(iClient, SDKHook_WeaponCanUsePost, WeaponColors_WeaponCanUse);
```

## Common Development Tasks

### Adding New Weapon Colors
1. Edit `addons/sourcemod/configs/weapon_colors.txt`
2. Add new color entry with RGBA values:
```
"new_color_name"
{
    "name"       "Display Name"
    "color"      "R G B A"  // 0-255 values
    "price"      "250"
    "sellprice"  "50"
    "duration"   "0"        // 0 = permanent
}
```

### Modifying Color Application Logic
- Core logic in `WeaponColors_WeaponCanUse()` function
- Color storage in `g_iClientColor[MAXPLAYERS+1][4]` array
- Apply colors using `SetEntityRenderMode()` and `SetEntityRenderColor()`

### Testing Plugin Changes
```bash
# Build using SourceKnight
sourceknight build

# Check output in .sourceknight/package/
# Deploy .smx files to test server
```

## Build & Development Workflow

### Local Development Setup
1. **Install SourceKnight** - Build tool for SourceMod plugins
2. **Dependencies are auto-fetched** via `sourceknight.yaml` configuration
3. **Build command**: `sourceknight build`

### CI/CD Pipeline
- **Trigger**: Push, PR, or manual dispatch
- **Build**: Automated via `maxime1907/action-sourceknight@v1`
- **Package**: Includes configs and compiled plugins
- **Release**: Auto-tags and releases on main/master branch

### Testing Checklist
- [ ] Plugin compiles without errors
- [ ] Shop integration works (items appear in shop)
- [ ] Color application works on weapon pickup
- [ ] Color removal works on weapon drop
- [ ] Configuration file parsing succeeds
- [ ] No memory leaks (check Handle usage)

## Configuration Management

### Weapon Colors Configuration (`weapon_colors.txt`)
- **Format**: KeyValues structure
- **Location**: `addons/sourcemod/configs/`
- **Validation**: Parsed in `OnMapStart()` with error checking
- **RGBA Values**: 0-255 range for each color component

### Shop Integration Settings
- **Category**: `Weapon_Colors` (registered in Shop-Core)
- **Item Type**: `Item_Togglable` (can be equipped/unequipped)
- **Duration Support**: Configurable per-item (0 = permanent)

## Troubleshooting Guide

### Common Issues

**Plugin fails to load:**
- Check SourceMod version compatibility (1.11.0+)
- Verify Shop-Core dependency is loaded
- Check console for compilation errors

**Colors not applying:**
- Verify SDK hooks are properly registered
- Check `g_bHasColor[iClient]` state
- Ensure weapon entity is valid

**Configuration errors:**
- Validate `weapon_colors.txt` syntax
- Check file path in `Shop_GetCfgFile()` call
- Verify KeyValues structure

**Build failures:**
- Check `sourceknight.yaml` dependencies
- Ensure include files are accessible
- Verify SourceMod compiler version

### Debug Logging
```cpp
// Add debug prints for troubleshooting
LogMessage("Client %d equipped color: %d %d %d %d", 
    iClient, r, g, b, a);
```

## Code Quality Standards

### Performance Considerations
- Minimize operations in frequently called hooks (`WeaponCanUsePost`)
- Cache KeyValues lookups where possible
- Avoid unnecessary string operations in hot paths

### Error Handling
```cpp
// Always validate entity indices
if (!IsValidEntity(weaponIndex)) return;

// Check KeyValues operations
if (!KvJumpToKey(g_hKv, item, false)) {
    LogError("Failed to find item: %s", item);
    return Shop_Raw;
}
```

### Memory Safety
- Use `delete` instead of `CloseHandle()`
- Set handles to `null` after deletion
- No null checks needed before `delete` operation
- Avoid memory leaks with proper cleanup in `OnPluginEnd()`

## Integration Points

### Shop-Core Integration
- **Category Registration**: `Shop_RegisterCategory()`
- **Item Registration**: `Shop_StartItem()` → `Shop_SetInfo()` → `Shop_EndItem()`
- **Toggle Management**: `Shop_ToggleClientCategoryOff()`

### SourceMod SDK Integration
- **Entity Rendering**: `SetEntityRenderMode()`, `SetEntityRenderColor()`
- **Event Hooks**: `SDKHook_WeaponCanUsePost`, `CS_OnCSWeaponDrop`
- **Client Management**: `OnClientPostAdminCheck()`

This plugin serves as a good example of Shop-Core integration and SourceMod entity manipulation. When making changes, prioritize minimal modifications and maintain compatibility with the Shop-Core framework.
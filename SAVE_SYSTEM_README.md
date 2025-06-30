# Save/Load System Documentation

## Overview
The save/load system allows players to save their game progress at Crystal Points and load their saved game from the main menu. The system uses a separate signal mechanism to avoid conflicts with attack animations.

## Key Features

### Save System
- **Crystal Point Save**: Players can save their game when near a Crystal Point
- **Visual Feedback**: Attack button changes appearance to indicate save mode
- **Separate Signal System**: Uses `save_pressed` signal to avoid triggering attack animations
- **Cooldown System**: Prevents spam saving with 2-second cooldown
- **Comprehensive Data**: Saves player status, inventory, equipment, and game progress

### Load System
- **Main Menu Integration**: Load game option available in main menu
- **Save Data Validation**: Checks for valid save data before loading
- **Error Handling**: Graceful handling of missing or corrupted save files
- **Loading Screen**: Visual feedback during game loading

## Data Saved

### Player Data
- **Status**: HP, MP, TP, Level, Experience
- **Stats**: Attack, Defense, Speed, etc.
- **Position**: Current world position
- **Equipment**: Currently equipped items

### Support Character Data
- **Status**: HP, MP, TP, Level, Experience
- **Stats**: Attack, Defense, Speed, etc.
- **Position**: Current world position
- **Equipment**: Currently equipped items

### Game Progress
- **Current World**: Which world the player is in
- **Save Point**: Last crystal point location
- **Inventory**: All collected items
- **Equipment**: All owned equipment

### Metadata
- **Save Date**: When the game was saved
- **Playtime**: Total time played
- **Version**: Game version for compatibility

## File Structure

```
user://saves/
├── save_game.json          # Main save file
└── save_backup.json        # Backup save file
```

## Usage Instructions

### Saving Game
1. Approach a Crystal Point in the game world
2. The attack button will change appearance to a push button
3. Press the attack button (now in save mode) or press 'X' key
4. Game will save with visual confirmation
5. 2-second cooldown prevents spam saving

### Loading Game
1. Start the game and go to Main Menu
2. Click "Load Game" button
3. If save data exists, the game will load
4. Player and support will spawn at saved positions
5. All stats, inventory, and equipment will be restored

## Technical Implementation

### Signal System
The system uses a dual-signal approach to prevent conflicts:

- **`attack_pressed`**: Original signal for attack animations
- **`save_pressed`**: New signal specifically for save functionality
- **Mode Switching**: Button switches between attack and save modes

### Load Game Flow
The load game system uses a clean flag-based approach:

1. **MainMenu.gd**: 
   - Checks if save file exists
   - Sets `load_save_data = true` on LoadingScreen
   - Transitions to LoadingScreen

2. **LoadingScreen.gd**:
   - Stores `should_load_save` flag in tree metadata
   - Transitions to Game scene
   - **Note**: LoadingScreen is only for scene transitions, not for load game logic

3. **Game.gd**:
   - Reads `should_load_save` flag from tree metadata
   - Calls `load_game_from_save()` if flag is true
   - Otherwise starts new game with default world

### AttackController.gd
```gdscript
signal attack_pressed      # For attack animations
signal save_pressed        # For save functionality
var is_save_mode: bool     # Controls which signal to emit

func set_save_mode(enabled: bool):
    is_save_mode = enabled
```

### CrystalPoint.gd
- Detects player proximity
- Changes button appearance and mode
- Connects to appropriate signal based on mode
- Handles save cooldown and feedback

### SaveSystem.gd
- JSON-based save/load system
- Comprehensive data serialization
- Error handling and validation
- Backup system for data safety
- **Debug logging** for troubleshooting save/load issues

### World and Position Loading
The system properly handles world and position loading:

1. **Save Process**:
   - Saves current world name from WorldManager
   - Saves exact player and support positions
   - Includes debug logging for verification

2. **Load Process**:
   - Loads the correct world first
   - Spawns player and support at saved positions
   - Applies all saved stats and equipment
   - Includes debug logging for troubleshooting

3. **Position Handling**:
   - Positions are set during character spawning
   - No conflicts between spawn and apply functions
   - Fallback to default spawn points if save data is missing

## Integration Points

### Main Game (Game.gd)
- Handles save/load requests
- Spawns player and support with saved data
- Applies saved stats and equipment
- Manages world transitions

### World Manager (WorldManager.gd)
- Tracks current world
- Handles world-specific save data
- Manages player/support positioning

### UI Components
- **MainMenu.gd**: Load game button and logic
- **LoadingScreen.gd**: Visual feedback during loading
- **AttackController.gd**: Dual-mode button system

## Error Handling

### Save Errors
- File write failures
- Invalid data serialization
- Disk space issues
- Permission problems

### Load Errors
- Missing save file
- Corrupted save data
- Version incompatibility
- Invalid data structure

### Recovery
- Automatic backup system
- Graceful fallback to new game
- User-friendly error messages
- Logging for debugging

## Future Enhancements

### Planned Features
- Multiple save slots
- Auto-save functionality
- Save data encryption
- Cloud save support
- Save data compression

### Potential Improvements
- Save data validation
- Incremental saves
- Save data migration
- Cross-platform compatibility

## Testing

### Test Cases
1. **Basic Save/Load**: Save game and load immediately
2. **Cross-World Save**: Save in different worlds
3. **Equipment Save**: Save with different equipment
4. **Inventory Save**: Save with various inventory states
5. **Error Recovery**: Test with corrupted save files
6. **Button Mode Switching**: Test attack/save mode transitions

### Test Scenarios
- Save during combat
- Save with low HP/MP
- Save with full inventory
- Load with missing assets
- Multiple save/load cycles

## Performance Considerations

### Save Performance
- JSON serialization overhead
- File I/O operations
- Memory usage during save
- UI responsiveness during save

### Load Performance
- Data deserialization
- Asset loading
- World initialization
- Player/support spawning

### Optimization
- Asynchronous save operations
- Data compression
- Incremental saves
- Background processing

## Troubleshooting

### Common Issues
1. **Save not working**: Check file permissions and disk space
2. **Load fails**: Verify save file integrity
3. **Button not changing**: Check signal connections
4. **Animation conflicts**: Ensure proper signal separation
5. **Wrong world loaded**: Check current_world in save data
6. **Wrong position loaded**: Check player_position and support_position in save data
7. **Load game not working**: Check should_load_save flag flow
8. **New game starts instead of load**: Verify flag passing between scenes

### Debug Information
- Save file location: `user://saves/save_game.json`
- Log file: Check console for error messages
- Signal connections: Verify in debugger
- File permissions: Check system settings
- **Debug logging**: System now includes comprehensive debug output
- **Flag tracking**: Check console for should_load_save flag messages

### Debug Commands
The save system includes debug functions for troubleshooting:

```gdscript
# Print save file contents
save_system.debug_print_save_file()

# Check if save file exists
save_system.has_save_file()

# Get save info
save_system.get_save_info()

# Check should_load_save flag
print("should_load_save: ", should_load_save)

# Check tree metadata
print("Tree metadata should_load_save: ", get_tree().get_meta("should_load_save", false))
```

### Common Debug Output
When loading game from main menu:
```
Load game button pressed - save file exists
Setting global load save flag
Read should_load_save from tree metadata: true
Loading game from save data...
Loading world: world_3_final from path: res://scenes/world/World3/World3-final.tscn
World loaded successfully: world_3_final
Player spawned at saved position: (10.5, 0, 15.2)
Support spawned at saved position: (8.5, 0, 10.2)
```

When starting new game:
```
Load game button pressed - no save file
Read should_load_save from tree metadata: false
Starting new game...
Loading world: world_1 from path: res://scenes/world/World1/World1.tscn
World loaded successfully: world_1
Player spawned at default position: (0, 0, 0)
Support spawned at default position: (0, 0, -5)
```

## Security Considerations

### Data Protection
- Save file validation
- Input sanitization
- Error message security
- File access permissions

### Best Practices
- Validate all loaded data
- Sanitize user inputs
- Handle errors gracefully
- Log security events 
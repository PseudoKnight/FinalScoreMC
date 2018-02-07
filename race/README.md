## Race
Creates and manages races with support for boats, horses, and elytra. Also features checkpoints, laps, and respawns.

### Commands
#### Track Creation
Permission: *command.track*
/track set <track> <setting> <value(s)>
/track delete <track> [setting]

#### Races
/race <start|join|end> <track>

### Dependencies
#### Java
- WorldEdit plugin
- WorldGuard plugin
- SKCompat extension

#### Procedures
- _click_tell() creates a mojangson chat string with a clickable link (chat/auto_include.ms)
- _worldmsg() messages all players within the specified world
- _clear_peffects() clears all player potion effects
- _set_pactivity() sets the players current activity for the server
- _equip_kit() resets the player's inventory
- _get_effects() returns an array of effect names and aliases mapped to numerical ids

# Race

Creates and manages races with support for boats, horses, pigs, karts, and elytra. Also features configuring multiple tracks
with effects, checkpoints, laps, and respawns.

## Commands

### Track Management

Permission: *command.track*

- /track set \<track> \<setting> <value(s)>
- /track delete \<track> [setting] [index]
- /track info \<track>
- /track rename \<track> \<name>
- /track list

### Races

- /race start \<track>
- /race join \<track>
- /race end \<track> (forces the race to end)
- /race reload core (recompiles all core.library scripts)

## Dependencies

### Java

- WorldEdit plugin
- WorldGuard plugin
- SKCompat extension

### Procedures

- _add_activity() and _remove_activity() procedures to keep a list of all current activities on server
- _click_tell() creates a mojangson chat string with a clickable link (chat/auto_include.ms)
- _psession() gets the current session data of a player, including player's current activity
- _equip_kit() resets the player's inventory
- _acc_add() gives a coin award to winners

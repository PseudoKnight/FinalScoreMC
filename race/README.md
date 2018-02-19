## Race
Creates and manages races with support for boats, horses, pigs, and elytra. Also features configuring multiple tracks
with effects, checkpoints, laps, and respawns.

### Commands
#### Track Creation
Permission: *command.track*
- /track set \<track> \<setting> <value(s)>
- /track delete \<track> [setting] [index]
- /track info \<track>

#### Races
- /race start \<track>
- /race join \<track>
- /race end \<track> (forces the race to end)
- /race reload core (recompiles all core.library scripts)

### Dependencies
#### Java
- WorldEdit plugin
- WorldGuard plugin
- SKCompat extension

#### Procedures
- _click_tell() creates a mojangson chat string with a clickable link (chat/auto_include.ms)
- _worldmsg() messages all players within the specified world
- _set_pactivity() sets the players current activity for the server
- _equip_kit() resets the player's inventory
- _get_effects() returns an array of effect names and aliases mapped to numerical ids
- _acc_add() gives a coin award to winners

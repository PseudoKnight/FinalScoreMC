proc _pvp(@action, @id, @arg){
    switch(@action) {
        case 'join':
            include('../core.library/join.ms');
            _pvp_join(to_lower(@id));

        case 'debug':
            @id = to_lower(@id);
            @pvp = import('pvp'.@id);
            if(is_null(@pvp)) {
                die('That arena doesn\'t seem to be running.');
            }
            foreach(@key: @value in @pvp) {
                msg(@key.': '.color('gray').@value);
            }

        case 'vote':
            @id = to_lower(@id);
            @pvp = import('pvp'.@id);
            if(!@pvp) {
                die('Game is not queued.');
            }
            if(!array_index_exists(@pvp['players'], player())) {
                die('You haven\'t joined.');
            }
            @pvp['players'][player()]['arena'] = @arg;
            msg(color('a').'You voted for '.to_upper(@arg).'.');

        case 'spectate':
            if(_is_survival_world(pworld())) {
                die('You are not in Frog Park.');
            }
            @id = to_lower(@id);
            @pvp = import('pvp'.@id);
            if(!@pvp || !@pvp['running']) {
                die('Game is not running.');
            }
            if(array_index_exists(@pvp['players'], player())) {
                die('You\'re already in the game.');
            }
            if(!array_contains(get_scoreboards(), @id)) {
                die('The arena isn\'t running.');
            }
            include('../core.library/spectator.ms');
            set_pscoreboard(player(), @id);
            @pvp = import('pvp'.@id);
            if(array_index_exists(@pvp['arena'], 'resourcepack')) {
                send_resourcepack(player(), 'http://mc.finalscoremc.com:25966/resourcepacks/'.@pvp['arena']['resourcepack'].'.zip');
            }
            _set_spectator(player(), @pvp);

        case 'addtime':
            if(!get_command_block() && !has_permission('group.moderator')) {
                die();
            }
            @id = to_lower(@id);
            @pvp = import('pvp'.@id);
            if(!@pvp) {
                die();
            }
            @pvp['arena']['timer'][1] += @arg;
            if(extension_exists('CHNaughty')) {
                foreach(@p in array_merge(array_keys(@pvp['players']), @pvp['spectators'])) {
                    try {
                        title_msg(@p, 'Added '.@arg.' minutes', null, 20, 20, 20);
                    } catch(PlayerOfflineException @ex) {
                        // we'll remove them elsewhere
                    }
                }
            }

        case 'start':
            @id = to_lower(@id);
            @pvp = import('pvp'.@id);
            if(!@pvp) {
                die('There is no match to start.');
            }
            if(@pvp['running']) {
                die('Match already in progress.');
            }
            if(!array_index_exists(@pvp['players'], player())) {
                die('You have not joined.');
            }
            # Get arena settings
            @pvp['arena'] = get_value('arena', @id);
            if(is_null(@pvp['arena'])) {
                die('Can\'t find that arena.');
            }
            include('../core.library/start.ms');
            _pvp_start(@pvp, @id);

        case 'end':
            if(!get_command_block() && !has_permission('group.builder')) {
                die(color('red').'You do not have permission.');
            }
            @id = to_lower(@id);
            @pvp = import('pvp'.@id);
            if(!@pvp || @pvp['running'] < 2) {
                die(color('red').'Not running.');
            }
            include('../core.library/game.ms');
            if(is_numeric(@arg)) {
                _pvp_end_match(@id, @pvp['team'][@arg - 1]['players']);
            } else {
                _pvp_end_match(@id, array());
            }

        default:
            msg(color('bold').'PVP COMMANDS ----------------');
            msg('/pvp join <id> '.color('gray').'Join the match');
            msg('/pvp start <id> '.color('gray').'Start the match');
            msg('/pvp spectate <id> '.color('gray').'Displays the scoreboard');
            msg(color('bold').'RESTRICTED COMMANDS ---------');
            msg('/pvp end <id> <team> '.color('gray').'End in favor of team');
            msg('/pvp addtime <id> <minutes> '.color('gray').'Add time to the timer');
            msg('/pvp debug <id> '.color('gray').'Output debug information');
    }
}

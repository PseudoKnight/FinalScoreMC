proc _snake_bot_update(@bot, @game) {
    @snake = @game['snakes'][@bot];
    @percent = rand(100);
    if(@bot == 'Sleepy') {
        if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir']))) {
            @dir = _snake_direction_of(@snake['loc'], '0:0', @snake['dir']);
            if(@dir) {
                @snake['dir'] = @dir
            }
        } else if(@snake['target']) {
            // go to target
            @dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
            if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
                @snake['dir'] = @dir;
            } else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
                @snake['target'] = null;
            }
        } else if(@percent < 7) {
            // turn
            @dir = _snake_direction_of(@snake['loc'], '0:0', @snake['dir']);
            if(@dir) {
                @snake['dir'] = @dir;
            }
        } else if(@percent < 14) {
            // get powerup
            foreach(@powerup in @game['powerups']) {
                if(@powerup['region'] == @snake['region']) {
                    @snake['target'] = associative_array('type': 'powerup', 'loc': @powerup['loc']);
                    break();
                }
            }
        }
    } else if(@bot == 'Dopey') {
        if(@percent < 25 || !_snake_safe_block(_relative(@snake['loc'], @snake['dir']))) {
            @dir = _snake_direction_of(@snake['loc'], '0:0', @snake['dir']);
            if(@dir) {
                @snake['dir'] = @dir;
            }
        } else if(@snake['target']) {
            // go to target
            if(@snake['target']['type'] == 'powerup') {
                @dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
                if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
                    @snake['dir'] = @dir;
                } else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
                    @snake['target'] = null;
                }
            } else {
                if(!@game['snakes'][@snake['target']['name']]['alive']
                || @snake['region'] != @game['snakes'][@snake['target']['name']]['region']) {
                    @snake['target'] = null;
                } else {
                    @dir = _snake_farthest_dir(@snake['loc'], @game['snakes'][@snake['target']['name']]['loc']);
                    if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
                        @snake['dir'] = @dir;
                    }
                }
            }
        } else if(@percent < 30) {
            // get powerup
            foreach(@powerup in @game['powerups']) {
                if(@powerup['region'] == @snake['region']) {
                    @snake['target'] = associative_array('type': 'powerup', 'loc': @powerup['loc']);
                    break();
                }
            }
            if(!@snake['target']) {
                @othersnake = array_rand(@game['snakes'])[0];
                if(@othersnake != @bot
                && @game['snakes'][@othersnake]['alive']
                && @game['snakes'][@othersnake]['region'] == @snake['region']) {
                    @snake['target'] = associative_array('type': 'snake', 'name': @othersnake);
                }
            }
        }
    } else if(@bot == 'Grumpy') {
        if(!@snake['target']) {
            @othersnake = array_rand(@game['snakes'])[0];
            if(@othersnake != @bot
            && @game['snakes'][@othersnake]['alive']
            && @game['snakes'][@othersnake]['region'] == @snake['region']) {
                @snake['target'] = associative_array('type': 'snake', 'name': @othersnake);
            } else {
                // get powerup
                foreach(@powerup in @game['powerups']) {
                    if(@powerup['region'] == @snake['region']) {
                        @snake['target'] = associative_array('type': 'powerup', 'loc': @powerup['loc']);
                        break();
                    }
                }
            }
        }
        if(@snake['target']) {
            if(@snake['target']['type'] == 'snake') {
                if(!@game['snakes'][@snake['target']['name']]['alive']
                || @snake['region'] != @game['snakes'][@snake['target']['name']]['region']) {
                    @snake['target'] = null;
                } else {
                    @dir = _snake_farthest_dir(@snake['loc'], @game['snakes'][@snake['target']['name']]['loc']);
                    if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
                        @snake['dir'] = @dir;
                    }
                    return();
                }
            } else {
                // go to target
                @dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
                if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
                    @snake['dir'] = @dir;
                } else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
                    @snake['target'] = null;
                }
            }
        }
        if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir'])) || @percent < 10) {
            @dir = _snake_direction_of(@snake['loc'], '0:0', @snake['dir']);
            if(@dir) {
                @snake['dir'] = @dir;
            }
        }
    } else if(@bot == 'Bashful') {
        @othersnake = array_rand(@game['snakes'])[0];
        if(@othersnake != @bot
        && @game['snakes'][@othersnake]['alive']
        && @snake['region'] == @game['snakes'][@othersnake]['region']) {
            @dir = _snake_farthest_dir(@snake['loc'], @game['snakes'][@othersnake]['loc']);
            if(@dir && _snake_safe_block(_relative(@snake['loc'], _snake_opposite_dir(@dir)))) {
                @snake['dir'] = _snake_opposite_dir(@dir);
            }
            return();
        }
        if(@snake['target']) {
            // go to target
            @dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
            if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
                @snake['dir'] = @dir;
            } else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
                @snake['target'] = null;
            }
        } else {
            // get powerup
            foreach(@powerup in @game['powerups']) {
                if(@powerup['region'] == @snake['region']) {
                    @snake['target'] = associative_array('type': 'powerup', 'loc': @powerup['loc']);
                    break();
                }
            }
        }
        if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir'])) || @percent < 10) {
            @dir = _snake_direction_of(@snake['loc'], '0:0', @snake['dir']);
            if(@dir) {
                @snake['dir'] = @dir;
            }
        }
    }
}

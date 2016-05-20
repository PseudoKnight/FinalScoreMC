proc _snake_bot_update(@bot, @game) {
    @snake = @game['snakes'][@bot];
    @percent = rand(100);
    switch(@bot) {
    case 'Sleepy':
        if(@snake['target']) {
            // go to target
            @dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
            if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
                @snake['dir'] = @dir;
            } else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
                @snake['target'] = null;
            }
        } else if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir']))) {
            @dir = _snake_direction_of(@snake['loc'], '0:0', @snake['dir']);
            if(@dir) {
                @snake['dir'] = @dir
            }
        } else if(@percent < 7) {
            // turn
            @dir = _snake_direction_of(@snake['loc'], '0:0', @snake['dir']);
            if(@dir) {
                @snake['dir'] = @dir;
            }
        } else if(@percent < 14) {
            _snake_bot_target_powerup(@snake, @game);
        }
    case 'Dopey':
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
            _snake_bot_target_powerup(@snake, @game);
        } else if(@percent < 35) {
            _snake_ability(@bot, @game);
        }
    case 'Grumpy':
        if(!@snake['target']) {
            if(!_snake_bot_target_snake(@snake, @game)) {
                _snake_bot_target_powerup(@snake, @game);
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
                        return();
                    }
                }
            } else {
                // go to target
                @dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
                if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
                    @snake['dir'] = @dir;
                    return();
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
        } else if(@percent < 15) {
            _snake_ability(@bot, @game);
        }
    case 'Bashful':
        @othersnake = array_rand(@game['snakes'])[0];
        if(@othersnake != @bot
        && @game['snakes'][@othersnake]['alive']
        && @snake['region'] == @game['snakes'][@othersnake]['region']) {
            @dir = _snake_opposite_dir(_snake_farthest_dir(@snake['loc'], @game['snakes'][@othersnake]['loc']));
            if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
                @snake['dir'] = @dir;
                return();
            }
        }
        if(@snake['target']) {
            // go to target
            @dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
            if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
                @snake['dir'] = @dir;
                return();
            } else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
                @snake['target'] = null;
            }
        } else {
            _snake_bot_target_powerup(@snake, @game);
        }
        if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir'])) || @percent < 10) {
            @dir = _snake_direction_of(@snake['loc'], '0:0', @snake['dir']);
            if(@dir) {
                @snake['dir'] = @dir;
            }
        }
    case 'Happy':
        if(@snake['target']) {
            // go to target
            @dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
            if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
                @snake['dir'] = @dir;
            } else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
                @snake['target'] = null;
            }
        } else if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir']))) {
                @dir = _snake_direction_of(@snake['loc'], '0:0', @snake['dir']);
                if(@dir) {
                    @snake['dir'] = @dir
                }
        } else if(@percent < 20) {
            // turn
            @dir = _snake_direction_of(@snake['loc'], '0:0', @snake['dir']);
            if(@dir) {
                @snake['dir'] = @dir;
            }
        } else if(@percent < 50) {
            _snake_bot_target_powerup(@snake, @game, 'food');
        }

    case 'Sneezy':
        if(@snake['target']) {
            // go to target
            @dir = _snake_farthest_dir(@snake['loc'], @snake['target']['loc']);
            if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
                @snake['dir'] = @dir;
            } else if(split(':', get_block_at(@snake['target']['loc']))[0] == '159') {
                @snake['target'] = null;
            }
        } else if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir']))) {
            @dir = _snake_direction_of(@snake['loc'], '0:0', @snake['dir']);
            if(@dir) {
                @snake['dir'] = @dir
            }
        } else if(@percent < 15) {
            // turn
            @dir = _snake_direction_of(@snake['loc'], '0:0', @snake['dir']);
            if(@dir) {
                @snake['dir'] = @dir;
            }
        } else if(@snake['ability'] && @percent < 30) {
            _snake_ability(@bot, @game);
        } else if(@percent < 25) {
            _snake_bot_target_powerup(@snake, @game);
        }
    }
}

proc _snake_bot_target_powerup(@snake, @game, @type = 'all') {
    foreach(@powerup in @game['powerups']) {
        if((@type == 'all' || @powerup['type'] == @type) && @powerup['region'] == @snake['region']) {
            @snake['target'] = associative_array('type': 'powerup', 'loc': @powerup['loc']);
            return(true);
        }
    }
    return(false);
}

proc _snake_bot_target_snake(@snake, @game) {
    foreach(@bot: @othersnake in @game['snakes']) {
        if(@bot != @snake['bot'] && @othersnake['alive'] && @othersnake['region'] == @snake['region']) {
            @snake['target'] = associative_array('type': 'snake', 'name': @bot);
            return(true);
        }
    }
    return(false);
}

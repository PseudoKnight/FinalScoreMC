proc _snake_bot_update(@bot, @game) {
    @snake = @game['snakes'][@bot];
    if(@bot == 'Sleepy') {
        if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir']))) {
            _snake_turn(if(rand(2), 'right', 'left'), @snake);
        } else if(!rand(16)) {
            @dir = _snake_direction_of(@snake['loc'], '0:0');
            if(@dir) {
                @snake['dir'] = @dir;
            }
        }
    } else if(@bot == 'Dopey') {
        if(!rand(5)) {
            _snake_turn(if(rand(2), 'right', 'left'), @snake);
        } else if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir']))) {
            @dir = _snake_direction_of(@snake['loc'], '0:0');
            if(@dir) {
                @snake['dir'] = @dir;
            }
        }
    } else if(@bot == 'Grumpy') {
        @othersnake = array_rand(@game['snakes'])[0];
        if(@othersnake != @bot && @game['snakes'][@othersnake]['alive']) {
            @regions2 = sk_regions_at(@game['snakes'][@othersnake]['loc']);
            if(array_size(@regions2) == 2) {
                @regions1 = sk_regions_at(@snake['loc']);
                if(array_size(@regions1) == 2) {
                    if(@regions1[1] == @regions2[1];) {
                        @dir = _snake_farthest_dir(@snake['loc'], @game['snakes'][@othersnake]['loc']);
                        if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
                            @snake['dir'] = @dir;
                        }
                        return();
                    }
                }
            }
        }
        if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir'])) || !rand(10)) {
            @dir = _snake_direction_of(@snake['loc'], '0:0');
            if(@dir) {
                @snake['dir'] = @dir;
            }
        }
    } else if(@bot == 'Bashful') {
        @othersnake = array_rand(@game['snakes'])[0];
        if(@othersnake != @bot && @game['snakes'][@othersnake]['alive']) {
            @regions2 = sk_regions_at(@game['snakes'][@othersnake]['loc']);
            if(array_size(@regions2) == 2) {
                @regions1 = sk_regions_at(@snake['loc']);
                if(array_size(@regions1) == 2) {
                    if(@regions1[1] == @regions2[1]) {
                        @dir = _snake_farthest_dir(@snake['loc'], @game['snakes'][@othersnake]['loc']);
                        if(@dir && _snake_safe_block(_relative(@snake['loc'], @dir))) {
                            @snake['dir'] = _snake_opposite_dir(@dir);
                        } else {
                            _snake_turn(if(rand(2), 'right', 'left'), @snake);
                        }
                        return();
                    }
                }
            }
        }
        if(!_snake_safe_block(_relative(@snake['loc'], @snake['dir'])) || !rand(10)) {
            @dir = _snake_direction_of(@snake['loc'], '0:0');
            if(@dir) {
                @snake['dir'] = @dir;
            }
        }
    }
}

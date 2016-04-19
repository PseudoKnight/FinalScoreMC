proc _snake_get_powerup_from(@id) {
    switch(@id) {
        case 1:
        case 2:
        case 4:
        case 170:
            return('food');

        case 3:
            return('poop');

        case 5:
        case 46:
            return('tnt');

        case 6:
        case 7:
        case 133:
            return('faster');

        case 8:
        case 152:
            return('slower');
    }
    return(null);
}

proc _snake_get_block_from(@powerup) {
    switch(@powerup) {
        case 1:
        case 2:
        case 4:
        case 'food':
            return(170);

        case 3:
        case 'poop':
            return(3);

        case 5:
        case 'tnt':
            return(46);

        case 6:
        case 7:
        case 'faster':
            return(133);

        case 8:
        case 'slower':
            return(152);
    }
    return(null);
}

proc _snake_add_powerup(@game) {
    @region = 'snake_'.@game['arena'].rand(1, @game['surfaces'] + 1);
    @loc = _snake_valid_location(@region);
    if(@loc) {
        @r = rand(8) + 1;
        @block = _snake_block(_snake_get_block_from(@r), @loc);
        @type = _snake_get_powerup_from(@r);
        if((@type == 'faster' && @game['speed'] == 'impossible')
        || (@type == 'slower' && @game['speed'] == 'slow')) {
            return();
        }
        set_block_at(@loc, @block, false);
        @game['powerups'][] = associative_array(
            'block': @block,
            'loc': @loc,
            'type': @type,
        );
    }
}

proc _snake_remove_powerup(@loc, @game) {
    foreach(@i: @pu in @game['powerups']) {
        if(@pu['loc'][0] == @loc[0] && @pu['loc'][1] == @loc[1] && @pu['loc'][2] == @loc[2]) {
            array_remove(@game['powerups'], @i);
            break();
        }
    }
}

proc _snake_remove_all_powerups(@game) {
    foreach(@pu in @game['powerups']) {
        set_block_at(@pu['loc'], '0:0', false);
    }
    @game['powerups'] = array();
}

proc _snake_powerup(@player, @powerup, @game) {
    @snake = @game['snakes'][@player];
    switch(@powerup) {
        case 'food':
            play_sound(@snake['loc'], associative_array('sound': 'EAT', 'volume': 2));
            @snake['length'] = ceil(@snake['length'] * 2);
            return(true);

        case 'faster':
            if(_snake_change_speed(1, @game)) {
                play_sound(@snake['loc'], associative_array('sound': 'SUCCESSFUL_HIT', 'volume': 3));
            }
            return(true);

        case 'slower':
            if(_snake_change_speed(-1, @game)) {
                play_sound(@snake['loc'], associative_array('sound': 'SUCCESSFUL_HIT', 'pitch': 0.5, 'volume': 3));
            }
            return(true);

        default:
            if(@powerup && !@game['snakes'][@player]['bot']) {
                @snake['ability'] = @powerup;
                play_sound(@snake['loc'], associative_array('sound': 'ENDERMAN_TELEPORT', 'pitch': 2, 'volume': 2));
                set_pinv(@player, associative_array(1: associative_array('type': _snake_get_block_from(@powerup))));
                return(true);
            }
    }
    return(false);
}

proc _snake_ability(@player, @game) {
    @snake = @game['snakes'][@player];
    switch(@snake['ability']) {
        case 'tnt':
            @item = pinv(@player, 1);
            if(@item) {
                set_pinv(@player, associative_array(1: null));
                spawn_entity('PRIMED_TNT', 1, array(
                    @snake['loc'][0] + 0.5, @snake['loc'][1] + 0.5, @snake['loc'][2] + 0.5, @snake['loc'][3]
                ));
                set_timeout(4000, closure(){
                    if(@snake['ability'] == 'tnt') {
                        set_pinv(@player, associative_array(1: associative_array('name': 'TNT')));
                    }
                });
            }

        case 'poop':
            if(@snake['length'] == 1) {
                _snake_kill(@player, @game);
                return();
            }
            set_block_at(@snake['blocks'][0], 88, false);
            @game['extraBlocks'][] = @snake['blocks'][0];
            array_remove(@snake['blocks'], 0);
            @snake['length'] -= 1;
            play_sound(@snake['loc'], associative_array('sound': 'CHICKEN_EGG_POP', 'volume': 2, 'pitch': 0.7));

    }
}

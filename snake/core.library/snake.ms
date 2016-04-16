/*
    Snake data

    'loc': current location
    'dir': current direction
    'top': relative direction for clockwise rotation (eg. north)
    'length': the number of blocks this snake maxes out at
    'head': the block type:data for the color of their block
    'tail': the block type:data for the color of their tail
    'blocks': an array of ordered block locations representing the tail, new ones pushed on end, such that
              order is back of tail to head. This is used for removing blocks.
    'ability': a powerup ability
    'alive': whether the snake is active or dead
    'click': set to true if an action is performed, set to false on update
*/

proc _snake_add(@player, @game) {
    @colors = array(
        array('159:11', '159:3'), # blue
        array('159:1', '159:4'), # orange
        array('159:13', '159:5'), # green
        array('159:14', '159:6'), # red
        array('159:8', '159:0'), # white
        array('159:10', '159:2'), # purple
        array('159:15', '159:7'), # black
    );
    @region = 'snake_'.@game['arena'].rand(1, @game['surfaces'] + 1);
    @startLoc = _snake_valid_location(@region);
    if(!@startLoc) {
        return();
    }
    @dir = _snake_direction_of(@startLoc, '0:0');
    @headLoc = _relative(@startLoc, @dir);
    @head = @colors[array_size(@game['snakes'])][0];
    @tail = @colors[array_size(@game['snakes'])][1];
    @game['snakes'][@player] = associative_array(
        'blocks': array(@startLoc, @headLoc),
        'ability': '',
        'head': @head,
        'tail': @tail,
        'length': @game['startingLength'],
        'alive': true,
        'loc': @headLoc,
        'dir': @dir,
        'click': false,
    );
    set_pflight(@player, true);
    set_peffect(@player, 14, 0, 9999, true, false);
    set_pinv(@player, associative_array(
        0: associative_array(
            'name': 'STICK',
            'meta': associative_array('display': 'JOYSTICK'),
        ),
        103: associative_array(
            'name': 'SKULL_ITEM',
            'data': 3,
            'meta': associative_array('owner': @player),
    )));
    set_block_at(@headLoc, @head, false);
    set_block_at(@startLoc, @tail, false);
    _snake_set_top(@game['snakes'][@player]);
    set_ploc(@player, _relative(@headLoc, @game['snakes'][@player]['top'], 20));
    @yaw = get_yaw(ploc(@player), @headLoc);
    @pitch = get_pitch(ploc(@player), @headLoc);
    pfacing(@player, @yaw, @pitch);
    set_pflying(@player, true);
}

proc _snake_remove(@player, @game) {
    foreach(@block in @game['snakes'][@player]['blocks']) {
        set_block_at(@block, 0, false);
    }
    array_remove(@game['snakes'], @player);
    if(ponline(@player) && pworld(@player) == 'custom') {
        set_pflight(@player, false);
        set_peffect(@player, 14, 0, 0);
        set_pinv(@player, array(0: null, 1: null, 103: null));
    }
}

proc _snake_kill(@player, @game) {
    @snake = @game['snakes'][@player];
    if(@game['removeTail']) {
        foreach(@block in @snake['blocks']) {
            set_block_at(@block, 0, false);
        }
    } else {
        foreach(@block in @snake['blocks']) {
            set_block_at(@block, @snake['head'], false);
        }
    }
    @snake['alive'] = false;
    play_sound(@snake['loc'], associative_array('sound': 'ZOMBIE_DEATH', 'pitch': 2, 'volume': 2));
}

proc _snake_set_top(@snake) {
    @snake['top'] = _snake_direction_of(@snake['loc'], '166:0');
}

proc _snake_update(@player, @game) {
    @snake = @game['snakes'][@player];
    set_block_at(@snake['loc'], @snake['tail'], false);
    @snake['loc'] = _relative(@snake['loc'], @snake['dir']);
    @block = get_block_at(@snake['loc']);
    @powerup = _snake_get_powerup_from(split(':', @block)[0]);
    if(@block == '0:0' || @powerup) {
        @snake['blocks'][] = @snake['loc'][];
        set_block_at(@snake['loc'], @snake['head'], false);
        if(array_size(@snake['blocks']) > @snake['length']) {
            set_block_at(@snake['blocks'][0], 0, false);
            array_remove(@snake['blocks'], 0);
        }
        @snake['click'] = false;
        if(_snake_powerup(@player, @powerup, @game)) {
            _snake_remove_powerup(@snake['loc'], @game);
        }
        return(true);
    } else if(@block == '169:0') {
        @dir = _snake_direction_of(@snake['loc'], '0:0');
        if(!@dir) {
            return(false);
        }
        @snake['loc'] = _relative(@snake['loc'], @dir);
        @snake['dir'] = @dir;
        @snake['blocks'][] = @snake['loc'][];
        set_block_at(@snake['loc'], @snake['head'], false);
        if(array_size(@snake['blocks']) > @snake['length']) {
            set_block_at(@snake['blocks'][0], 0, false);
            array_remove(@snake['blocks'], 0);
        }
        @snake['click'] = false;
        _snake_set_top(@snake);
        return(true);
    }
    return(false);
}

proc _snake_turn(@rotation, @snake) {
    if(@snake['click']) {
        return();
    }
    @snake['click'] = true;
    switch(@snake['top']) {
        case 'north':
            switch(@snake['dir']) {
                case 'east':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'up';
                    } else {
                        @snake['dir'] = 'down';
                    }

                case 'west':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'down';
                    } else {
                        @snake['dir'] = 'up';
                    }

                case 'up':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'west';
                    } else {
                        @snake['dir'] = 'east';
                    }

                case 'down':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'east';
                    } else {
                        @snake['dir'] = 'west';
                    }
            }

        case 'south':
            switch(@snake['dir']) {
                case 'east':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'down';
                    } else {
                        @snake['dir'] = 'up';
                    }

                case 'west':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'up';
                    } else {
                        @snake['dir'] = 'down';
                    }

                case 'up':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'east';
                    } else {
                        @snake['dir'] = 'west';
                    }

                case 'down':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'west';
                    } else {
                        @snake['dir'] = 'east';
                    }
            }

        case 'east':
            switch(@snake['dir']) {
                case 'north':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'down';
                    } else {
                        @snake['dir'] = 'up';
                    }

                case 'south':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'up';
                    } else {
                        @snake['dir'] = 'down';
                    }

                case 'up':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'north';
                    } else {
                        @snake['dir'] = 'south';
                    }

                case 'down':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'south';
                    } else {
                        @snake['dir'] = 'north';
                    }
            }

        case 'west':
            switch(@snake['dir']) {
                case 'north':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'up';
                    } else {
                        @snake['dir'] = 'down';
                    }

                case 'south':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'down';
                    } else {
                        @snake['dir'] = 'up';
                    }

                case 'up':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'south';
                    } else {
                        @snake['dir'] = 'north';
                    }

                case 'down':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'north';
                    } else {
                        @snake['dir'] = 'south';
                    }
            }

        case 'up':
            switch(@snake['dir']) {
                case 'north':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'east';
                    } else {
                        @snake['dir'] = 'west';
                    }

                case 'south':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'west';
                    } else {
                        @snake['dir'] = 'east';
                    }

                case 'east':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'south';
                    } else {
                        @snake['dir'] = 'north';
                    }

                case 'west':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'north';
                    } else {
                        @snake['dir'] = 'south';
                    }
            }


        case 'down':
            switch(@snake['dir']) {
                case 'north':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'west';
                    } else {
                        @snake['dir'] = 'east';
                    }

                case 'south':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'east';
                    } else {
                        @snake['dir'] = 'west';
                    }

                case 'east':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'north';
                    } else {
                        @snake['dir'] = 'south';
                    }

                case 'west':
                    if(@rotation == 'right') {
                        @snake['dir'] = 'south';
                    } else {
                        @snake['dir'] = 'north';
                    }
            }

    }
}

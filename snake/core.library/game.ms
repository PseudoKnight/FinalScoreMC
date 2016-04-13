include('util.ms');
include('snake.ms');

proc _snake_queue(@args) {
    // Check if a game is already running
    if(has_bind('snake-interact')) {
        die('Game is already running.');
    }

    // Default options
    @game = associative_array();
    @game['arena'] = 'plane';
    @game['surfaces'] = 5;
    @game['removeTail'] = false;
    @game['startingLength'] = 4;
    @game['snakes'] = associative_array();
    @game['powerups'] = array();
    @game['speed'] = 'normal';
    @game['debug'] = false;

    // Command options
    foreach(@arg in @args) {
        @split = split(':', @arg);
        if(array_size(@split) < 2) {
            die('Invalid setting: '.@arg);
        }
        @key = @split[0];
        @value = @split[1];
        @game[@key] = @value;
    }

    // Add players in region
    foreach(@p in all_players()) {
        if(array_contains(sk_current_regions(@p), 'snake') && pmode(@p) == 'ADVENTURE') {
            _snake_add(@p, @game);
        }
        if(array_size(@game['snakes']) == 7) {
            break();
        }
    }

    if(!array_index_exists(@game, 'numPowerups')) {
        @game['numPowerups'] = array_size(@game['snakes']);
    }

    // Start countdown
    @help = array(
        '',
        'Left or right-click to turn',
        'Left or right-click to turn',
        'SNAKE',
        'SNAKE',
        'SNAKE',
    );
    @countdown = array(5);
    set_interval(1000, closure(){
        if(@countdown[0] > 0) {
            foreach(@p in array_keys(@game['snakes'])) {
                if(!ponline(@p)) {
                    continue();
                }
                title_msg(@p, @countdown[0], array_get(@help, @countdown[0], ''), 0, 25, 0);
            }
        } else {
            clear_task();
            _snake_start(@game);
        }
        @countdown[0] -= 1;
    });
}

proc _snake_add_powerup(@game) {
    @region = 'snake_'.@game['arena'].rand(1, @game['surfaces'] + 1);
    @loc = _snake_valid_location(@region);
    if(@loc) {
        @block = _snake_block(170, @loc);
        set_block_at(@loc, @block, false);
        @game['powerups'][] = associative_array('block': @block, 'loc': @loc);
    }
}

proc _snake_remove_powerups(@game) {
    foreach(@i: @pu in @game['powerups']) {
        if(get_block_at(@pu['loc']) != @pu['block']) {
            array_remove(@game['powerups'], @i);
        }
    }
}

proc _snake_remove_all_powerups(@game) {
    foreach(@pu in @game['powerups']) {
        set_block_at(@pu['loc'], '0:0', false);
    }
    @game['powerups'] = array();
}

proc _snake_start(@game) {
    _snake_bind_events(@game);
    _snake_add_powerup(@game);
    @ms = 200;
    switch(@game['speed']) {
        case 'impossible':
            @ms = 50;
        case 'superfast':
            @ms = 100;
        case 'fast':
            @ms = 150;
        case 'slow':
            @ms = 250;
    }
    set_interval(@ms, closure() {
        @alive = 0;
        @active = 'No one';
        foreach(@player: @snake in @game['snakes']) {
            if(!ponline(@player) || !array_contains(sk_current_regions(@player), 'snake')) {
                _snake_remove(@player, @game);
                continue();
            }
            if(@snake['alive']) {
                if(_snake_update(@snake)) {
                    @alive++;
                    @active = @player;
                } else {
                    _snake_kill(@player, @game);
                }
            }
        }
        if((@alive < 2 && array_size(@game['snakes']) > 1) || @alive < 1) {
            clear_task();
            _snake_end(@active, @game);
        }
        _snake_remove_powerups(@game);
        if(array_size(@game['powerups']) < @game['numPowerups']) {
            _snake_add_powerup(@game);
        }
    });
}

proc _snake_end(@winner, @game) {
    foreach(@player in array_keys(@game['snakes'])) {
        title_msg(@player, @winner.' wins!', '');
    }
    _snake_unbind_events();
    set_timeout(3000, closure(){
        foreach(@player: @snake in @game['snakes']) {
            _snake_remove(@player, @game);
        }
        _snake_remove_all_powerups(@game);
    });
}

proc _snake_bind_events(@game) {
    bind(player_interact, array('id': 'snake-interact'), array('hand': 'main_hand'), @event, @game) {
        if(array_index_exists(@game['snakes'], player())) {
            _snake_turn(@event['button'], @game['snakes'][player()]);
        }
    }

    bind(item_swap, array('id': 'snake-swap'), null, @event, @game) {
        if(array_index_exists(@game['snakes'], player())) {
            cancel();
            _snake_ability(@game['snakes'][player()]);
        }
    }
}

proc _snake_unbind_events() {
    unbind('snake-interact');
    unbind('snake-swap');
}

proc _hazards_create() {
    if(!sk_region_exists('hazards')) {
        throw('NotFoundException', 'Hazards region does not exist!');
    }
    if(is_null(get_value('warp.hazards'))) {
        throw('NotFoundException', 'Hazards warp does not exist!');
    }
    @game = array(
        'world': pworld(),
        'players': associative_array(),
        'round': 0,
        'targetScore': 50,
        'maxRounds': 15,
        'timer': 50,
        'buildTimer': 15,
        'running': false,
        'entities': array(),
    );

    if(array_contains(get_scoreboards(), 'hazards')) {
        remove_scoreboard('hazards');
    }
    create_scoreboard('hazards');
    create_objective('score', 'DUMMY', 'hazards');
    set_objective_display('score', array('slot': 'SIDEBAR', 'displayname': color('bold').'Score (target: 100)'), 'hazards');

    if(array_contains(get_bars(), 'hazards')) {
        remove_bar('hazards');
    }
    create_bar('hazards', array('style': 'SEGMENTED_12', 'visible': false));

    export('hazards', @game);
    return(@game);
}

proc _hazards_start(@game) {
    include('events.ms');
    include('entities.ms');

    _hazards_clean_region(@game);
    _hazards_define_regions(@game);
    _hazards_bind(@game);
    @game['running'] = true;
    @timer = mutable_primitive(neg(@game['timer']));
    set_interval(1000, closure() {
        if(@game['round'] > 0) {
            foreach(@player: @data in @game['players']) {
                if(!ponline(@player)) {
                    _hazards_remove_player(@player, @game);
                    continue();
                }
                @regions = sk_current_regions(@player);
                if(pmode(@player) == 'ADVENTURE' && array_contains(@regions, 'hazards_end')) {
                    @data['score'] += 10;
                    set_pscore('score', @player, @data['score'], 'hazards');
                    set_pmode(@player, 'SPECTATOR');
                    play_sound(ploc(@player), array('sound': 'ENTITY_VINDICATOR_CELEBRATE', 'pitch': 1.5));
                } else if(!array_contains(@regions, 'hazards')) {
                    _hazards_remove_player(@player, @game);
                }
            }
            if(array_size(@game['players']) == 0) {
                clear_task();
                _hazards_end(@game);
                die();
            }
        }

        @timer--;
        if(@timer > 0) {
            if(@game['countdown']) {
                _hazards_msg(@game, color('bold').@timer);
                if(@timer < 12) {
                    update_bar('hazards', double(@timer / 12));
                }
            } else {
                @timer++; // keep waiting for the first block placement
            }
        } else if(@timer == 0) {
            _hazards_set_mode(@game, 'ADVENTURE');
            _hazards_spawn_players(@game);
            _hazards_activate_entities(@game);
            update_bar('hazards', array('visible': false));
        } else if(@timer > neg(@game['timer'])) {
            if(!_hazards_are_players_alive(@game)) {
                @timer[] = neg(@game['timer']);
            }
            _hazards_msg(@game, color('bold').(@timer + @game['timer']));
        } else {
            if(@game['round'] == @game['maxRounds'] || _hazards_did_player_win(@game)) {
                _hazards_end(@game);
                clear_task();
            } else {
                @game['round']++;
                _hazards_set_mode(@game, 'CREATIVE');
                _hazards_spawn_players(@game);
                _hazards_respawn_entities(@game);
                @timer[] = @game['buildTimer'];
                @game['countdown'] = false;
                update_bar('hazards', array('visible': true, 'percent': 1.0));
            }
        }
    });
}

proc _hazards_end(@game) {
    _hazards_unbind(@game);
    @winner = _hazards_get_winner(@game);
    if(@winner) {
        if(array_size(@winner) > 1) {
            broadcast(color('bold').array_implode(@winner, ', ').' won Hazards!', all_players(@game['world']));
        } else {
            broadcast(color('bold').display_name(@winner[0]).color('reset').' won Hazards!', all_players(@game['world']));
        }
    }
    foreach(@player in array_keys(@game['players'])) {
        _hazards_remove_player(@player, @game);
    }
    _hazards_remove_entities(@game);
    export('hazards', null);
    remove_scoreboard('hazards');
}

proc _hazards_clean_region(@game) {
    @coords = sk_region_info('hazards', @game['world'], 0);
    sk_pos1('~console', @coords[0]);
    sk_pos2('~console', @coords[1]);
    sk_setblock('~console', 'air');
    sk_pos1('~console', null);
    sk_pos2('~console', null);
}

proc _hazards_define_regions(@game) {
    @coords = sk_region_info('hazards', @game['world'], 0);
    @size = array_size(@game['players']) + 1;

    // define start region
    @startX = rand(@coords[1][0] + 1, @coords[1][0] + integer((@coords[0][0] - @coords[1][0]) / 3) - @size);
    @startY = rand(@coords[1][1] + 1, @coords[0][1] - 2);
    @startZ = rand(@coords[1][2] + 1, @coords[0][2] - @size);
    @start = array(
        array(@startX + @size, @startY + 3, @startZ + @size),
        array(@startX, @startY, @startZ);
    );
    if(!sk_region_exists('hazards_start')) {
        sk_region_create(@game['world'], 'hazards_start', @start);
    } else {
        sk_region_update(@game['world'], 'hazards_start', @start);
    }

    //set start platform
    @start[0][1] -= 3; // floor only
    @start[0][3] = @game['world']; // add worlds for console selection
    @start[1][3] = @game['world'];
    sk_pos1('~console', @start[0]);
    sk_pos2('~console', @start[1]);
    sk_setblock('~console', 'iron_block');

    // define end region
    @size = 3;
    @endX = rand(@coords[1][0] + integer((@coords[0][0] - @coords[1][0]) * 2 / 3), @coords[0][0] - @size);
    @endY = rand(@coords[1][1] + 1, @coords[0][1] - 2);
    @endZ = rand(@coords[1][2] + 1, @coords[0][2] - @size);
    @end = array(
        array(@endX + @size, @endY + 3, @endZ + @size),
        array(@endX, @endY, @endZ);
    );
    if(!sk_region_exists('hazards_end')) {
        sk_region_create(@game['world'], 'hazards_end', @end);
    } else {
        sk_region_update(@game['world'], 'hazards_end', @end);
    }

    //set end platform
    @end[0][1] -= 3; // floor only
    @end[0][3] = @game['world']; // add worlds for console selection
    @end[1][3] = @game['world'];
    sk_pos1('~console', @end[0]);
    sk_pos2('~console', @end[1]);
    sk_setblock('~console', 'emerald_block');

    // clear selection
    sk_pos1('~console', null);
    sk_pos2('~console', null);
}

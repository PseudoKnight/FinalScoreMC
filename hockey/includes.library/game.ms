proc _start_game(@players) {
    @hockey = associative_array(
        'players': @players,
        'puck': '',
        'velocity': associative_array(),
        'holder': '',
        'distance': 0,
        'last': '',
        'seconds': 300,
        'red': '',
        'blue': '',
    );
    @hockey['players'] = @players;
    
    // create scoreboard
    create_scoreboard('hockey');
    create_objective('score', 'dummy', 'hockey');
    set_objective_display('score', associative_array('slot': 'SIDEBAR', 'displayname': color('bold').'Score'), 'hockey');
    @hockey['red'] = color('red').array_rand(array('StoneRiver Toads', 'Utah Waffles', 'Jaksonville Slashers', 'Oakdale Furies'), 1, false)[0];
    @hockey['blue'] = color('blue').array_rand(array('Gothem Knights', 'Stirling Kings', 'PantsCo Pixies', 'Canada Wizards'), 1, false)[0];
    create_team('red', 'hockey');
    set_team_display('red', array('displayname': @hockey['red'], 'prefix': color('red')), 'hockey');
    set_pscore('score', @hockey['red'], 0, 'hockey');
    create_team('blue', 'hockey');
    set_team_display('blue', array('displayname': @hockey['blue'], 'prefix': color('blue')), 'hockey');
    set_pscore('score', @hockey['blue'], 0, 'hockey');
    @t = 0;
    foreach(@p in array_rand(@players, array_size(@players), false)) {
        @world = pworld(@p);
        set_pscoreboard(@p, 'hockey');
        if(@t) {
            team_add_player('red', @p, 'hockey');
            @t = 0;
            @item = associative_array('name': 'STAINED_GLASS_PANE', 'data': 14);
            set_pinv(@p, associative_array(4: @item, 5: @item, 6: @item, 7: @item, 8: @item));
        } else {
            team_add_player('blue', @p, 'hockey');
            @t = 1;
            @item = associative_array('name': 'STAINED_GLASS_PANE', 'data': 11);
            set_pinv(@p, associative_array(4: @item, 5: @item, 6: @item, 7: @item, 8: @item));
        }
        set_pheld_slot(@p, 0);
    }
    
    // get puck spawn point
    @region = sk_region_info('hockey', @world, 0);
    @loc = associative_array(
        'x': (@region[0][0] + @region[1][0]) / 2 + 0.5,
        'y': @region[1][1] + 0.078,
        'z': (@region[0][2] + @region[1][2]) / 2 + 0.5,
        'world': @world
    );
    
    // spawn puck
    @hockey['puck'] = spawn_mob('SLIME:1', 1, @loc)[0];
    @hockey['velocity'] = array('x': 0, 'y': 0, 'z': 0);
    set_timeout(50, closure(){
        set_mob_effect(@hockey['puck'], 11, 4, 99999, true, false);
        set_mob_effect(@hockey['puck'], 25, -1, 99999, true, false);
        set_mob_effect(@hockey['puck'], 2, 10, 99999, true, false);
    });
    
    // bind events
    bind(entity_damage, associative_array('id': 'hockey-damage'), associative_array('id': @hockey['puck']), @event, @hockey) {
        if(!array_index_exists(@event, 'damager')) {
            die();
        }
        @xp = 20;
        if(@event['damager'] == @hockey['holder']) {
            @xp = pexp(@event['damager']);
        }
        @player = @event['damager'];
        play_sound(entity_loc(@event['id']), array('sound': 'WOOD_CLICK', 'pitch': 2 - (1.3 / @xp)));
        @ploc = entity_loc(puuid(@player));
        @eloc = entity_loc(@hockey['puck']);
        @dist = _distance(@ploc, @eloc);
        @x = ((@eloc['x'] - @ploc['x']) / @dist) * (@xp / 30);
        @z = ((@eloc['z'] - @ploc['z']) / @dist) * (@xp / 30);
        @hockey['velocity'] = array('x': @x, 'y': 0, 'z': @z);
        set_entity_velocity(@hockey['puck'], @hockey['velocity']);
        @hockey['last'] = @player;
        @hockey['holder'] = '';
    }
    bind(player_interact_entity, associative_array('id': 'hockey-interact'), associative_array('id': @hockey['puck']), @event, @hockey) {
        @ploc = ploc();
        @eloc = entity_loc(@hockey['puck']);
        @ploc['y'] += 1;
        @dist = _distance(@ploc, @eloc);
        if(@dist < 3.5) {
            @hockey['holder'] = player();
            @hockey['last'] = player();
            @hockey['distance'] = @dist;
            set_pexp(0);
            play_sound(@eloc, array('sound': 'WOOD_CLICK', 'pitch': 0.6));
        }
    }
    bind(entity_damage_player, associative_array('id': 'hockey-damage-player'), associative_array('damager': 'PLAYER'), @event, @hockey) {
        if(@hockey['holder'] == player()) {
            set_pexp(@hockey['holder'], 0);
            @hockey['holder'] = '';
            @hockey['velocity'] = associative_array('x': 0, 'y': 0, 'z': 0);
        }
    }
    bind(player_quit, associative_array('id': 'hockey-quit'), null, @event, @hockey) {
        if(array_contains(@hockey['players'], player())) {
            array_remove_values(@hockey['players'], player());
            @teams = get_teams('hockey');
            if(array_contains(@teams[0]['players'], player())) {
                team_remove_player(@teams[0]['name'], player(), 'hockey');
                if(array_size(@teams[0]['players']) < 2) {
                    _end_game(@hockey);
                }
            } else {
                team_remove_player(@teams[1]['name'], player(), 'hockey');
                if(array_size(@teams[1]['players']) < 2) {
                    _end_game(@hockey);
                }
            }
            if(@hockey['holder'] == player()) {
                @hockey['holder'] = '';
                @hockey['last'] = '';
                @hockey['velocity'] = associative_array('x': 0, 'y': 0, 'z': 0);
                set_entity_velocity(@hockey['puck'], @hockey['velocity']);
            }
        }
    }
    
    // core game loop
    @count = array(20);
    @bounciness = 0.85;
    set_interval(50, 0, closure(){
        if(@count[0]-- == 0) {
            @count[0] = 20;
            @hockey['seconds']--;
            @time = simple_date('m:ss', @hockey['seconds'] * 1000);
            foreach(@p in all_players(@world)) {
                if(array_contains(sk_current_regions(@p), 'hockey')) {
                    if(!array_contains(@hockey['players'], @p)) {
                        @hockey['players'][] = @p;
                        @teams = get_teams('hockey');
                        if(array_size(@teams[0]['players']) > array_size(@teams[1]['players'])) {
                            team_add_player(@teams[1]['name'], @p, 'hockey');
                            @item = associative_array('name': 'STAINED_GLASS_PANE', 'data': 14);
                            set_pinv(@p, associative_array(4: @item, 5: @item, 6: @item, 7: @item, 8: @item));
                        } else {
                            team_add_player(@teams[0]['name'], @p, 'hockey');
                            @item = associative_array('name': 'STAINED_GLASS_PANE', 'data': 11);
                            set_pinv(@p, associative_array(4: @item, 5: @item, 6: @item, 7: @item, 8: @item));
                        }
                        set_pheld_slot(@p, 0);
                    }
                    action_msg(@p, @time);
                    set_peffect(@p, 8, -8, 2, false, false);
                } else if(array_contains(@hockey['players'], @p)) {
                    array_remove_values(@hockey['players'], @p);
                    @teams = get_teams('hockey');
                    if(array_contains(@teams[0]['players'], @p)) {
                        team_remove_player(@teams[0]['name'], @p, 'hockey');
                        if(array_size(@teams[0]['players']) < 2) {
                            _end_game(@hockey);
                        }
                    } else {
                        team_remove_player(@teams[1]['name'], @p, 'hockey');
                        if(array_size(@teams[1]['players']) < 2) {
                            _end_game(@hockey);
                        }
                    }
                }
            }
            if(@hockey['seconds'] < 1) {
                _end_game(@hockey);
            }
        }
        
        if(!entity_exists(@hockey['puck'])) {
            _end_game(@hockey);
            die();
        }
        
        @l = entity_loc(@hockey['puck']);
        @block = get_block_at(_relative(@l, 'down'));
        
        if(@block == '35:14' || @block == '35:11' || @block == '44:15') {
            if(@block != '44:15') {
                @team = if(@block == '35:11', @hockey['red'], @hockey['blue']);
                set_pscore('score', @team, get_pscore('score', @team, 'hockey') + 1, 'hockey');
                launch_firework(@l, associative_array('strength': 0));
            }
            set_entity_loc(@hockey['puck'], @loc);
            @hockey['holder'] = '';
            @hockey['last'] = '';
            @hockey['velocity'] = associative_array('x': 0, 'y': 0, 'z': 0);
            set_entity_velocity(@hockey['puck'], @hockey['velocity']);
            
        } else if(@hockey['holder'] && (@block == '79:0' || @block == '174:0')) {
            @uuid = puuid(@hockey['holder']);
            @newloc = entity_loc(@uuid);
            if(@newloc['world'] != @world) {
                @hockey['holder'] = '';
                @hockey['last'] = '';
                @hockey['velocity'] = associative_array('x': 0, 'y': 0, 'z': 0);
                set_entity_velocity(@hockey['puck'], @hockey['velocity']);
            } else {
                @vector = _get_vector(pfacing(@hockey['holder'])[0], 0, @hockey['distance'], 0);
                @newloc['x'] += @vector['x'];
                @newloc['z'] += @vector['z'];
                set_entity_loc(@hockey['puck'], @newloc);
                set_pexp(@hockey['holder'], min(100, pexp(@hockey['holder']) + 2));
                @v = entity_velocity(@uuid);
                @v['y'] = 0;
                @hockey['velocity'] = @v;
                set_entity_velocity(@hockey['puck'], @v);
            }
            
        } else {
            if(!array_contains(sk_regions_at(@l), 'hockey') || @l['y'] > @loc['y']) {
                set_entity_loc(@hockey['puck'], @loc);
                @hockey['holder'] = '';
                @hockey['last'] = '';
                @hockey['velocity'] = associative_array('x': 0, 'y': 0, 'z': 0);
                set_entity_velocity(@hockey['puck'], @hockey['velocity']);
                die();
            }
            
            @v = entity_velocity(@hockey['puck']);
            @ricochetPitch = 0;
            
            @forceX = 0;
            if(@v['x'] == 0) {
                @forceX = abs(@hockey['velocity']['x']);
                @v['magnitude'] = 1;
                if(@forceX > 0.002) {
                    @v['x'] = 0 - @hockey['velocity']['x'] * @bounciness;
                    if(@forceX > 0.05) {
                        @ricochetPitch = 1 + @forceX / 2;
                    }
                }
            }

            if(@v['z'] == 0) {
                @forceZ = abs(@hockey['velocity']['z']);
                @v['magnitude'] = 1;
                if(@forceZ > 0.002) {
                    @v['z'] = 0 - @hockey['velocity']['z'] * @bounciness;
                    if(@forceZ > 0.06 && @forceZ > @forceX) {
                        @ricochetPitch = 1 + @forceZ / 2;
                    }
                }
            }
            
            if(@v['magnitude'] < 0.875 && @v['magnitude'] > 0.125) {
                @v['x'] = (@v['x'] / @v['magnitude']) * (1.08 * @v['magnitude']);
                @v['z'] = (@v['z'] / @v['magnitude']) * (1.08 * @v['magnitude']);
            }
            
            if(@ricochetPitch > 1) {
                play_sound(@l, array('sound': 'WOOD_CLICK', 'pitch': min(2, @ricochetPitch)));
            }
            
            @v['y'] = 0;
            @hockey['velocity'] = @v;
            set_entity_velocity(@hockey['puck'], @hockey['velocity']);
        }
        
    });
}

proc _end_game(@hockey){
    clear_task();
    unbind('hockey-damage');
    unbind('hockey-damage-player');
    unbind('hockey-interact');
    unbind('hockey-quit');
    @teams = get_teams('hockey');
    @winner = null;
    @redscore = get_pscore('score', @hockey['red'], 'hockey');
    @bluescore = get_pscore('score', @hockey['blue'], 'hockey');
    @score = '';
    if(@redscore > @bluescore) {
        @winner = 'red';
        @score = @redscore.':'.@bluescore;
    } else if(@bluescore > @redscore) {
        @winner = 'blue';
        @score = @bluescore.':'.@redscore;
    } else {
        @score = @redscore.':'.@bluescore;
    }
    @msg = 'Tied game!';
    if(@winner) {
        @winners = associative_array();
        foreach(@t in @teams) {
            if(@t['name'] == @winner) {
                @winners = @t;
            }
        }
        @msg = @winners['displayname'].' won! '.color('bold').@score;
    }
    foreach(@p in @hockey['players']) {
        tmsg(@p, @msg);
    }
    remove_scoreboard('hockey');
    entity_remove(@hockey['puck']);
}

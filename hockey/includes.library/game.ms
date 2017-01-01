proc _start_game(@players) {
    _add_activity('hockey', 'Ice Hockey');
    @hockey = associative_array(
        'players': @players,
        'puck': '',
        'velocity': associative_array(),
        'holder': '',
        'distance': 0,
        'last': '',
        'seconds': 180,
        'red': '',
        'blue': '',
        'loc': associative_array(),
        'lastloc': associative_array(),
    );
    @hockey['players'] = @players;
    
    // create scoreboard
    create_scoreboard('hockey');
    create_objective('score', 'dummy', 'hockey');
    set_objective_display('score', associative_array('slot': 'SIDEBAR', 'displayname': color('bold').'Score'), 'hockey');
    
    @hockey['red'] = color('red').array_rand(array('StoneRiver Toads', 'Utah Waffles', 'Jaksonville Slashers', 'Oakdale Furies'), 1, false)[0];
    create_team('red', 'hockey');
    set_team_display('red', array('displayname': @hockey['red'], 'prefix': color('red')), 'hockey');
    set_pscore('score', @hockey['red'], 0, 'hockey');
    @item = associative_array('name': 'STAINED_GLASS_PANE', 'data': 14);
    @redgear = associative_array(
        4: @item, 5: @item, 6: @item, 7: @item, 8: @item,
        100: associative_array('name': 'LEATHER_BOOTS', 'meta': associative_array('color': array(255, 0, 0))),
        101: associative_array('name': 'LEATHER_LEGGINGS', 'meta': associative_array('color': array(255, 0, 0))),
        102: associative_array('name': 'LEATHER_CHESTPLATE', 'meta': associative_array('color': array(255, 0, 0))),
        103: associative_array('name': 'LEATHER_HELMET', 'meta': associative_array('color':array(255, 0, 0))),
    );
    
    @hockey['blue'] = color('blue').array_rand(array('Gothem Knights', 'Stirling Kings', 'PantsCo Pixies', 'Canada Wizards'), 1, false)[0];
    create_team('blue', 'hockey');
    set_team_display('blue', array('displayname': @hockey['blue'], 'prefix': color('blue')), 'hockey');
    set_pscore('score', @hockey['blue'], 0, 'hockey');
    @item = associative_array('name': 'STAINED_GLASS_PANE', 'data': 11);
    @bluegear = associative_array(
        4: @item, 5: @item, 6: @item, 7: @item, 8: @item,
        100: associative_array('name': 'LEATHER_BOOTS', 'meta': associative_array('color': array(0, 0, 255))),
        101: associative_array('name': 'LEATHER_LEGGINGS', 'meta': associative_array('color': array(0, 0, 255))),
        102: associative_array('name': 'LEATHER_CHESTPLATE', 'meta': associative_array('color': array(0, 0, 255))),
        103: associative_array('name': 'LEATHER_HELMET', 'meta': associative_array('color': array(0, 0, 255))),
    );
    
    @t = 0;
    foreach(@p in array_rand(@players, array_size(@players), false)) {
        @world = pworld(@p);
        set_pscoreboard(@p, 'hockey');
        if(@t) {
            team_add_player('red', @p, 'hockey');
            @t = 0;
            set_pinv(@p, @redgear);
        } else {
            team_add_player('blue', @p, 'hockey');
            @t = 1;
            set_pinv(@p, @bluegear);
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
    @hockey['loc'] = @loc;
    
    _place_puck(@hockey);
    
    // bind events
    bind(entity_damage, associative_array('id': 'hockey-damage'), associative_array('id': @hockey['puck']), @event, @hockey) {
        if(!array_index_exists(@event, 'damager')) {
            @hockey['holder'] = '';
            set_entity_loc(@hockey['puck'], @hockey['lastloc']);
            die();
        }
        @xp = 20;
        if(@event['damager'] == @hockey['holder']) {
            @xp = max(1, pexp(@event['damager'])) ** 1.3;
        }
        @player = @event['damager'];
        play_sound(entity_loc(@event['id']), array('sound': 'WOOD_CLICK', 'pitch': 2 - (1.3 / @xp)));
        @ploc = entity_loc(puuid(@player));
        @eloc = entity_loc(@hockey['puck']);
        @dist = _distance(@ploc, @eloc);
        @x = ((@eloc['x'] - @ploc['x']) / @dist) * (@xp / 100);
        @z = ((@eloc['z'] - @ploc['z']) / @dist) * (@xp / 100);
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
            @hockey['velocity'] = associative_array('x': 0, 'y': 0, 'z': 0);
            @hockey['lastloc'] = entity_loc(@hockey['puck']);
            set_pexp(0);
            play_sound(@eloc, array('sound': 'WOOD_CLICK', 'pitch': 0.6));
        }
    }
    bind(entity_damage_player, associative_array('id': 'hockey-damage-player'), associative_array('damager': 'PLAYER'), @event, @hockey) {
        if(@hockey['holder'] == player()) {
            set_pexp(@hockey['holder'], 0);
            @hockey['holder'] = '';
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
                _place_puck(@hockey);
            }
        }
    }
    bind(target_player, associative_array('id': 'hockey-target'), associative_array('mobtype': 'SLIME'), @event, @hockey) {
        if(@event['id'] == @hockey['puck']) {
            modify_event('player', null);
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
                            set_pinv(@p, @bluegear);
                        } else {
                            team_add_player(@teams[0]['name'], @p, 'hockey');
                            set_pinv(@p, @redgear);
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
        
        if(@block == '35:14' || @block == '35:11') {
            @team = if(@block == '35:11', @hockey['red'], @hockey['blue']);
            set_pscore('score', @team, get_pscore('score', @team, 'hockey') + 1, 'hockey');
            launch_firework(@l, associative_array('strength': 0));
            _place_puck(@hockey);
            
        } else if(@block == '44:15') {
            @hockey['holder'] = '';
            set_entity_loc(@hockey['puck'], @hockey['lastloc']);
            
        } else if(@hockey['holder'] && (@block == '79:0' || @block == '174:0')) {
            @newloc = ploc(@hockey['holder']);
            if(@newloc['world'] != @world) {
                _place_puck(@hockey);
            } else {
                if(@hockey['distance'] > 2.24) {
                    @hockey['distance'] -= 0.05;
                } else if(@hockey['distance'] < 2.16) {
                    @hockey['distance'] += 0.05;
                }
                @vector = _get_vector(pfacing(@hockey['holder']), @hockey['distance'], 0);
                @newloc['x'] += @vector['x'];
                @newloc['y'] += 1;
                @newloc['z'] += @vector['z'];
                set_entity_loc(@hockey['puck'], @newloc);
                @hockey['lastloc'] = @l;
                set_pexp(@hockey['holder'], min(100, pexp(@hockey['holder']) + 2));
            }
            
        } else {
            if(!array_contains(sk_regions_at(@l), 'hockey') || @l['y'] > @loc['y']) {
                _place_puck(@hockey);
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

proc _place_puck(@hockey){
    if(!@hockey['puck']) {
        @hockey['puck'] = spawn_mob('SLIME:1', 1, @hockey['loc'])[0];
        set_timeout(50, closure(){
            set_mob_effect(@hockey['puck'], 11, 4, 99999, true, false);
            set_mob_effect(@hockey['puck'], 25, -1, 99999, true, false);
            set_mob_effect(@hockey['puck'], 2, 10, 99999, true, false);
        });
    } else {
        set_entity_loc(@hockey['puck'], @hockey['loc']);
    }
    @hockey['holder'] = '';
    @hockey['last'] = '';
    @hockey['velocity'] = associative_array('x': 0, 'y': 0, 'z': 0);
    set_entity_velocity(@hockey['puck'], @hockey['velocity']);
}

proc _end_game(@hockey){
    clear_task();
    unbind('hockey-damage');
    unbind('hockey-damage-player');
    unbind('hockey-interact');
    unbind('hockey-quit');
    unbind('hockey-target');
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
    _remove_activity('hockey');
    entity_remove(@hockey['puck']);
}

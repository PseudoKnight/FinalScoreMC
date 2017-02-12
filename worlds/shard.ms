bind(player_interact, null, array('item': 264, 'hand': 'main_hand', 'block': 0), @event) {
    proc _random_spawn_location() {
        @worldborder = get_world_border('shard');
        @width = @worldborder['width'];
        @loc = @worldborder['center'];
        @loc['x'] += rand() * @width - @width / 2;
        @loc['z'] += rand() * @width - @width / 2;
        return(get_highest_block_at(@loc));
    }
    
    if(array_contains(get_worlds(), 'shard')) {
        if(pworld() == 'shard') {
            action_msg('You can\'t go deeper!');
        } else {
            play_sound(ploc(), array('sound': 'GLASS', 'pitch': 0.5));
            @loc = get_spawn('shard');
            @loc['y'] -= 1;
            set_ploc(_random_spawn_location());
            set_peffect(player(), 11, 3, 30, true);
            play_sound(@loc, array('sound': 'GLASS', 'pitch': 0.5), player());
            if(get_world_border('shard')['width'] < 128) {
                set_pmode('SPECTATOR');
            }
        }
        die();
    }
    if(!has_permission('group.moderator')) {
        action_msg('Only staff can generate shards for now!');
        die();
    }
    @start = time();
    
    // Get players
    @world = pworld();
    @worldname = _worldname(@world);
    @players = array();
    foreach(@p in all_players()) {
        if(pworld(@p) != @world) {
            continue();
        }
        @item = pinv(@p, null);
        if(@item && @item['name'] == 'DIAMOND') {
            @players[] = @p;
            @ploc = ploc(@p);
            play_named_sound(@ploc, array('sound': 'entity.guardian.attack', 'volume': 2));
        }
    }
    if(array_size(@players) < 2 && !pisop()) {
        play_sound(ploc(), array('sound': 'FIZZ', 'pitch': 0.7));
        action_msg('Not enough players to generate a shard!');
        die();
    }

    // Remove existing region files
    @base = '../../../..'; // relative to script location
    try {
        @files = list_files("@base/shard/region");
        foreach(@file in @files) {
            if(string_starts_with(@file, 'r.') && file_size("@base/shard/region/@file") > 1000000) {
                delete_file("@base/shard/region/@file");
            }
        }
    } catch(IOException @ex) {
        // world does not exist yet
    }
    
    // Setup region files
    @environment = world_info(@world)['environment'];
    @chunk = get_chunk_loc();
    @x = floor(@chunk['x'] / 32);
    @z = floor(@chunk['z'] / 32);
    @x2 = if(round(@chunk['x'] / 32) == @x, @x - 1, @x + 1);
    @z2 = if(round(@chunk['z'] / 32) == @z, @z - 1, @z + 1);
    @dim = '';
    if(@environment == 'NETHER') {
        @dim = '/DIM-1';
    } else if(@environment == 'THE_END') {
        @dim = '/DIM1';
    }
    @stop = time();
    console('Shard setup completed ('.(@stop - @start).'ms)', false);
    
    set_timeout(50, closure(){
        // Copy region files
        @start = time();
        try {
            copy_file("@base/@{world}@dim/region/r.@x.@z.mca", "@base/shard/region/r.@x.@z.mca");
            copy_file("@base/@{world}@dim/region/r.@x2.@z.mca", "@base/shard/region/r.@x2.@z.mca");
            copy_file("@base/@{world}@dim/region/r.@x.@z2.mca", "@base/shard/region/r.@x.@z2.mca");
            copy_file("@base/@{world}@dim/region/r.@x2.@z2.mca", "@base/shard/region/r.@x2.@z2.mca");
        } catch(IOException @ex) {
            console('Failed to copy files!', false);
            die();
        }
        @stop = time();
        console('Copy region files ('.(@stop - @start).'ms)', false);
        
        set_timeout(50, closure(){
            // Create shard
            @start = time();
            _create_world('shard', array(
                'name': @worldname.'//Shard',
                'mode': 'SURVIVAL',
                'group': 'shard',
                'teleports': true,
                'environment': 'NORMAL',
                'seed': null,
                'generator': 'CleanroomGenerator:.',
            ));
            @stop = time();
            console('Created shard ('.(@stop - @start).'ms)', false);
            
            set_timeout(150, closure(){
                include('../inventory/util.library/loot.ms');
                // Set pre-player world settings
                @minX = min(@x, @x2) * 512;
                @maxX = (max(@x, @x2) + 1) * 512;
                @minZ = min(@z, @z2) * 512;
                @maxZ = (max(@z, @z2) + 1) * 512;
                @centerX = @minX + 512;
                @centerZ = @minZ + 512;
                @loc = get_highest_block_at(@centerX, @centerZ, 'shard');
                set_spawn(@loc);
                set_world_time('shard', get_world_time(@world));
                storm(false, 'shard');
                set_world_border('shard', array('width': 1024, 'center': @loc));
                _add_activity('shard', @worldname.'//Shard');
                
                // Teleport players
                @loc['y'] -= 1;
                foreach(@p in @players) {
                    if(pworld(@p) != @world) {
                        continue();
                    }
                    queue_push(closure(){
                        @ploc = ploc(@p);
                        play_sound(@ploc, array('sound': 'GLASS', 'pitch': 0.5));
                        @ploc['world'] = 'shard';
                        if(@p != player()
                        && (@ploc['x'] < @minX
                        || @ploc['x'] > @maxX
                        || @ploc['z'] < @minZ
                        || @ploc['z'] > @maxZ)) {
                            @ploc = _random_spawn_location();
                        }
                        set_ploc(@p, @ploc);
                        set_peffect(@p, 11, 3, 60, true);
                        play_sound(@ploc, array('sound': 'GLASS', 'pitch': 0.5), @p);
                        play_sound(@ploc, array('sound': 'WITHER_SPAWN', 'pitch': 0.7), @p);
                    }, 'shard');
                }
                
                proc _check_shard() {
                    set_timeout(50, closure(){
                        @count = 0;
                        @last = '';
                        foreach(@p in all_players()) {
                            if(pworld(@p) == 'shard' && pmode(@p) != 'SPECTATOR') {
                                @count++;
                                @last = @p;
                            }
                        }
                        if(@count == 1) {
                            set_world_border('shard', array('width': 1, 'seconds': 20));
                            storm(true, 'shard');
                            set_thunder(true, 'shard');
                            _worldmsg('shard', color('green').@last.' wins!');
                            set_timeout(20000, closure(){
                                if(array_contains(get_worlds(), 'shard') && pworld(@last) == 'shard') {
                                    explosion(_relative(ploc(@last), 'up', 2), 5);
                                }
                            });
                        } else if(@count == 0) {
                            _remove_activity('shard');
                            unbind('shard-quit');
                            unbind('shard-death');
                            unbind('shard-spawn');
                            unbind('shard-interact');
                            unbind('shard-worldchanged');
                            unbind('shard-itemframe');
                            unbind('shard-place1');
                            unbind('shard-place2');
                            foreach(@p in all_players()) {
                                if(pworld(@p) == 'shard') {
                                    queue_push(closure(){
                                        @pdata = _pdata(@p);
                                        set_ploc(@p, @pdata['survival']['loc']);
                                    }, 'shard');
                                }
                            }
                            queue_push(closure(){
                                if(array_size(all_players('shard')) > 0 || !unload_world('shard')) {
                                    console('Failed to unload shard world!', false);
                                } else {
                                    array_remove(_worlds_config(), 'shard');
                                }
                            }, 'shard');
                        }
                    });
                }
                
                // Events
                bind(player_quit, array('priority': 'HIGHEST', 'id': 'shard-quit'), null, @event) {
                    if(pworld() == 'shard') {
                        @loc = get_spawn('custom');
                        @loc['y'] -= 1;
                        set_ploc(@loc);
                        _check_shard();
                    }
                }
                
                bind(player_death, array('priority': 'HIGHEST', 'id': 'shard-death'), null, @event, @players) {
                    if(@event['location']['world'] == 'shard') {
                        consume();
                        modify_event('death_message', color('k').'X'.color('r').' '.@event['death_message']);
                        export('playerspawn', ploc());
                        set_pmode('SPECTATOR');
                        if(get_world_border('shard')['width'] > 1000) {
                            @seconds = array_size(@players) * 180 + 600;
                            set_world_border('shard', array('width': 1, 'seconds': @seconds));
                            _worldmsg('shard', 'Shard has started to collapse! ETA '.floor(@seconds / 60).' minutes');
                        }
                    }
                }
                
                bind(player_spawn, array('id': 'shard-spawn', 'priority': 'LOWEST'), array('world': 'shard'), @event) {
                    modify_event('location', import('playerspawn', get_spawn('shard')));
                    _check_shard();
                    export('playerspawn', null);
                }
                
                bind(world_changed, array('id': 'shard-worldchanged'), array('from': 'shard'), @event) {
                    _check_shard();
                }
                
                bind(player_interact, array('id': 'shard-interact'), null, @event) {
                    if(@event['block'] != 0 && pworld() == 'shard') {
                        switch(split(':', @event['block'], 1)[0]) {
                            case '23':
                            case '61':
                            case '117':
                            case '154':
                            case '158':
                                _set_random_contents(@event['location'], 0);
                            case '54':
                            case '146':
                                _set_random_contents(@event['location'], 3);
                        }
                    }
                }
                
                bind(block_place, array('id': 'shard-place1'), array('type': 54), @event) {
                    _set_random_contents(@event['location'], 0);
                }
                
                bind(block_place, array('id': 'shard-place2'), array('type': 146), @event) {
                    _set_random_contents(@event['location'], 0);
                }
                
                bind(entity_damage, array('id': 'shard-itemframe'), array('type': 'ITEM_FRAME'), @event) {
                	if(@event['world'] == 'shard') {
                		cancel();
                	}
                }
                
            });
        });
    });
}

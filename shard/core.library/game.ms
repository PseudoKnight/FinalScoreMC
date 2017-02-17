proc _shard_create(@rules){
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
    @base = '../../../../..'; // relative to script location
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
                // Calculate area and center
                @minX = min(@x, @x2) * 512;
                @maxX = (max(@x, @x2) + 1) * 512;
                @minZ = min(@z, @z2) * 512;
                @maxZ = (max(@z, @z2) + 1) * 512;
                @centerX = @minX + 512;
                @centerZ = @minZ + 512;
                
                // Randomize center slightly
                @randX = rand(0, 65) - 32;
                @centerX += @randX;
                @randZ = rand(0, 65) - 32;
                @centerZ += @randZ;
                if(@randX < 0) {
                    @maxX += @randX * 2;
                } else {
                    @minX += @randX * 2;
                }
                if(@randZ < 0) {
                    @maxZ += @randZ * 2;
                } else {
                    @minZ += @randZ * 2;
                }
                @loc = get_highest_block_at(@centerX, @centerZ, 'shard');
                
                // Set world settings
                set_spawn(@loc);
                set_world_time('shard', get_world_time(@world));
                storm(false, 'shard');
                set_world_border('shard', array('width': min(@maxX - @minX, @maxZ - @minZ), 'center': @loc));
                set_gamerule('shard', 'NATURALREGENERATION', true);
                
                // Start game
                create_scoreboard('shard');
                _add_activity('shard', @worldname.'//Shard');
                
                @binds = array();
                @randomspawn = false;
                foreach(@rule in @rules) {
                    if(@rule['value']) {
                        include('../rules.library/'.@rule['name'].'.ms');
                    }
                }
                
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
                        if(@randomspawn
                        || @p != player()
                        && (@ploc['x'] < @minX
                        || @ploc['x'] > @maxX
                        || @ploc['z'] < @minZ
                        || @ploc['z'] > @maxZ)) {
                            @ploc = _get_spawn_location();
                        }
                        set_ploc(@p, @ploc);
                        _shard_equip(@p);
                        set_peffect(@p, 11, 3, 60, true);
                        set_pscoreboard(@p, 'shard');
                        play_sound(@ploc, array('sound': 'GLASS', 'pitch': 0.5), @p);
                        play_sound(@ploc, array('sound': 'WITHER_SPAWN', 'pitch': 0.7), @p);
                    }, 'shard');
                }
                
                proc _check_shard(@binds) {
                    queue_push(closure(){
                        @count = 0;
                        @last = '';
                        if(get_teams()) {
                            @left = array();
                            foreach(@p in all_players()) {
                                if(pworld(@p) == 'shard' && pmode(@p) != 'SPECTATOR') {
                                    @team = _get_team(@p);
                                    if(@team) {
                                        if(!array_contains(@left, @team)) {
                                            @left[] = @team;
                                            @count++;
                                            @last = 'Team '.@team;
                                        }
                                    } else {
                                        @last = @p;
                                        @count++; // still count players not in a team
                                    }
                                }
                            }
                        } else {
                            foreach(@p in all_players()) {
                                if(pworld(@p) == 'shard' && pmode(@p) != 'SPECTATOR') {
                                    @count++;
                                    @last = @p;
                                }
                            }
                        }
                        if(@count == 1) {
                            set_world_border('shard', array('width': 1, 'seconds': 20));
                            storm(true, 'shard');
                            set_thunder(true, 'shard');
                            _worldmsg('shard', color('green').@last.' wins!');
                            set_timeout(20000, closure(){
                                if(array_contains(get_worlds(), 'shard') && ponline(@last) && pworld(@last) == 'shard') {
                                    explosion(_relative(ploc(@last), 'up', 2), 5);
                                }
                            });
                        } else if(@count == 0) {
                            foreach(@p in all_players()) {
                                if(pworld(@p) == 'shard') {
                                    queue_push(closure(){
                                        if(pworld(@p) == 'shard') {
                                            @pdata = _pdata(@p);
                                            set_ploc(@p, @pdata['survival']['loc']);
                                        }
                                    }, 'shard');
                                }
                            }
                            queue_push(closure(){
                                if(!array_contains(get_worlds(), 'shard')) {
                                    die();
                                }
                                if(array_size(all_players('shard')) == 0 && unload_world('shard')) {
                                    remove_scoreboard('shard');
                                    array_remove(_worlds_config(), 'shard');
                                    _remove_activity('shard');
                                    foreach(@bind in @binds) {
                                        unbind(@bind);
                                    }
                                } else {
                                    console('Failed to unload shard world!', false);
                                }
                            }, 'shard');
                        }
                    }, 'shard');
                }
                
                // Events
                @binds[] = 'shard-quit';
                @binds[] = 'shard-death';
                @binds[] = 'shard-spawn';
                @binds[] = 'shard-worldchanged';
                bind(player_quit, array('priority': 'HIGHEST', 'id': 'shard-quit'), null, @event, @binds) {
                    if(pworld() == 'shard') {
                        @loc = get_spawn('custom');
                        @loc['y'] -= 1;
                        set_ploc(@loc);
                        _check_shard(@binds);
                    }
                }
                
                bind(player_death, array('priority': 'HIGHEST', 'id': 'shard-death'), null, @event, @players) {
                    if(@event['location']['world'] == 'shard') {
                        consume();
                        modify_event('death_message', color('k').'X'.color('r').' '.@event['death_message']);
                        @loc = ploc();
                        if(@loc['y'] < 0) {
                            @loc['y'] = 0;
                        }
                        export('playerspawn', @loc);
                        set_pmode('SPECTATOR');
                        if(get_world_border('shard')['width'] > 960) {
                            @seconds = array_size(@players) * 180 + 600;
                            set_world_border('shard', array('width': 1, 'seconds': @seconds));
                            _worldmsg('shard', color('red').color('bold').'Shard has started to collapse! ('.floor(@seconds / 60).' minutes)');
                        }
                        set_timeout(50, closure(){
                            respawn();
                        });
                    }
                }
                
                bind(player_spawn, array('id': 'shard-spawn', 'priority': 'LOWEST'), array('world': 'shard'), @event, @binds) {
                    modify_event('location', import('playerspawn', get_spawn('shard')));
                    _check_shard(@binds);
                    export('playerspawn', null);
                }
                
                bind(world_changed, array('id': 'shard-worldchanged'), array('from': 'shard'), @event, @binds) {
                    _check_shard(@binds);
                }
                
            });
        });
    });
}

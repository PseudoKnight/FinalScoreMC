bind(player_interact, null, array('item': 264, 'hand': 'main_hand', 'block': 0), @event) {
    if(!pisop()) {
        action_msg('Only ops can generate shards!');
        die();
    }
    if(array_contains(get_worlds(), 'shard')) {
        if(pworld() == 'shard') {
            action_msg('You can\'t go deeper!');
        } else {
            action_msg('Shard already exists!');
        }
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
    
    // Copy region files
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
    console('Setup regions files ('.(@stop - @start).'ms)', false);
    
    set_timeout(50, closure(){
        // Create shard
        @start = time();
        _create_world('shard', array(
            'name': @worldname.'//Shard',
            'mode': 'SURVIVAL',
            'group': 'shard',
            'teleports': false,
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
            set_world_border('shard', array('width': 1024, 'center': @loc));
            set_world_border('shard', array('width': 1, 'seconds': array_size(@players) * 200 + 500));
            
            // Teleport players
            @loc['y'] -= 1;
            foreach(@p in @players) {
                if(pworld(@p) != @world) {
                    continue();
                }
                queue_push(closure(){
                    @ploc = ploc(@p);
                    @bedloc = @ploc[];
                    @ploc['world'] = 'shard';
                    if(@p != player()
                    && (@ploc['x'] < @minX
                    || @ploc['x'] > @maxX
                    || @ploc['z'] < @minZ
                    || @ploc['z'] > @maxZ)) {
                        @ploc = @loc;
                    }
                    play_sound(@bedloc, array('sound': 'GLASS', 'pitch': 0.5));
                    set_peffect(@p, 15, 1, 2, true, false);
                    set_ploc(@p, @ploc);
                    set_pbed_location(@p, @bedloc);
                    set_peffect(@p, 15, 1, 2, true, false);
                    play_sound(@ploc, array('sound': 'GLASS', 'pitch': 0.5), @p);
                    play_sound(@ploc, array('sound': 'WITHER_SPAWN', 'pitch': 0.7), @p);
                }, 'shard');
            }
            
            proc _check_shard() {
                @count = 0;
                foreach(@p in all_players()) {
                    if(pworld(@p) == 'shard' && pinfo(@p, 5) > 0) {
                        @count++;
                    }
                }
                if(@count == 1) {
                    set_world_border('shard', array('size': 1, 'seconds': 20));
                    storm(true, 'shard');
                    set_thunder(true, 'shard');
                } else if(@count == 0) {
                    unbind('shard-quit');
                    unbind('shard-death');
                    unbind('shard-spawn');
                    unbind('shard-invclick');
                    unbind('shard-interact1');
                    unbind('shard-interact2');
                    set_timeout(100, closure(){
                        if(array_size(all_players('shard')) > 0 || !unload_world('shard')) {
                            console('Failed to unload shard world!', false);
                        } else {
                            array_remove(_worlds_config(), 'shard');
                        }
                    });
                }
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
            
            bind(player_death, array('priority': 'HIGHEST', 'id': 'shard-death'), null, @event) {
                if(@event['location']['world'] == 'shard') {
                    consume();
                    modify_event('death_message', color('k').'X'.color('r').' '.@event['death_message']);
                }
            }
            
            bind(player_spawn, array('id': 'shard-spawn'), null, @event) {
                _check_shard();
            }
            
            bind(inventory_click, array('id': 'shard-invclick'), array('slottype': 'CONTAINER'), @event) {
                if(pworld() == 'shard') {
                    if(@event['inventorytype'] == 'HOPPER') {
                        cancel();
                        action_msg('Clicking in hoppers is not allowed!');
                    } else if(@event['inventorysize'] > 5) {
                        @marker = @event['inventory'][0];
                        if(@event['slot'] == 0 || !@marker || @marker['name'] != 'CHEST'
                        || !@marker['meta'] || @marker['meta']['display'] != 'LOOT CHEST') {
                            cancel();
                            action_msg('Clicking on this item is not allowed!');
                        }
                    }
                }
            }
            
            bind(player_interact, array('id': 'shard-interact1'), array('block': 54), @event) {
                if(pworld() == 'shard') {
                    _set_random_contents(@event['location'], 6);
                }
            }
            
            bind(player_interact, array('id': 'shard-interact2'), array('block': 146), @event) {
                if(pworld() == 'shard') {
                    _set_random_contents(@event['location'], 6);
                }
            }
            
        });
    });
}

bind(player_interact, null, array('item': 264, 'hand': 'main_hand', 'block': 0), @event) {
    if(!pisop()) {
        action_msg('Only ops can generate shards!');
        die();
    }
    if(array_contains(get_worlds(), 'shard')) {
        action_msg('Shard already exists!');
        die();
    }
    @start = time();
    
    // Get players
    @world = pworld();
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
        @worlds = _worlds_config();
        _create_world('shard', array(
            'name': @worlds[@world]['name'].' Shard',
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
            // Set pre-player world settings
            @region = array(
                'x': array(min(@x, @x2) * 512, (max(@x, @x2) + 1) * 512),
                'z': array(min(@z, @z2) * 512, (max(@z, @z2) + 1) * 512),
            );
            @centerX = @region['x'][0] + 512;
            @centerZ = @region['z'][0] + 512;
            @loc = get_highest_block_at(@centerX, @centerZ, 'shard');
            set_spawn(@loc);
            set_world_time('shard', get_world_time(@world));
            set_world_border('shard', array('size': 1024, 'center': @loc));
            set_world_border('shard', array('size': 1, 'seconds': 1200));
            
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
                    && (@ploc['x'] < @region['x'][0]
                    || @ploc['x'] > @region['x'][1]
                    || @ploc['z'] < @region['z'][0]
                    || @ploc['z'] > @region['z'][1])) {
                        @ploc = @loc;
                    }
                    set_ploc(@p, @ploc);
                    set_pbed_location(@p, @bedloc);
                    set_peffect(@p, 15, 1, 2, true, false);
                    play_sound(@bedloc, array('sound': 'GLASS', 'pitch': 0.7));
                    play_sound(@ploc, array('sound': 'GLASS', 'pitch': 0.7), @p);
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
                    set_timeout(100, closure(){
                        if(array_size(all_players('shard')) > 0 || !unload_world('shard')) {
                            console('Failed to unload shard world!', false);
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
            
        });
    });
}

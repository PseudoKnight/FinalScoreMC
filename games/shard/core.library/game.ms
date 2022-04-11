proc _shard_create(@rules){
	@start = time();
	// Get players
	@world = pworld();
	@worldgroup = _world_group(@world);
	@worldname = _worldname(@world);
	@players = array();
	foreach(@p in all_players()) {
		if(_world_group(pworld(@p)) != @worldgroup) {
			continue();
		}
		@item = pinv(@p, null);
		if(@item && @item['name'] == 'AMETHYST_SHARD') {
			@players[] = @p;
			@ploc = ploc(@p);
			play_named_sound(@ploc, array('sound': 'entity.guardian.attack', 'volume': 2));
		}
	}
	if(array_size(@players) < 2 && !pisop()) {
		play_sound(ploc(), array('sound': 'BLOCK_FIRE_EXTINGUISH', 'pitch': 0.7));
		action_msg('Not enough players to generate a shard!');
		die();
	}

	// Remove existing region files
	if(extension_exists('CHDynmap')) {
		dm_set_update_renders_paused(true);
	}
	@base = '../../../../../..'; // relative to script location
	try {
		@files = list_files("@base/shard/region");
		foreach(@file in @files) {
			if(string_starts_with(@file, 'r.')) { // 
				delete_file("@base/shard/region/@file");
				try(delete_file("@base/shard/entities/@file"));
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
				'difficulty': 'HARD',
			));
			@stop = time();
			console('Created shard ('.(@stop - @start).'ms)', false);

			set_timeout(150, closure(){
				if(extension_exists('CHDynmap')) {
					dm_set_update_renders_paused(false);
				}

				// Calculate center
				@centerX = 0;
				@centerZ = 0;
				if(@rules['width'] <= 512) { // use player location if possible
					@ploc = ploc();
					@centerX = @ploc['x'];
					@centerZ = @ploc['z'];
				} else { // otherwise use center of entire shard
					@centerX = min(@x, @x2) * 512 + 512;
					@centerZ = min(@z, @z2) * 512 + 512;

					// Randomize center slightly
					@randX = rand(0, 65) - 32;
					@centerX += @randX;
					@randZ = rand(0, 65) - 32;
					@centerZ += @randZ;
				}

				// Calculate worldborder region
				@radius = @rules['width'] / 2;
				@minX = @centerX - @radius;
				@maxX = @centerX + @radius;
				@minZ = @centerZ - @radius;
				@maxZ = @centerZ + @radius;

				@loc = get_highest_block_at(@centerX, @centerZ, 'shard');

				// Set dynmap marker
				if(extension_exists('CHDynmap')) {
					include('../util.library/dynmap.ms');
				}

				// Set world settings
				set_spawn(@loc);
				set_world_time('shard', get_world_time(@world));
				storm(false, 'shard');
				set_world_border('shard', array('width': @rules['width'], 'center': @loc));
				set_gamerule('shard', 'NATURALREGENERATION', !array_index_exists(@rules, 'regen') || !@rules['noregen']);
				set_spawning('shard', array(
					'animal-spawn-limit': 20,
					'ticks-per-animal-spawns': 20,
				));
				@respawnPlayers = (@rules['objective'] == 'treasurehunt' || @rules['objective'] == 'scavengerhunt' || @rules['objective'] == 'creative');
				if(!@respawnPlayers && @rules['buffertime'] && @rules['timelimit']) {
					set_timeout(@rules['buffertime'], closure(){
						if(array_contains(get_worlds(), 'shard')) {
							set_world_border('shard', array('width': 1, 'seconds': @rules['timelimit'] * 60));
							_worldmsg('shard', color('red').color('bold').'Shard has started to collapse! ('.@rules['timelimit'].' minutes)');
						}
					});
				}
				@game = array(
					'respawnPlayers': @respawnPlayers,
					'rules': @rules,
					'lateJoin': true,
					'inv': if(array_index_exists(@rules, 'mirrored') && @rules['mirrored'], pinv(), null),
				);
				export('shard', @game);

				// Start game
				if(array_contains(get_scoreboards(), 'shard')) {
					// Leftover junk. Probably caused by a bug.
					console('Cleaning up old scoreboard for shard.', false);
					remove_scoreboard('shard');
				}
				create_scoreboard('shard');
				create_objective('rules', 'DUMMY', 'shard');
				foreach(@rule: @value in @rules) {
					if(@rule != 'objective' && @value) {
						set_pscore('rules', to_upper(@rule[0]).@rule[1..], integer(@value), 'shard');
					}
				}
				set_objective_display('rules', array(
					displayname: color('bold').color('aqua').to_upper(@rules['objective'][0]).@rules['objective'][1..],
					slot: 'SIDEBAR'
				), 'shard');
				set_timeout(60 * 1000, closure() {
					try(set_objective_display('rules', array(slot: null), 'shard'));
				});
				_add_activity('shard', @worldname.'//Shard');

				// Default procedures (overrideable)
				include_dir('../rules.library');
				proc _set_inventory_contents(@loc, @count, @player) {
					// Clear all inventory
					if(has_metadata(@loc, 'loot')) {
						return();
					}

					@size = get_inventory_size(@loc);
					@inv = array();
					array_resize(@inv, @size);
					set_inventory(@loc, @inv);
					set_metadata(@loc, 'loot', 1);
				}

				// Load objective and rule scripts
				@binds = array();
				@game['binds'] = @binds;
				foreach(@rule: @value in @rules) {
					if(@rule == 'objective' && file_exists('../objectives.library/'.@value.'.ms')) {
						// games only have one objective, but we need to statically include all of them first
						include_dir('../objectives.library');
						// now we make sure the current objective is last before calling _objective_load
						include('../objectives.library/'.@value.'.ms');
						_objective_load(@binds, @rules);
					} else if(@value && file_exists('../rules.library/'.@rule.'.ms')) {
						include('../rules.library/'.@rule.'.ms');
						_rule_load(@binds, @value);
					}
				}

				// Teleport players
				@loc['y'] -= 1;
				foreach(@p in @players) {
					queue_push(closure(){
						if(_world_group(pworld(@p)) != @worldgroup) {
							return();
						}
						@ploc = ploc(@p);
						play_sound(@ploc, array('sound': 'BLOCK_AMETHYST_CLUSTER_BREAK', 'pitch': 0.5));
						@ploc['world'] = 'shard';
						@airDrop = false;
						if(array_index_exists(@rules, 'randomspawn') && @rules['randomspawn']
						|| @ploc['x'] < @minX
						|| @ploc['x'] > @maxX
						|| @ploc['z'] < @minZ
						|| @ploc['z'] > @maxZ) {
							if(@rules['objective'] == 'scavengerhunt' || !@rules['keep']) {
								@ploc = _get_spawn_location(0);
								@ploc['y'] += 128;
								@airDrop = true;
							} else {
								@ploc = _get_spawn_location();
							}
						}
						if(set_ploc(@p, @ploc)) {
							if(@rules['objective'] == 'creative') {
								set_pmode(@p, 'CREATIVE');
							}
							if(@game['inv']) {
								set_pinv(@p, @game['inv']);
							} else if(!array_index_exists(@rules, 'keep') || !@rules['keep']) {
								_clear_pinv(@p);
							}
							if(@airDrop) {
								pgive_item(@p, array('name': 'ELYTRA', 'meta': array('damage': 402)));
								set_peffect(@p, 'LEVITATION', -4, 15);
								bind('entity_toggle_glide', null, array('type': 'PLAYER', 'player': @p), @event) {
									set_peffect(player(), 'LEVITATION', 0, 0);
									unbind();
								}
							}
							set_plevel(@p, 0);
							set_peffect(@p, 'RESISTANCE', 3, 30, true);
							set_pscoreboard(@p, 'shard');
							play_sound(@ploc, array('sound': 'BLOCK_AMETHYST_CLUSTER_BREAK', 'pitch': 0.5), @p);
							play_sound(@ploc, array('sound': 'ENTITY_WITHER_SPAWN', 'pitch': 0.7), @p);
						}
					}, 'shard');
				}

				proc _check_shard(@willRespawnPlayers = @respawnPlayers) {
					queue_push(closure(){
						@count = 0;
						@last = '';
						if(get_teams('shard')) {
							@left = array();
							foreach(@p in all_players()) {
								if(pworld(@p) == 'shard' && pmode(@p) != 'SPECTATOR') {
									try {
										@team = get_pteam(@p, 'shard')['name'];
										if(!array_contains(@left, @team)) {
											@left[] = @team;
											@count++;
											@last = 'Team '.@team;
										}
									} catch(CastException @ex) {
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
						if(@count == 1 && !@willRespawnPlayers) {
							set_world_border('shard', array('width': 1, 'seconds': 20));
							storm(true, 'shard');
							set_thunder(true, 'shard');
							_worldmsg('shard', color('green').@last.' wins!');
							set_timeout(20000, closure(){
								if(array_contains(get_worlds(), 'shard') && ponline(@last) && pworld(@last) == 'shard') {
									explosion(location_shift(ploc(@last), 'up', 2), 5);
								}
							});
						} else if(@count == 0) {
							_unload_shard();
						}
					}, 'shard');
				}

				// Events
				@binds[] = 'shard-quit';
				bind('player_quit', array('priority': 'HIGHEST', 'id': 'shard-quit'), null, @event) {
					if(pworld() == 'shard') {
						@loc = get_spawn('custom');
						@loc['y'] -= 1;
						set_ploc(@loc);
						_check_shard();
					}
				}

				@binds[] = 'shard-death';
				bind('player_death', array('priority': 'HIGHEST', 'id': 'shard-death'), null, @event, @players, @rules, @respawnPlayers) {
					if(@event['location']['world'] == 'shard') {
						consume();
						if(!@respawnPlayers) {
							modify_event('death_message', color('k').'X'.color('r').' '.@event['death_message']);
							@loc = ploc();
							if(@loc['y'] < 0) {
								@loc['y'] = 0;
							}
							export('playerspawn', @loc);
							set_pmode('SPECTATOR');
							if(@rules['timelimit'] && !@rules['buffertime'] && get_world_border('shard')['width'] == @rules['width']) {
								set_world_border('shard', array('width': 1, 'seconds': @rules['timelimit'] * 60));
								_worldmsg('shard', color('red').color('bold').'Shard has started to collapse! ('.@rules['timelimit'].' minutes)');
							}
							@game = import('shard');
							@game['lateJoin'] = false;
						} else {
							modify_event('death_message', null);
							modify_event('keep_inventory', true);
						}
						set_timeout(50, closure(){
							respawn();
						});
					}
				}

				@binds[] = 'shard-spawn';
				bind('player_spawn', array('id': 'shard-spawn', 'priority': 'LOWEST'), array('world': 'shard'), @event) {
					modify_event('location', import('playerspawn', _get_spawn_location()));
					_check_shard();
					export('playerspawn', null);
				}

				bind('world_changed', array('id': 'shard-worldchanged'), array('from': 'shard'), @event) {
					_check_shard();
				}

				@binds[] = 'shard-interact';
				bind('player_interact', array('id': 'shard-interact'), null, @event) {
					if(@event['block'] && pworld() == 'shard') {
						switch(@event['block']) {
							case 'BLAST_FURANCE':
							case 'COOKER':
							case 'DISPENSER':
							case 'FURNACE':
							case 'BREWING_STAND':
							case 'HOPPER':
							case 'DROPPER':
								_set_inventory_contents(@event['location'], 0);
							case 'BARREL':
							case 'CHEST':
							case 'TRAPPED_CHEST':
								@luck = 0;
								@effects = get_peffect();
								if(array_index_exists(@effects, 'luck')) {
									@luck += @effects['luck']['strength'] + 1;
								}
								if(array_index_exists(@effects, 'bad_luck')) {
									@luck -= @effects['bad_luck']['strength'] + 1;
								}
								_set_inventory_contents(@event['location'], 3 + @luck);
							default:
								if(string_ends_with(@event['block'], 'SHULKER_BOX')) {
									_set_inventory_contents(@event['location'], 0);
								}
						}
					}
				}

				@binds[] = 'shard-place1';
				bind('block_place', array('id': 'shard-place1'), array('block': 'CHEST'), @event) {
					_set_inventory_contents(@event['location'], 0);
				}

				@binds[] = 'shard-place2';
				bind('block_place', array('id': 'shard-place2'), array('block': 'TRAPPED_CHEST'), @event) {
					_set_inventory_contents(@event['location'], 0);
				}

				@binds[] = 'shard-explosion';
				bind('entity_explode', array('id': 'shard-explosion'), null, @event) {
					if(@event['location']['world'] == 'shard') {
						foreach(@block in @event['blocks']) {
							switch(get_block(@block)) {
								case 'BLAST_FURNACE':
								case 'COOKER':
								case 'DISPENSER':
								case 'FURNACE':
								case 'BREWING_STAND':
								case 'HOPPER':
								case 'DROPPER':
									@inv = array();
									array_resize(@inv, get_inventory_size(@block));
									set_inventory(@block, @inv);
								case 'BARREL':
								case 'CHEST':
								case 'TRAPPED_CHEST':
									_set_inventory_contents(@block, 3);
							}
						}
					}
				}

			});
		});
	});
}

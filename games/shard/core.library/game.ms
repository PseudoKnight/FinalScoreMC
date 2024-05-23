proc _shard_create(@rules){
	@start = time();
	// Get players
	@world = pworld();
	@worldgroup = _world_group(@world);
	@worldname = _world_name(@world);
	@players = array();
	foreach(@p in all_players()) {
		if(_world_group(pworld(@p)) != @worldgroup) {
			continue();
		}
		@item = pinv(@p, null);
		if(@p == player() || @item && @item['name'] == 'ECHO_SHARD') {
			@players[] = @p;
			@ploc = ploc(@p);
			play_sound(@ploc, array(sound: 'ENTITY_GUARDIAN_ATTACK'), @p);
		}
	}
	if(array_size(@players) < 2 && @rules['objective'] != 'creative' && @rules['objective'] != 'scavengerhunt') {
		set_timeout(1800, closure(){
			action_msg(color('red').'Not enough players to generate a shard!');
			play_sound(ploc(), array(sound: 'BLOCK_FIRE_EXTINGUISH', volume: 0.5), player());
		});
		die();
	}

	// Remove existing region files
	if(extension_exists('CHDynmap')) {
		dm_set_update_renders_paused(true);
	}
	@base = '../../../../../../worlds'; // relative to script location
	try {
		foreach(@file in list_files("@base/shard/region")) {
			if(string_starts_with(@file, 'r.')) { // 
				delete_file("@base/shard/region/@file");
			}
		}
		foreach(@file in list_files("@base/shard/entities")) {
			if(string_starts_with(@file, 'r.')) { // 
				delete_file("@base/shard/entities/@file");
			}
		}
		foreach(@file in list_files("@base/shard/poi")) {
			if(string_starts_with(@file, 'r.')) { // 
				delete_file("@base/shard/poi/@file");
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
			action_msg(color('red').'Failed to create Shard!');
			play_sound(ploc(), array(sound: 'BLOCK_FIRE_EXTINGUISH', volume: 0.5));
			die();
		}
		@stop = time();
		console('Copy region files ('.(@stop - @start).'ms)', false);

		set_timeout(50, closure(){
			// Create shard
			@start = time();
			_create_world('shard', array(
				name: @worldname.'//Shard',
				mode: 'SURVIVAL',
				group: 'shard',
				teleports: true,
				environment: 'NORMAL',
				seed: null,
				generator: 'CleanroomGenerator:.',
				difficulty: 'HARD',
			));
			@stop = time();
			console('Created shard ('.(@stop - @start).'ms)', false);

			set_timeout(150, closure(){

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
					dm_create_marker('markers', array(
						type: 'AREA',
						world: @world,
						label: 'Shard',
						id: 'shard',
						corners: array(
							array(@minX, 0, @minZ, @world),
							array(@maxX, 0, @minZ, @world),
							array(@maxX, 0, @maxZ, @world),
							array(@minX, 0, @maxZ, @world),
						),
					));
					dm_set_marker_line_style('markers', 'shard', array(
						color: array(r: 255, g: 0, b: 0),
						opacity: 1,
						weight: 1,
					));
					dm_set_marker_fill_style('markers', 'shard', array(
						color: array(r: 255, g: 0, b: 0),
						opacity: 0.1,
					));
					dm_set_update_renders_paused(false);
				}

				// Set world settings
				set_spawn(@loc);
				set_world_time('shard', get_world_time(@world));
				storm(false, 'shard');
				set_world_border('shard', array(width: @rules['width'], center: @loc));
				set_gamerule('shard', 'NATURALREGENERATION', !array_index_exists(@rules, 'regen') || !@rules['noregen']);
				set_spawning('shard', array(
					'animal-spawn-limit': 20,
					'ticks-per-animal-spawns': 20,
				));
				@respawnPlayers = (@rules['objective'] == 'treasurehunt' || @rules['objective'] == 'scavengerhunt' || @rules['objective'] == 'creative');
				if(!@respawnPlayers && @rules['buffertime'] && @rules['timelimit'] && @rules['objective'] != 'scavengerhunt') {
					set_timeout(@rules['buffertime'], closure(){
						if(array_contains(get_worlds(), 'shard')) {
							set_world_border('shard', array(width: 1, seconds: @rules['timelimit'] * 60));
							broadcast(color('red').color('bold').'Shard has started to collapse! ('.@rules['timelimit'].' minutes)', all_players('shard'));
						}
					});
				}
				@game = array(
					respawnPlayers: @respawnPlayers,
					rules: @rules,
					lateJoin: true,
					inv: if(array_index_exists(@rules, 'mirrored') && @rules['mirrored'], pinv(), null),
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
					try(set_objective_display('rules', array(slot: null), 'shard'))
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
						play_sound(@ploc, array(sound: 'BLOCK_AMETHYST_CLUSTER_BREAK', pitch: 0.5));
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
								clear_pinv(@p);
							}
							if(@airDrop) {
								pgive_item(@p, array(name: 'ELYTRA', meta: array(damage: 402)));
								set_peffect(@p, 'SLOW_FALLING', 1, 60);
								queue_push(closure(){
									bind('player_armor_change', null, array(player: @p), @event) {
										set_peffect(player(), 'SLOW_FALLING', 0, 0);
										unbind();
									}
								}, 'shard');
							}
							set_plevel(@p, 0);
							set_peffect(@p, 'RESISTANCE', 3, 30, true);
							set_pscoreboard(@p, 'shard');
							play_sound(@ploc, array(sound: 'BLOCK_AMETHYST_CLUSTER_BREAK', pitch: 0.5), @p);
							play_sound(@ploc, array(sound: 'ENTITY_WITHER_SPAWN', pitch: 0.7), @p);
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
							set_world_border('shard', array(width: 1, seconds: 20));
							storm(true, 'shard');
							set_thunder(true, 'shard');
							broadcast(color('green').@last.' wins!', all_players('shard'));
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
				@binds[] = bind('player_quit', array(priority: 'HIGHEST', id: 'shard-quit'), null, @event) {
					if(pworld() == 'shard') {
						@loc = get_spawn('custom');
						@loc['y'] -= 1;
						set_ploc(@loc);
						_check_shard();
					}
				}

				@binds[] = bind('player_death', array(priority: 'HIGHEST', id: 'shard-death'), null, @event, @players, @rules, @respawnPlayers) {
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
							if(@rules['timelimit'] 
							&& !@rules['buffertime'] 
							&& @rules['objective'] != 'scavengerhunt'
							&& get_world_border('shard')['width'] == @rules['width']) {
								set_world_border('shard', array(width: 1, seconds: @rules['timelimit'] * 60));
								broadcast(color('red').color('bold').'Shard has started to collapse! ('.@rules['timelimit'].' minutes)', all_players('shard'));
							}
							@game = import('shard');
							@game['lateJoin'] = false;
						} else {
							modify_event('death_message', null);
							modify_event('keep_inventory', true);
						}
						set_timeout(50, closure(){
							pforce_respawn();
						});
					}
				}

				@binds[] = bind('player_spawn', array(id: 'shard-spawn', priority: 'LOWEST'), array(location: array(world: 'shard')), @event) {
					@respawnLocation = import('playerspawn');
					if(!@respawnLocation) {
						@respawnLocation = _get_spawn_location();
					}
					modify_event('location', @respawnLocation);
					_check_shard();
					export('playerspawn', null);
				}

				// special-case, do not add to @binds
				bind('world_changed', array(id: 'shard-worldchanged'), array(from: 'shard'), @event) {
					_check_shard();
				}

				@binds[] = bind('player_interact', array(id: 'shard-interact'), null, @event) {
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
							case 'DECORATED_POT':
								_set_inventory_contents(@event['location'], 1);
							default:
								if(string_ends_with(@event['block'], 'SHULKER_BOX')) {
									_set_inventory_contents(@event['location'], 0);
								}
						}
					}
				}

				@binds[] = bind('block_place', array(id: 'shard-chest'), array(block: 'CHEST'), @event) {
					_set_inventory_contents(@event['location'], 0);
				}

				@binds[] = bind('block_place', array(id: 'shard-trapped-chest'), array(block: 'TRAPPED_CHEST'), @event) {
					_set_inventory_contents(@event['location'], 0);
				}

				@binds[] = bind('block_place', array(id: 'shard-barrel'), array(block: 'BARREL'), @event) {
					_set_inventory_contents(@event['location'], 0);
				}

				@binds[] = bind('block_place', array(id: 'shard-decorated-pot'), array(block: 'DECORATED_POT'), @event) {
					_set_inventory_contents(@event['location'], 0);
				}

				@binds[] = bind('entity_explode', array(id: 'shard-explosion'), null, @event) {
					if(@event['location']['world'] == 'shard') {
						foreach(@block in @event['blocks']) {
							@type = get_block(@block);
							switch(@type) {
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
								case 'DECORATED_POT':
									_set_inventory_contents(@block, 1);
								default:
									if(string_ends_with(@type, 'SHULKER_BOX')) {
										@inv = array();
										array_resize(@inv, get_inventory_size(@block));
										set_inventory(@block, @inv);
									}
							}
						}
					}
				}

				// Bypass survival worldborder suffocation protection
				@binds[] = bind('entity_damage', array(priority: 'HIGHEST'), array(world: 'shard', type: 'PLAYER', cause: 'WORLD_BORDER'), @event) {
					consume();
				}
			});
		});
	});
}

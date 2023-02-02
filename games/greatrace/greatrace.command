<!
	description: Players race to the target location. First there wins.
	Teleports disqualifies players. Horses/Minecarts/Potions/Elytra are not blocked.;

	requiredProcs: _add_activity() and _remove_activity() procedures to keep a list of all current activities on server.
	As well as _get_worldborder() to get the limits of the world.
>
register_command('greatrace', array(
	description: 'Creates a race in survival for all players in the area.',
	usage: '/greatrace [radius | x z]',
	tabcompleter: closure(return(array())),
	executor: closure(@alias, @sender, @args, @info) {
		// Get players
		@start = ploc();
		@world = @start['world'];
		@players = players_in_radius(@start, 24);
		if(array_size(@players) < 1 && !pisop()) {
			die(color('gold').'Not enough players within 24 blocks.');
		}

		// Get target locations
		@targets = array();
		@worldExtent = _get_world_extent(@world, 8);
		if(array_size(@args) < 2) {
			@radius = array_get(@args, 0, 512);
			do {
				@x = @start['x'] - @radius + @radius * 2 * rand();
				@z = @start['z'] - @radius + @radius * 2 * rand();
				if(@x > @worldExtent['xMin'] && @x < @worldExtent['xMax']
				&& @z > @worldExtent['zMin'] && @z < @worldExtent['zMax']) {
					@targets[] = get_highest_block_at(@x, @z, @world);
				}
			} while(array_size(@targets) < 2 || rand(2))
		} else if(array_size(@args) == 2) {
			@x = integer(@args[0]);
			@z = integer(@args[1]);
			if(@x > @worldExtent['xMin'] && @x < @worldExtent['xMax']
			&& @z > @worldExtent['zMin'] && @z < @worldExtent['zMax']) {
				@targets[] = get_highest_block_at(@x, @z, @world);
			} else {
				die(color('gold').'Coordinates outside world extent.');
			}
		} else {
			return(false);
		}

		// Setup scoreboard
		create_scoreboard('greatrace');
		create_objective('distance', 'DUMMY', 'greatrace');
		create_objective('target', 'DUMMY', 'greatrace');
		set_objective_display('distance', array(slot: 'SIDEBAR', displayname: color('b').'Distance'), 'greatrace');
		foreach(@p in @players) {
			set_pscoreboard(@p, 'greatrace');
		}

		_add_activity('greatrace', 'The Great Race');

		proc _end_race() {
			_remove_activity('greatrace');
			unbind('greatrace');
			remove_scoreboard('greatrace');
		}

		@timer = array(10);
		set_interval(500, closure(){
			foreach(@index: @p in @players) {
				if(!ponline(@p) || pworld(@p) != @world || phealth(@p) == 0) {
					array_remove(@players, @index);
				}
			}

			if(array_size(@players) == 0 || array_size(@players) == 1 && !pisop(@players[0])) {
				tmsg(array_get(@players, 0, '~console'), 'All players left the race.');
				_end_race();
				clear_task();

			} else if(@timer[0] > -1) {
				// Counting down to start
				foreach(@index: @p in @players) {
					@l = ploc(@p);
					@dist = distance(@l, @start);
					if(@dist > 24) {
						array_remove(@players, @index);
					} else if(@timer[0]) {
						title(@p, ceil(@timer[0] / 2), 'The Great Race', 0, 20, 0);
					} else {
						title(@p, 'GO!', 'The Great Race', 0, 40, 20);
						play_sound(@l, array(sound: 'ENTITY_FIREWORK_ROCKET_BLAST_FAR'), @p);
					}
				}
				@timer[0] -= 1;

			} else {
				// Racing to target
				foreach(@p in @players) {
					@ploc = location_shift(ploc(@p), 'up', 1.5);
					@targetIndex = get_pscore('target', @p, 'greatrace');
					@targetLoc = @targets[@targetIndex];
					@dist = distance(@ploc, @targetLoc);
					if(@dist > 8) {
						set_pscore('distance', @p, integer(@dist), 'greatrace');
						if(@dist < 96) {
							for(@i = 0, @i < 5, @i++) {
								@vector = get_vector(array(0, 0, 0, @world, rand(360), 0), 8);
								@point = array(
									@targetLoc['x'] + @vector['x'],
									@targetLoc['y'] + 1.2,
									@targetLoc['z'] + @vector['z'],
									@world,
								);
								spawn_particle(@point, 'CAMPFIRE_SIGNAL_SMOKE', @p);
							}
						}
						if(@dist > 18) {
							spawn_particle(@ploc, array(particle: 'VIBRATION', destination: location_shift(@ploc, @targetLoc, 16)), @p);
						}
					} else if(@targetIndex + 1 < array_size(@targets)) {
						// Player reached target, so select the next target.
						set_pscore('target', @p, @targetIndex + 1, 'greatrace');
						play_sound(@ploc, array(sound: 'ENTITY_ARROW_HIT_PLAYER'), @p);
					} else {
						// Winner!
						launch_firework(location_shift(@ploc, 'up', 2));
						broadcast(@p.' won the Great Race!', all_players(@world));
						_end_race();
						clear_task();
						break();
					}
				}
			}
		});

		bind('player_teleport', array(id: 'greatrace'), null, @event, @players) {
			if(array_contains(@players, player())) {
				@dist = distance(@event['from'], @event['to']);
				if(@dist > 8) {
					array_remove_values(@players, player());
					msg('You have been disqualified for teleporting.');
					broadcast(player().' has been disqualified for teleporting.', @players);
				}
			}
		}
	}
));

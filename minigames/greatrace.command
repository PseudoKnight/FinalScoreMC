/*
	The Great Race
	Players sprint and/or ride to the target location. First there wins.
	NO teleports. Horses/Minecarts/Potions are allowed.

	DEPENDENCIES:
	- CHNaughty extension for action_msg()
*/
register_command('greatrace', array(
	'description': 'Creates a race in survival for all players in the area.',
	'usage': '/greatrace [x] [z]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		@world = pworld();

		# Get players
		@start = ploc();
		@players = players_in_radius(@start, 32);
		if(array_size(@players) < 1) {
			die(color('gold').'Not enough players within 32 blocks.');
		}

		# Get target location
		if(!@args) {
			@worlds = null;
			try {
				@worlds = yml_decode(read('../../../WorldBorder/config.yml'))['worlds'];
			} catch(IOException @ex) {
				// WorldBorder plugin doesn't exist
			}
			@x = 0;
			@z = 0;
			if(@worlds && array_index_exists(@worlds, @world)) {
				@border = @worlds[@world];
				@x = @border['x'] - @border['radiusX'] + rand(@border['radiusX'] * 2);
				@z = @border['z'] - @border['radiusZ'] + rand(@border['radiusZ'] * 2);
			} else {
				@width = min(8192, integer(get_world_border(@world)['width']));
				@x += rand(@width) - @width / 2;
				@z += rand(@width) - @width / 2;
			}
			@target = get_highest_block_at(@x, @z, @world);
		} else if(array_size(@args) == 2) {
			@target = get_highest_block_at(@args[0], @args[1], @world);
		} else {
			return(false);
		}

		# Create an array of points in a circle around the target location
		@radius = 8;
		@circle = array();
		for(@angle = 0, @angle < 6.28, @angle += 0.4) {
			@circle[] = array(
				'x': @radius * cos(@angle) + @target['x'],
				'y': @target['y'] + 4,
				'z': @radius * sin(@angle) + @target['z'],
				'world': @world,
			);
		}

		# Setup scoreboard
		create_scoreboard('greatrace');
		create_objective('distance', 'DUMMY', 'greatrace');
		set_objective_display('distance', array('slot': 'SIDEBAR', 'displayname': color('b').'Distance'), 'greatrace');
		foreach(@p in @players) {
			set_pscoreboard(@p, 'greatrace');
		}

		# Main loop
		@timer = array(3);
		set_interval(1000, closure(){
			foreach(@index: @p in @players) {
				if(!ponline(@p) || pworld(@p) != @world || phealth(@p) == 0) {
					array_remove(@players, @index);
				}
			}

			if(array_size(@players) <= 1) {
				tmsg(array_get(@players, 0, '~console'), 'All players left the race.');
				unbind('thegreatrace');
				remove_scoreboard('greatrace');
				clear_task();

			} else if(@timer[0] > -1) {
				# COUNTDOWN
				foreach(@index: @p in @players) {
					@l = ploc(@p);
					@dist = sqrt(
						((@l['x'] - @start['x']) ** 2) +
						((@l['y'] - @start['y']) ** 2) +
						((@l['z'] - @start['z']) ** 2)
					);
					if(@dist > 32) {
						array_remove(@players, @index);
					} else if(@timer[0]) {
						title(@p, @timer[0], 'The Great Race', 0, 40, 0);
						play_sound(@l, array('sound': 'BLOCK_NOTE_BLOCK_PLING'), @p);
					} else {
						title(@p, 'GO!', 'The Great Race', 0, 40, 20);
						play_sound(@l, array('sound': 'ENTITY_FIREWORK_ROCKET_BLAST_FAR'), @p);
						set_compass_target(@p, @target);
						tmsg(@p, 'Target Location: '.@target['x'].' / '.@target['y'].' / '.@target['z']);
					}
				}
				@timer[0] -= 1;

			} else {
				#RACE
				foreach(@p in @players) {
					@l = ploc(@p);
					@dist = sqrt(
						((@l['x'] - @target['x']) ** 2) +
						((@l['y'] - @target['y']) ** 2) +
						((@l['z'] - @target['z']) ** 2)
					);
					if(@dist > @radius) {
						action_msg(@p, 'Distance to target: '.floor(@dist).'m');
						set_pscore('distance', @p, integer(@dist), 'greatrace');
						if(@dist < 96) {
							foreach(@point in @circle) {
								spawn_particle(@point, 'FIREWORKS_SPARK', @players);
							}
						}

					} else {
						# WINNER!
						@l['y'] += 2;
						launch_firework(@l);
						broadcast(@p.' won The Great Race!', all_players(@world));
						unbind('thegreatrace');
						remove_scoreboard('greatrace');
						clear_task();
						break();
					}
				}
			}
		});

		bind('player_teleport', array('id': 'thegreatrace'), null, @e, @players) {
			if(array_contains(@players, @e['player'])) {
				@dist = sqrt(
					((@e['from']['x'] - @e['to']['x']) ** 2) +
					((@e['from']['y'] - @e['to']['y']) ** 2) +
					((@e['from']['z'] - @e['to']['z']) ** 2)
				);
				if(@dist > 8) {
					array_remove_values(@players, @e['player']);
					msg('You\'ve been disqualified for teleporting.');
					broadcast(@e['player'].' has been disqualified for teleporting.', @players);
				}
			}
		}
	}
));

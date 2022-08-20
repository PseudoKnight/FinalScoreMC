<!
	description: 	Stairway creates a stairway of randomly placed blocks to heaven (world height).
	Records are stored for how high the player made it.;

	requiredExtensions: SKCompat;
	requiredProcs: _acc_add() proc for rewarding players who reach the top.
		_add_activity() and _remove_activity() procedures to keep a list of all current activities on server.;
>
register_command('stairway', array(
	description: 'Starts a randomly generated block stairway in the region.',
	usage: '/stairway <player>',
	permission: 'command.stairway',
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = _get_nearby_player(get_command_block(), 3);
		if(!array_contains(sk_current_regions(@player), 'stairway')) {
			die();
		}
		@players = import('stairway');
		if(is_null(@players)) {
			@players = associative_array();
		} else if(array_index_exists(@players, @player)) {
			die();
		}
		_add_activity(@player.'stairway', @player.' on Stairway');
		if(array_size(@players) == 0) {
			@players[@player] = 'WHITE';
			runas('~console', '/jukebox music @stairway http://finalscoremc.com/media/stairway.mp3 {volume:30,fadeDuration:2}');
		} else {
			@players[@player] = array_get_rand(reflect_pull('enum', 'DyeColor'));
		}
		runas('~console', '/jukebox show add '.@player.' @stairway');
		@loc = get_command_block();
		@startY = integer(@loc['y'] + 2);
		@loc = array(floor(@loc[0] + 1), floor(@loc[1] + 2), floor(@loc[2]), @loc[3]);
		set_block(@loc, @players[@player].'_STAINED_GLASS', false);
		set_pbed_location(@player, @loc, true);
		@oldLocs = array();
		export('stairway', @players);
		
		proc _stairway_end(@player, @height) {
			clear_task();
			@players = import('stairway');
			array_remove(@players, @player);
			export('stairway', @players);
			if(!@players) {
				if(@height == 256) {
					runas('~console', '/jukebox stop music @stairway {fadeDuration:10}');
				} else if(!ponline(@player) || phealth(@player) == 0) {
					runas('~console', '/jukebox sound @stairway http://finalscoremc.com/media/record_scratch.ogg {volume:20}');
					runas('~console', '/jukebox stop music @stairway');
				} else {
					runas('~console', '/jukebox stop music @stairway {fadeDuration:3}');
				}
			}
			_remove_activity(@player.'stairway');
			if(!ponline(@player)) {
				return();
			}
			@complete = get_value('stairway');
			if(!@complete) {
				@complete = associative_array();
			}
			@uuid = puuid(@player);
			@oldHeight = 65;
			if(array_index_exists(@complete, @uuid)) {
				@oldHeight = @complete[@uuid];
			}
			if(@height > @oldHeight) {
				@complete[@uuid] = @height;
				store_value('stairway', @complete);
				if(@height == 256) {
					title(@player, color('gold').'+ 256 coins', '');
					_acc_add(@player, 256);
				} else {
					title(@player, '', color('green').'Closer!');
				}
			}
		}
		
		proc _remove_old_blocks(@locations) {
			foreach(@index: @loc in @locations) {
				set_block(@loc, 'AIR', false);
				array_remove(@locations, @index);
			}
		}

		@records = get_value('stairway') ||| associative_array();
		@stairs = associative_array();
		foreach(@uuid: @record in @records) {
			if(!array_index_exists(@stairs, @record)) {
				@stairs[@record] = array();
			}
			@stairs[@record][] = @uuid;
		}

		set_interval(500, closure(){
			if(!ponline(@player) || !array_contains(sk_current_regions(@player), 'stairway')) {
				_remove_old_blocks(@oldLocs);
				set_block(@loc, 'AIR');
				_stairway_end(@player, @loc[1]);
				die();
			}
			@ploc = ploc(@player);
			if(string_ends_with(get_block(@ploc), '_STAINED_GLASS') && @ploc[1] >= @loc[1] && @loc[1] < 255) {
				_remove_old_blocks(@oldLocs);
				@oldLocs[] = @loc[];

				@passing = '';
				@passingUUID = '';

				// do small path
				@maxLength = 10;
				@skull = false;
				do {
					@newLoc = @loc[];
					@newLoc[rand(2) * 2] += rand(2) * 2 - 1;
					if(array_contains(sk_regions_at(@newLoc), 'stairway')
					&& get_block(@newLoc) == 'AIR') {
						set_block(@newLoc, @players[@player].'_STAINED_GLASS', false);
						@oldLocs[] = @newLoc[];
						@loc[0] = @newLoc[0];
						@loc[1] = @newLoc[1];
						@loc[2] = @newLoc[2];
						if(!@skull && array_index_exists(@stairs, @loc[1])) {
							@skull = true;
							try {
								@passingUUID = array_get_rand(@stairs[@loc[1]]);
								@pdata = _pdata_by_uuid(replace(@passingUUID, '-', ''));
								@passing = @pdata['name'];
								@skullLoc = location_shift(@newLoc, 'up');
								@rotation = integer(get_yaw(@ploc, @newLoc) / 22.5);
								set_blockdata(@skullLoc, array('block': 'player_head', 'rotation': @rotation), false);
								set_skull_owner(@skullLoc, @passingUUID);
								@oldLocs[] = @skullLoc;
							} catch (NotFoundException @ex) {
								console(@ex['message']);
							}
						}
					} else {
						break();
					}
				} while(@maxLength-- > 0);
				
				// do jump
				@max = rand(3,5); // reduce chance of max jump length
				@attempts = 20;
				do {
					@newLoc = @loc[];
					@distA = rand(-@max, @max + 1);
					@coord = rand(2) * 2;
					@newLoc[@coord] += @distA;
					@newLoc[1] += 1;
					@distB = (4 - abs(@distA)) * rand(-1, 2);
					if(@coord == 0) {
						@newLoc[2] += @distB;
					} else {
						@newLoc[0] += @distB;
					}
					if((@distA || @distB) && array_contains(sk_regions_at(@newLoc), 'stairway')) {
						@loc[0] = @newLoc[0];
						@loc[1] = @newLoc[1];
						@loc[2] = @newLoc[2];
						break();
					}
				} while(@attempts-- > 0);
				set_block(@loc, @players[@player].'_STAINED_GLASS', false);
				title(@player, integer(@loc[1]) - @startY, if(@passing, 'Passing '.@passing));
			} else if(@oldLocs && @ploc['y'] < @startY) {
				_remove_old_blocks(@oldLocs);
				set_block(@loc, 'AIR');
				_stairway_end(@player, @loc[1]);
			} else if(@ploc['y'] > 254) {
				_stairway_end(@player, 256);
				set_timeout(3000, closure(){
					_remove_old_blocks(@oldLocs);
					set_block(@loc, 'AIR');
				});
			}
		});
	}
));

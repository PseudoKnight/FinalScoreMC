/*
	Stairway creates a stairway of randomly placed blocks to heaven (world height).
	Records are stored for how high the player made it.
	
	DEPENDENCIES:
	- MCJukeBox plugin to play music while the player climbs. Remove runas() functions if you do not need this.
	- WorldGuard plugin and SKCompat extension for region detection.
	- _acc_add() proc for rewarding players who reach the top.
*/
register_command('stairway', array(
	'description': 'Starts a randomly generated block stairway in the region.',
	'usage': '/stairway <player>',
	'permission': 'command.stairway',
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@player = @args[0];
		if(!array_contains(sk_current_regions(@player), 'stairway')) {
			die();
		}
		@players = import('stairway');
		if(is_null(@players)) {
			@players = associative_array();
		} else if(array_index_exists(@players, @player)) {
			die();
		}
		if(array_size(@players) == 0) {
			@players[@player] = 0;
			runas('~console', '/jukebox music @stairway http://finalscoremc.com/media/stairway.mp3 {volume:30,fadeDuration:2}');
		} else {
			@players[@player] = rand(16);
		}
		runas('~console', '/jukebox show add '.@player.' @stairway');
		@ploc = ploc(@player);
		@startY = @ploc['y'] + 1;
		@loc = array(floor(@ploc[0]), floor(@ploc[1]), floor(@ploc[2]), @ploc[3]);
		@startY = integer(@ploc[1] + 1);
		@loc[0]++;
		@loc[1]++;
		set_block_at(@loc, '95:'.@players[@player]);
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
				} else {
					runas('~console', '/jukebox sound @stairway http://finalscoremc.com/media/record_scratch.ogg {volume:20}');
					runas('~console', '/jukebox stop music @stairway');
				}
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
				if(ponline(@player)) {
					if(@height == 256) {
						title(@player, color('gold').'+ 256 coins', '');
						_acc_add(@player, 256);
					} else {
						title(@player, '', color('green').'Closer!');
					}
				}
			}
		}
		
		proc _remove_old_blocks(@locations) {
			foreach(@index: @loc in @locations) {
				set_block_at(@loc, 0, false);
				array_remove(@locations, @index);
			}
		}
		
		set_interval(500, closure(){
			if(!ponline(@player) || !array_contains(sk_current_regions(@player), 'stairway')) {
				_remove_old_blocks(@oldLocs);
				set_block_at(@loc, 0);
				_stairway_end(@player, @loc[1]);
				die();
			}
			@ploc = ploc(@player);
			if(split(':', get_block_at(@ploc))[0] == '95' && @ploc[1] >= @loc[1] && @loc[1] < 255) {
				_remove_old_blocks(@oldLocs);
				@oldLocs[] = @loc[];
				
				// do small path
				@maxLength = 10;
				do {
					@newLoc = @loc[];
					@newLoc[rand(2) * 2] += rand(2) * 2 - 1;
					if(array_contains(sk_regions_at(@newLoc), 'stairway')
					&& get_block_at(@newLoc) == '0:0') {
						set_block_at(@newLoc, '95:'.@players[@player], false);
						@oldLocs[] = @newLoc[];
						@loc[0] = @newLoc[0];
						@loc[1] = @newLoc[1];
						@loc[2] = @newLoc[2];
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
					if(array_contains(sk_regions_at(@newLoc), 'stairway')) {
						@loc[0] = @newLoc[0];
						@loc[1] = @newLoc[1];
						@loc[2] = @newLoc[2];
						break();
					}
				} while(@attempts-- > 0);
				set_block_at(@loc, '95:'.@players[@player]);
				title(@player, '', integer(@loc[1]) - @startY);
			} else if(@oldLocs && @ploc['y'] < @startY) {
				_remove_old_blocks(@oldLocs);
				set_block_at(@loc, 0);
				_stairway_end(@player, @loc[1]);
			} else if(@ploc['y'] > 254) {
				_stairway_end(@player, 256);
				set_timeout(3000, closure(){
					_remove_old_blocks(@oldLocs);
					set_block_at(@loc, 0);
				});
			}
		});
	}
));

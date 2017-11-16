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
		if(import('stairway') || !array_contains(sk_current_regions(@player), 'stairway')) {
			die();
		}
		runas('~console', '/jukebox show add '.@player.' @stairway');
		runas('~console', '/jukebox music @stairway http://finalscoremc.com/media/stairway.mp3 {volume:30,fadeDuration:3}');
		@ploc = ploc(@player);
		@startY = @ploc['y'] + 1;
		@loc = array(floor(@ploc[0]), floor(@ploc[1]), floor(@ploc[2]), @ploc[3]);
		@loc[0]++;
		@loc[1]++;
		set_block_at(@loc, 95);
		@oldLoc = array();
		export('stairway', true);
		
		proc _stairway_end(@player, @height) {
			clear_task();
			export('stairway', null);
			runas('~console', '/jukebox stop music @stairway {fadeDuration:6}');
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
		
		set_interval(500, closure(){
			if(!ponline(@player) || !array_contains(sk_current_regions(@player), 'stairway')) {
				if(@oldLoc) {
					set_block_at(@oldLoc, 0);
				}
				set_block_at(@loc, 0);
				_stairway_end(@player, @loc[1]);
				die();
			}
			@ploc = ploc(@player);
			if(get_block_at(@ploc) == '95:0' && @ploc[1] >= @loc[1] && @loc[1] < 255) {
				if(@oldLoc) {
					set_block_at(@oldLoc, 0);
				}
				@oldLoc[0] = @loc[0];
				@oldLoc[1] = @loc[1];
				@oldLoc[2] = @loc[2];
				@oldLoc[3] = @loc[3];
				@attempts = 20;
				@max = rand(3,5); // reduce chance of max jump length
				do {
					@newLoc = @loc[];
					@dist = rand(-@max, @max + 1);
					@coord = rand(2) * 2;
					@newLoc[@coord] += @dist;
					@newLoc[1] += 1;
					if(abs(@dist) < @max) {
						@otherDist = (@max - abs(@dist)) * rand(-1, 2);
						if(@coord == 0) {
							@newLoc[2] += @otherDist;
						} else {
							@newLoc[0] += @otherDist;
						}
					}
				} while(!array_contains(sk_regions_at(@newLoc), 'stairway') && @attempts-- > 0);
				@loc[0] = @newLoc[0];
				@loc[1] = @newLoc[1];
				@loc[2] = @newLoc[2];
				set_block_at(@loc, 95);
			} else if(@oldLoc && @ploc['y'] < @startY) {
				set_block_at(@oldLoc, 0);
				set_block_at(@loc, 0);
				_stairway_end(@player, @loc[1]);
			} else if(@ploc['y'] > 254) {
				_stairway_end(@player, 256);
				set_timeout(3000, closure(){
					set_block_at(@oldLoc, 0);
					set_block_at(@loc, 0);
				});
			}
		});
	}
));

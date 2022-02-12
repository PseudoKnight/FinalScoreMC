register_command('cubeclimber', array(
	'description': 'Starts CubeClimber games and lists/manages stats for it.',
	'usage': '/cc <start|stats|top|reset|resetstats|recalctimes> [player]',
	'aliases': array('cc'),
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('start', 'stats', 'top', 'reset', 'resetstats', 'recalctimes'), @args[-1]));
		}
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		switch(@args[0]) {
			case 'start':

				if(!sk_region_exists(pworld(), 'cubeclimber')) {
					die(color('gold').'Define the \'cubeclimber\' region first.');
				}

				if(!sk_region_exists(pworld(), 'cubeclimber_blocks')) {
					die(color('gold').'Define the \'cubeclimber_blocks\' region first.');
				}

				@count = 0;
				foreach(@p in all_players()) {
					if(array_contains(sk_current_regions(@p), 'cubeclimber')
					&& pworld(@p) == pworld()) {
						@count++;
					}
				}

				if(@count < 2) {
					die(color('gold').'You need to have at least 2 players to start CubeClimber.');
				}

				@cc = import('cubeclimber');
				if(!@cc) {
					@cc = array(
						'players': array(),
						'highest': 0,
					);
					export('cubeclimber', @cc);
					broadcast(player().colorize(' queued up a game of &7[&6Cube&cClimber&7]'), all_players(pworld()));
				} else {
					die(color('gold').'Already running.');
				}

				if(!array_contains(get_scoreboards(), 'cc')) {
					create_scoreboard('cc');
					create_objective('height', 'DUMMY', 'cc');
					set_objective_display('height', array('slot': 'SIDEBAR', 'displayname': 'Starting...'), 'cc');
					_add_activity('cubeclimber', 'CubeClimber', 'cubeclimber', pworld());
				}

				include('includes.library/cubeclimber.ms');
				_cc_start();

			case 'reset':
				if(!has_permission('cubeclimber.reset')) {
					die(color('gold').'You do not have permission.');
				}
				if(array_contains(get_scoreboards(), 'cc')) {
					remove_scoreboard('cc');
					_remove_activity('cubeclimber');
				}
				if(has_bind('cube-interact')) {
					unbind('cube-interact');
					unbind('cube-teleport');
				}
				export('cubeclimber', null);
				msg(color('green').'CubeClimber reset.');

			case 'mystats':
			case 'stats':
				@player = player();
				if(array_size(@args) > 1) {
					@player = @args[1];
				}
				@pstats = get_value('cubeclimber.player', _get_uuid(to_lower(@player)));
				if(!@pstats) {
					die(color('gold').'No statistics recorded for player '.@player);
				}
				msg(color('red').color('bold').'[ PERFORMANCE ]');
				msg(color('red').'[ '.round((@pstats[0] / @pstats[1]) * (@pstats[3] / @pstats[1]), 2).' ] '.color('r').'Avg Players Defeated');
				msg(color('red').'[ '.round((@pstats[2] / @pstats[1]), 2).' ] '.color('r').'Avg Blocks Climbed');
				if(array_index_exists(@pstats, 4)) {
					msg(color('green').color('bold').'[ PERSONAL RECORDS ]');
					msg(color('green').'[ '.@pstats[4].' ] '.color('r').'Best Time');
				}
				msg(color('yellow').color('bold').'[ STATISTICS ]');
				msg(color('yellow').'[ '.@pstats[0].' ] '.color('r').'Total Games Won');
				msg(color('yellow').'[ '.@pstats[1].' ] '.color('r').'Total Games Played');
				msg(color('yellow').'[ '.@pstats[2].' ] '.color('r').'Total Blocks Climbed');
				msg(color('yellow').'[ '.@pstats[3].' ] '.color('r').'Total Opponents Played');

			case 'top':
			case 'toptimes':
				@toptimes = get_value('cubeclimber', 'toptimes');
				if(!@toptimes) {
					die(color('gold').'No top times recorded.');
				}
				msg(color('green').color('bold').'Top Times');
				@player = 0;
				@time = 1;
				foreach(@this in @toptimes) {
					msg(color('yellow').'[ '.@this[@time].' ] '.color('r').@this[@player]);
				}

			case 'resetstats':
				if(!has_permission('cubeclimber.resetstats')) {
					die(color('gold').'You do not have permission.');
				}
				@stats = get_values('cubeclimber');
				foreach(@key in array_keys(@stats)) {
					clear_value(@key);
				}
				msg(color('green').'CubeClimber stats reset.');

			case 'resettimes':
				if(!has_permission('cubeclimber.resetstats')) {
					die(color('gold').'You do not have permission.');
				}
				@players = get_values('cubeclimber.player');
				foreach(@key: @data in @players) {
					if(array_index_exists(@data, 4)) {
						array_remove(@data, 4);
						store_value(@key, @data);
					}
				}
				store_value('cubeclimber', 'toptimes', array());
				msg(color('green').'CubeClimber times reset.');
				
			case 'recalctimes':
				if(!has_permission('cubeclimber.resetstats')) {
					die(color('gold').'You do not have permission.');
				}
				@allstats = get_values('cubeclimber');
				@toptimes = array();
				foreach(@key: @value in @allstats) {
					if(@key == 'cubeclimber.toptimes' || !array_index_exists(@value, 4)) {
						continue();
					}
					@uuid = split('.', @key)[2];
					@pdata = _pdata_by_uuid(@uuid);
					@player = @pdata['name'];
					@time = @value[4];
					@top = false;
					foreach(@i: @toptime in @toptimes) {
						if(@i > 19) {
							break();
						}
						if(@toptime[1] > @time) {
							array_insert(@toptimes, array(@player, @time), @i);
							@top = true;
							break();
						}
					}
					if(!@top && array_size(@toptimes) < 19) {
						@toptimes[] = array(@player, @time);
					} else if(array_size(@toptimes) > 19) {
						array_remove(@toptimes, 19);
					}
				}
				store_value('cubeclimber', 'toptimes', @toptimes);
				msg(color('green').'CubeClimber times recalculated.');

			case 'convert2uuid':
				if(!has_permission('cubeclimber.resetstats')) {
					die(color('gold').'You do not have permission.');
				}
				@values = get_values('cubeclimber.player');
				foreach(@key: @value in @values){
					@name = split('.', @key)[2];
					if(length(@name) > 17) {
						continue();
					}
					@uuid = _get_uuid(to_lower(@name));
					if(has_value('cubeclimber.player.'.@uuid)) {
						@previous = get_value('cubeclimber.player.'.@uuid);
						@previous[0] += @value[0];
						@previous[1] += @value[1];
						@previous[2] += @value[2];
						@previous[3] += @value[3];
						if(array_index_exists(@previous, 4) || array_index_exists(@value, 4)) {
							@previous[4] = min(array_get(@value, 4, math_const('INTEGER_MAX')), array_get(@previous, 4, math_const('INTEGER_MAX')));
						}
						store_value('cubeclimber.player.'.@uuid, @previous);
						console('Combined '.@name.' into '.@uuid);
					} else {
						store_value('cubeclimber.player.'.@uuid, @value);
						console('Saved '.@name.' into '.@uuid);
					}
					clear_value(@key);
				}

			default:
				msg(colorize('&7[&6Cube&cClimber&7] '
				.'is a minigame where the goal is to reach the top of the block tower first. '
				.'Blocks that you walk on will change to your randomly assigned color. You can '
				.'break blocks of that same color.'));
				msg('/cubeclimber start '.color(7).'Start the game.');
				msg('/cc stats '.color(7).'View your statistics.');
				msg('/cc toptimes '.color(7).'View the top times.');
		}
	}
));

register_command('cubeclimber', array(
	description: 'Starts and manages the CubeClimber game.',
	usage: '/cc <start|stats|top> [player]',
	aliases: array('cc'),
	tabcompleter: _create_tabcompleter(
		array('cubeclimber.resetstats': array('start', 'stats', 'top', 'reset', 'resetstats', 'recalctimes'),
			null: array('start', 'stats', 'top')),
		array('<stats': array('[player]')),
	),
	executor: closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@gameTitle = '&7[&6Cube&cClimber&7]&r';
		switch(@args[0]) {
			case 'start':

				if(!sk_region_exists(pworld(), 'cubeclimber')) {
					die(color('gold').'Define the cubeclimber region first.');
				}

				if(!sk_region_exists(pworld(), 'cubeclimber_blocks')) {
					die(color('gold').'Define the cubeclimber_blocks region first.');
				}

				@invitations = array();
				foreach(@p in all_players(pworld())) {
					if(!array_contains(sk_current_regions(@p), 'cubeclimber')) {
						@invitations[] = @p;
					}
				}

				_click_tell(@invitations, array(@gameTitle.' Starting... ',
						array('&b[Click to Warp]', '/warp cubeclimber')));

				@cc = import('cubeclimber');
				if(!@cc) {
					@cc = array(
						players: array(),
						highest: 0,
						reset: false,
					);
					export('cubeclimber', @cc);
					broadcast(player().colorize(' queued up a game of '.@gameTitle), all_players(pworld()));
				} else {
					die(color('red').'Already running.');
				}

				if(!array_contains(get_scoreboards(), 'cc')) {
					create_scoreboard('cc');
					create_objective('height', 'DUMMY', 'cc');
					set_objective_display('height', array(slot: 'SIDEBAR', displayname: 'Starting...'), 'cc');
					_add_activity('cubeclimber', 'CubeClimber', 'cubeclimber', pworld());
				}

				include('includes.library/cubeclimber.ms');
				_cc_start();

			case 'reset':
				if(!has_permission('cubeclimber.reset')) {
					die(color('red').'You do not have permission.');
				}
				@cc = import('cubeclimber');
				@cc['reset'] = true;
				msg(color('green').'CubeClimber resetting...');

			case 'stats':
				@player = player();
				if(array_size(@args) > 1) {
					@player = @args[1];
				}
				@pstats = get_value('cubeclimber.player', _get_uuid(to_lower(@player)));
				if(!@pstats) {
					die(color('gold').'No statistics recorded for player '.@player);
				}
				@gamesWon = @pstats[0];
				@gamesPlayed = @pstats[1];
				@blocksClimbed = @pstats[2];
				@opponentsPlayed = @pstats[3];
				@avgPlayersDefeated = round((@gamesWon / @gamesPlayed) * (@opponentsPlayed / @gamesPlayed), 2);
				@avgBlocksClimbed = round((@blocksClimbed / @gamesPlayed), 2);
				msg(color('red').color('bold').'[ PERFORMANCE ]');
				msg(color('red').'[ '.@avgPlayersDefeated.' ] '.color('r').'Avg Players Defeated');
				msg(color('red').'[ '.@avgBlocksClimbed.' ] '.color('r').'Avg Blocks Climbed');
				if(array_index_exists(@pstats, 4)) {
					@bestTime = @pstats[4];
					msg(color('green').color('bold').'[ PERSONAL RECORDS ]');
					msg(color('green').'[ '.@bestTime.' ] '.color('r').'Best Time');
				}
				msg(color('yellow').color('bold').'[ STATISTICS ]');
				msg(color('yellow').'[ '.@gamesWon.' ] '.color('r').'Total Games Won');
				msg(color('yellow').'[ '.@gamesPlayed.' ] '.color('r').'Total Games Played');
				msg(color('yellow').'[ '.@blocksClimbed.' ] '.color('r').'Total Blocks Climbed');
				msg(color('yellow').'[ '.@opponentsPlayed.' ] '.color('r').'Total Opponents Played');

			case 'top':
				@toptimes = get_value('cubeclimber', 'toptimes');
				if(!@toptimes) {
					die(color('gold').'No top times recorded.');
				}
				msg(color('green').color('bold').'Top Times');
				@player = 0;
				@time = 2;
				foreach(@this in @toptimes) {
					msg(color('yellow').'[ '.@this[@time].' ] '.color('r').@this[@player]);
				}

			case 'resetstats':
				if(!has_permission('cubeclimber.resetstats')) {
					die(color('red').'You do not have permission.');
				}
				@stats = get_values('cubeclimber');
				foreach(@key in array_keys(@stats)) {
					clear_value(@key);
				}
				msg(color('green').'CubeClimber stats reset.');

			case 'resettimes':
				if(!has_permission('cubeclimber.resetstats')) {
					die(color('red').'You do not have permission.');
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

			default:
				msg(colorize(@gameTitle)
				.' is a minigame where the goal is to reach the top of the block tower first.'
				.' You will be assigned a random block color.'
				.' Blocks that you walk on will change to that color,'
				.' and you can click to break blocks of that color.');
				msg('/cubeclimber start '.color(7).'Start the game.');
				msg('/cc stats '.color(7).'View statistics.');
				msg('/cc top '.color(7).'View the top times.');
		}
	}
));

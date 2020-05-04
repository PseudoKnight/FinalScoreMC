register_command('cake', array(
	'description': 'Lists and manages cake prizes',
	'usage': '/cake <list|info|find|set|move|delete|rename|tp|resetplayer|stats> [cake_id] [coins] [type] [difficulty]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('list', 'info', 'find', 'set', 'move', 'delete', 'rename', 'tp', 'resetplayer', 'stats'), @args[-1]));
		} else if(array_size(@args) == 4) {
			return(_strings_start_with_ic(array('challenge', 'secret', 'coop'), @args[-1]));
		} else if(array_size(@args) == 5) {
			return(_strings_start_with_ic(array('easy', 'easy-medium', 'medium', 'medium-hard', 'hard', 'very-hard'), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		switch(@args[0]) {
			case 'list':
				@cakes = get_value('cakeinfo');
				@names = '';
				@count = 0;
				@total = 0;
				@player = @player = puuid(player(), true);
				@type = 'secret';
				foreach(@arg in @args[1..]) {
					if(array_contains(array('challenge', 'secret', 'coop'), @arg)) {
						@type = @arg;
					} else {
						@player = puuid(@arg, true);
					}
				}
				foreach(@id: @cake in @cakes) {
					if(@cake['type'] == @type) {
						@total += 1;
						@splitName = split('_', @id);
						foreach(@i: @section in @splitName) {
							@splitName[@i] = to_upper(@section[0]).@section[1..];
						}
						@name = array_implode(@splitName, '_');
						if(array_index_exists(@cake['players'], @player)) {
							@count += 1;
							@names .= ' '.color('dark_gray').@name;
						} else {
							@names .= ' '.color('r').@name;
						}
					}
				}
				if(array_size(@args) > 1) {
					msg(color('yellow').'CAKES ACHIEVED BY '.to_upper(@args[1]));
				} else {
					msg(color('yellow').'CAKES YOU\'VE ACHIEVED');
				}
				msg(color('green').color('l').to_upper(@type[0]).@type[1..].' Cakes'.color('green').' ('.@count.' of '.@total.')'.color('r').@names);

			case 'find':
				@cakeInfo = get_value('cakeinfo');
				@cakeLoc = get_value('cakes');
				@range = 4096;
				if(array_size(@args) > 1 && is_integral(@args[1])) {
					@range = integer(@args[1]);
				}

				@loc = ploc();
				@distance = @range;
				@found = null;
				foreach(@id: @cake in @cakeInfo) {
					if(@cake['type'] == 'secret') {
						@d = distance(@loc, @cakeLoc[@id]);
						if(@d < @distance) {
							@found = @id;
							@distance = @d;
						}
					}
				}
				if(is_null(@found)) {
					die(color('gold').'Cake not found within '. @range .' blocks.');
				}
				msg(color('green').'Found '.@found.' cake.');
				set_ploc(@cakeLoc[@found]);

			case 'info':
				@id = '';
				if(array_size(@args) < 2) {
					@cakes = get_value('cakes');
					@cursorloc = pcursor();
					foreach(@key: @loc in @cakes) {
						if(@loc[0] == @cursorloc[0]
						&& @loc[1] == @cursorloc[1]
						&& @loc[2] == @cursorloc[2]) {
							@id = @key;
							break();
						}
					}
					if(!@id) {
						die('No cake prize found.');
					}
				} else {
					@id = @args[1];
				}
				@cake = get_value('cakeinfo')[@id];
				@names = '';
				foreach(@p: @time in @cake['players']){
					@names .= get_value('uuids', @p)['name'].' ';
				}
				msg('Cake info for "'.@id.'":');
				msg(color('green').@cake['coins'].color('r').' coins.');
				msg(color('green').array_size(@cake['players']).color('r').' players: '.@names);

			case 'set':
				if(!has_permission('group.engineer')) {
					die(color('gold').'You do not have permission to use this cake command.');
				}
				if(array_size(@args) < 3) {
					return(false);
				}
				@loc = pcursor();
				@cakes = get_value('cakes');
				@id = @args[1];

				if(!array_index_exists(@cakes, @id) && get_block(@loc) !== 'CAKE') {
					die(color('gold').'That doesn\'t appear to be a cake. Is it obstructed by a sign or other partial block?');
				}

				if(!@cakes) {
					@cakes = associative_array();
				}

				if(!array_index_exists(@cakes, @id)) {
					@cakes[@id] = array(integer(@loc[0]), integer(@loc[1]), integer(@loc[2]), @loc[3]);
				}

				@coins = @args[2];

				@type = 'challenge';
				if(array_size(@args) > 3) {
					@type = to_lower(@args[3]);
				}

				if(@type !== 'secret' && @type !== 'challenge' && @type !== 'coop') {
					die(color('gold').'You can only have "secret", "challenge", or "coop" cake types.');
				}

				@cakeinfo = get_value('cakeinfo');
				if(array_index_exists(@cakeinfo, @id)) {
					@cake = @cakeinfo[@id];
				} else {
					@cake = associative_array();
					@cake['players'] = associative_array();
				}

				if(array_index_exists(@cake, 'coins') && @coins != @cake['coins']) {
					foreach(@uuid in array_keys(@cake['players'])) {
						// get cached if available
						@pdata = if(ponline(@uuid), _pdata(player(@uuid)), _pdata_by_uuid(@uuid));
						@pdata['coins'] = array_get(@pdata, 'coins', 0) + (@coins - @cake['coins']);
						_store_pdata(@uuid, @pdata);
					}
				}

				if(array_size(@args) > 4) {
					@cake['difficulty'] = @args[4];
				}
				@cake['coins'] = @coins;
				@cake['type'] = @type;
				@cakeinfo[@id] = @cake;
				store_value('cakes', @cakes);
				store_value('cakeinfo', @cakeinfo);
				msg(color('green').'Set '.@type.' cake "'.@id.'" ('.@coins.' coins)');

			case 'move':
				if(!has_permission('group.engineer')) {
					die(color('gold').'You do not have permission to use this cake command.');
				}
				if(array_size(@args) < 2) {
					die(color('gold').'This needs a cake id.');
				}
				@id = @args[1];
				@loc = pcursor();
				if(get_block(@loc) !== 'CAKE') {
					die(color('gold').'That doesn\'t appear to be a cake. Is it obstructed by a sign or other partial block?');
				}

				@cakes = get_value('cakes');
				if(!array_index_exists(@cakes,@id)) {
					die('There doesn\'t appaar to be a cake by that id.');
				}
				@cakes[@id] = array(integer(@loc[0]), integer(@loc[1]), integer(@loc[2]), @loc[3]);
				store_value('cakes', @cakes);
				msg(color('green').'Set '.@id.' cake to this new location.');

			case 'delete':
			case 'remove':
				if(!has_permission('group.engineer')) {
					die(color('gold').'You do not have permission to use this cake command.');
				}
				@cakes = get_value('cakes');
				@id = '';
				if(array_size(@args) < 2) {
					@cursorloc = pcursor();
					foreach(@key: @loc in @cakes) {
						if(@loc[0] == @cursorloc[0]
						&& @loc[1] == @cursorloc[1]
						&& @loc[2] == @cursorloc[2]) {
							@id = @key;
							break();
						}
					}
					if(!@id) {
						die(color('gold').'No cake prize found.');
					}
				} else {
					@id = @args[1];
				}
				if(!array_index_exists(@cakes, @id)) {
					die(color('gold').'No cake by that ID found.');
				}
				array_remove(@cakes, @id);
				@cakeinfo = get_value('cakeinfo');
				array_remove(@cakeinfo, @id);
				store_value('cakes', @cakes);
				store_value('cakeinfo', @cakeinfo);
				msg(color('green').'Deleted cake '.@id);

			case 'rename':
				if(!has_permission('group.engineer')) {
					die(color('gold').'You do not have permission to use this cake command.');
				}
				@cakes = get_value('cakes');
				if(array_size(@args) == 2) {
					@cursorloc = pcursor();
					foreach(@key: @loc in @cakes) {
						if(@loc[0] == @cursorloc[0]
						&& @loc[1] == @cursorloc[1]
						&& @loc[2] == @cursorloc[2]) {
							@old = @key;
							break();
						}
					}
					if(!@old) {
						die(color('gold').'No cake prize found.');
					}
					@new = @args[1];
				} else if(array_size(@args) == 3) {
					@old = @args[1];
					@new = @args[2];
					if(!array_index_exists(@cakes, @old)) {
						die(color('gold').'No cake by that ID found.');
					}
				} else {
					die(color('yellow').'Usage: /cake rename <oldname> <newname>');
				}
				@cakes[@new] = @cakes[@old];
				array_remove(@cakes, @old);
				@cakeinfo = get_value('cakeinfo');
				@cakeinfo[@new] = @cakeinfo[@old];
				array_remove(@cakeinfo, @old);
				store_value('cakeinfo', @cakeinfo);
				store_value('cakes', @cakes);
				msg(color('green').'Changed '.@old.' to '.@new.'.');

			case 'tp':
				if(!has_permission('group.engineer')) {
					die(color('gold').'You do not have permission to use this cake command.');
				}
				if(array_size(@args) < 2) {
					die(color('gold').'This needs an id.');
				}
				@id = @args[1];
				@cakes = get_value('cakes');
				if(!array_index_exists(@cakes, @id)) {
					die('That cake ID doesn\'t exist');
				}
				set_ploc(array(@cakes[@id][0] + 0.5, @cakes[@id][1], @cakes[@id][2] + 0.5, @cakes[@id][3]));
				msg('Teleported.');

			case 'resetplayer':
				if(!has_permission('group.engineer')) {
					die(color('gold').'You do not have permission to use this cake command.');
				}
				@cakeinfo = get_value('cakeinfo');
				if(array_size(@args) == 2) {
					@player = @args[1];
					@uuid = _get_uuid(@player);
					@count = 0;
					@amount = 0;
					foreach(@id: @cake in @cakeinfo) {
						if(array_index_exists(@cake['players'], @uuid)) {
							@count += 1;
							array_remove(@cake['players'], @uuid);
							@amount += @cake['coins'];
						}
					}
					store_value('cakeinfo', @cakeinfo);
					msg(color('green').'Deleted player from '.@count.' cakes.');
					if(_acc_subtract(@player, @amount)) {
						msg(color('green').'Removed '.@amount.' coins.');
					} else {
						msg(color('gold').'Failed to remove '.@amount.' coins.');
					}

				} else if(array_size(@args) == 3) {
					@id = '';
					@player = '';
					if(array_index_exists(@cakeinfo, @args[1])) {
						@id = @args[1];
						@player = @args[2];
					} else if(array_index_exists(@cakeinfo, @args[2])) {
						@id = @args[2];
						@player = @args[1];
					} else {
						die(color('gold').'No cake found by that name.');
					}
					@uuid = _get_uuid(@player);
					if(!array_index_exists(@cakeinfo[@id]['players'], @uuid)) {
						die('That player does not exist for this cake.');
					}
					array_remove(@cakeinfo[@id]['players'], @uuid)
					store_value('cakeinfo', @cakeinfo)
					msg(color('green').'Deleted player from '.@id.' cake.')
					if(_acc_subtract(@player, @cakeinfo[@id]['coins'])) {
						msg(color('green').'Remove '.@cakeinfo[@id]['coins'].' coins.');
					} else {
						msg(color('gold').'Failed to remove '.@cakeinfo[@id]['coins'].' coins.');
					}

				} else {
					msg(color('yellow').'Usage: /cake resetplayer [cakeid] <player>');
				}
				
			case 'stats':
				if(array_size(@args) < 2) {
					die(color('gold').'Requires a cake type: challenge, secret, coop.');
				}
				@chatcolor = associative_array(
					'easy': 'aqua',
					'easy-medium': 'green',
					'medium': 'yellow',
					'medium-hard': 'gold',
					'hard': 'dark_red',
					'very-hard': 'dark_purple',
					'other': 'white',
				);
				@cakes = get_value('cakeinfo');
				@list = array();
				@min = 100;
				@type = @args[1];
				foreach(@id: @cake in @cakes) {
					if(@cake['type'] != @type) {
						continue();
					}
					@min = min(@min, array_size(@cake['players']));
				}
				@min--;
				foreach(@id: @cake in @cakes) {
					if(@cake['type'] != @type) {
						continue();
					}
					@time = time();
					foreach(@ptime in @cake['players']) {
						if(@ptime < @time) {
							@time = @ptime;
						}
					}
					@prefix = '';
					if(array_index_exists(@cake, 'difficulty')) {
						@prefix = color(@chatcolor[@cake['difficulty']]);
					} else {
						@prefix = @cake['coins'].' ';
					}
					@list[] = array(
						'name': @id,
						'prefix': @prefix,
						'rate': round((time() - @time) / 604800000 / (array_size(@cake['players']) - @min), 2)
					);
				}
				array_sort(@list, closure(@left, @right){
					return(@left['rate'] > @right['rate']);
				});
				msg(color('yellow').color('bold').'Frequency of completion:');
				foreach(@cake in @list) {
					msg(@cake['prefix'].@cake['name'].': '.@cake['rate'].' weeks');
				}

			default:
				msg(color('green').'[CAKE] Commands to create, change and remove cake prizes.');
				msg('/cake list '.color('gray').'List the names of all cake prizes.');
				msg('/cake info [id] '.color('gray').'Shows cake info and the players who have it.');
				msg('/cake set [id] <coins> [type] [difficulty]'.color('gray').'Sets the data for the specified cake.'
				 	' Type can be "secret", "challenge", or "coop". Difficulty can be "easy", "easy-medium", "medium",'
					.' "medium-hard", "hard", or "very-hard".');
				msg('/cake move <id> '.color('gray').'Moves the prize cake to a new location.');
				msg('/cake tp <id> '.color('gray').'Teleports you to a cake.');
				msg('/cake rename <old> <new> '.color('gray').'Renames a cake.');
				msg('/cake delete [id] '.color('gray').'Deletes the prize for the cake you\'re looking at.');
				msg('/cake resetplayer [id] <player> '.color('gray').'Deletes player from cake.');
				msg('/cake stats <type> '.color('gray').'Shows the completion frequency for all cakes of this type.');
		}
	}
));

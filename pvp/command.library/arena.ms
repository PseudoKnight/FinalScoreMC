register_command('arena', array(
	'description': 'Manages pvp arena configurations.',
	'usage': '/arena <list|set|add|load|move|delete|info|stats|resetstats> [arena_id] [setting] [value(s)]',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('list', 'set', 'add', 'load', 'move', 'delete', 'info',
					'stats', 'resetstats'), @args[-1]));
		} else if(array_size(@args) == 3) {
			@action = @args[0];
			@completions = array();
			if(@action == 'set' || @action == 'delete') {
				@completions = array('class_picks', 'delay', 'lives', 'max', 'min', 'respawntime', 'score', 'time',
						'dropchance', 'saturation', 'hunger', 'rounds', 'timer', 'teamratio', 'class_picking',
						'kothregion', 'parent', 'powerup', 'region', 'resourcepack', 'respawnmode', 'goalname',
						'captain', 'nametags', 'stats', 'build', 'debug', 'hideplayers', 'infinitedispensers',
						'keepinventory', 'nobottles', 'noinventory', 'noxp', 'rallycall', 'stackedpickup',
						'heartsdisplay', 'script', 'exitrespawn', 'description', 'lobby', 'podium', 'kothbeacon',
						'ctfflag', 'respawn', 'spawn','blockbreak', 'ff', 'arenaselect', 'sharedarenas', 'mode',
						'mobprotect', 'team', 'kit', 'restore','itemspawn', 'chestgroup', 'chestspawn', 'rsoutput',
						'rsoutputscore', 'effect', 'denydrop', 'mobspawn', 'weapons', 'options');
				if(!@args[2]) {
					return(@completions);
				}
			} else if(@action == 'add') {
				@completions = array('description', 'arenaselect', 'weapons', 'options');
			} else if(@action == 'load') {
				@completions = array('kit', 'chestspawn', 'spawn');
			}
			return(_strings_start_with_ic(@completions, @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(!@args) {
			return(false);
		}
		@action = @args[0];
		switch(@action) {
			case 'set':
			case 's':
			case 'add':
				if(array_size(@args) < 4) {
					return(false);
				}
				if(!has_permission('group.builder')) {
					die(color('gold').'You do not have permission.');
				}
				@id = @args[1];
				if(reg_count('^[a-z0-9_]+$', @id) < 1) {
					die(color('gold').'You can only use lowercase alphanumeric characters for the ID');
				}
				@arena = get_value('arena.'.@id);
				if(!@arena) {
					@arena = associative_array();
					msg(color('green').'Creating new arena... ');
				}
				
				@setting = @args[2];
				switch(@setting) {

					# integers
					case 'class_picks':
					case 'delay':
					case 'lives':
					case 'max':
					case 'min':
					case 'respawntime':
					case 'score':
					case 'time':
					case 'dropchance':
					case 'saturation':
					case 'hunger':
					case 'rounds':
					case 'sky':

						if(!is_integral(@args[3])) {
							die(color('gold').@setting . ' requires an integer.');
						}
						@arena[@setting] = integer(@args[3]);
						msg(colorize('Set &a' . @setting . '&r to &a' . @args[3]));

					# 2 integer options
					case 'timer':
					case 'teamratio':

						if(array_size(@args) < 5 || !is_integral(@args[3]) || !is_integral(@args[4])) {
							die(color('gold').@setting . ' requires two integers.');
						}
						@arena[@setting] = array(integer(@args[3]), integer(@args[4]));
						msg(colorize('Set &a' . @setting . '&r to &a' . @args[3] . '&r : &a' . @args[4]));

					# string options
					case 'class_picking':
					case 'kothregion':
					case 'parent':
					case 'powerup':
					case 'region':
					case 'resourcepack':
					case 'respawnmode':
					case 'goalname':

						@arena[@setting] = @args[3];
						msg(colorize('Set &a' . @setting . '&r to &a' . @args[3]));

					# 2 string options
					case 'captain':
					case 'nametags':

						@arena[@setting][0] = array(@args[3], @args[4]);
						msg(colorize('Set &a' . @setting . '&r to &a' . @args[3] . '&r and &a' . @args[4] . '&r.'));

					# boolean option (true default)
					case 'stats':
						switch(@args[3]) {
							case 'true':
							case 'on':
							case '1':
							case 'yes':
								try {
									array_remove(@arena, @setting);
								} catch(IndexOverflowException @ex) {
									die(color('yellow').'Already set to true by default.');
								}
								msg(colorize('Turned &a' . @setting . '&r on (default)'));

							case 'false':
							case 'off':
							case '0':
							case 'no':
								@arena[@setting] = false;
								msg(colorize('Turned &a' . @setting . '&r off'));

							default:
								die(color('gold').'Only accepts values: true or false');
						}

					# boolean option (false default)
					case 'build':
					case 'debug':
					case 'hideplayers':
					case 'infinitedispensers':
					case 'keepinventory':
					case 'nobottles':
					case 'noinventory':
					case 'noxp':
					case 'rallycall':
					case 'stackedpickup':
					case 'heartsdisplay':
					case 'exitrespawn':

						switch(@args[3]) {
							case 'true':
							case 'on':
							case '1':
							case 'yes':
								if(!array_index_exists(@arena, 'flags')) {
									@arena['flags'] = array();
								}
								@arena['flags'][] = @setting;
								msg(colorize('Turned &a' . @setting . '&r on'));

							case 'false':
							case 'off':
							case '0':
							case 'no':
								array_remove_values(array_get(@arena, 'flags', array()), @setting);
								msg(colorize('Turned &a' . @setting . '&r off (default)'));

							default:
								die(color('gold').'Only accepts values: true or false');
						}

					# message option
					case 'description':
						if(@action == 'add') {
							@arena[@setting][] = colorize(@string);
						} else {
							@arena[@setting] = array(colorize(@string));
						}
						msg(colorize('Set &a' . @setting . '&r to '.@arena[@setting]));

					# single exact locations
					case 'lobby':
					case 'podium':
					case 'kothbeacon':

						if(_is_survival_world(pworld())) {
							die(color('gold').'You can\'t set location in survival world.');
						}
						@loc = ploc();
						@arena[@setting] = array(round(@loc['x'], 1), @loc['y'], round(@loc['z'], 1), @loc['world']);
						msg(colorize('Set &a' . @setting . '&r to current location.'));

					# single exact locations w/ teams (y++)
					case 'ctfflag':

						if(!is_integral(@args[3])) {
							die(color('gold').'This requires a team #.');
						}
						@team = @args[3];
						@loc = ploc();
						@loc = array(
							round(@loc['x'], 1),
							round(@loc['y'], 1) + 1,
							round(@loc['z'], 1),
							@loc['world'],
						);
						@arena[@setting][@team] = @loc;
						msg(colorize('Set &a' . @setting . '&r for team &a' . @team . '&r to this location.'));

					# multiple exact locations w/ teams
					case 'respawn':
					case 'spawn':
					case 'blockbreak':

						if(_is_survival_world(pworld())) {
							die(color('gold').'You can\'t set location in survival world.');
						}
						if(!array_index_exists(@arena, @setting)) {
							@arena[@setting] = array();
						}
						@team = 0;
						if(@args[3]) {
							@team = integer(@args[3]);
						}
						if(!array_index_exists(@arena[@setting], @team)) {
							@arena[@setting][@team] = array();
						}
						@loc = ploc();
						if(@args[4] == 'there') {
							@loc = pcursor();
							@loc = array_normalize(@loc)[0..3];
						} else {
							@loc = array(round(@loc['x'], 1), round(@loc['y'], 1), round(@loc['z'], 1), @loc['world'],
									round(@loc['yaw'], 1), round(@loc['pitch'], 1));
						}
						@arena[@setting][@team][] = @loc;
						msg(colorize('Set a &a' . @setting . '&r to current location for team &a' . @team));
						
					case 'ff':
						switch(@args[3]) {
							case 'true':
							case 'on':
							case '1':
							case 'yes':
								try {
									array_remove(@arena, @setting);
								} catch(IndexOverflowException @ex) {
									die(color('yellow').'Already set to true by default.');
								}
								msg(colorize('Turned &a' . @setting . '&r on (default)'));

							case 'false':
							case 'off':
							case '0':
							case 'no':
								@arena[@setting] = 'false';
								msg(colorize('Turned &a' . @setting . '&r off'));
								
							case 'knockback':
								@arena[@setting] = 'knockback';
								msg(colorize('Allow &aknockback&r only'));
								
							case 'reduced':
								@arena[@setting] = 'reduced';
								msg(colorize('Set &areduced&r friendly-fire'));

							default:
								die(color('gold').'Only accepts values: true, false, knockback, reduced');
						}

					case 'arenaselect':
						if(array_size(@args) == 5) {
							@arena['arenaselect'] = array('type': @args[3], 'arenas': split(',', @args[4]));
							msg(color('green').'Set arena to select '.@args[3].'ly from these child arenas: '.@arena['arenaselect']['arenas']);
						} else if(@action == 'add') {
							@arena['arenaselect']['arenas'][] = @args[3];
							msg(color('green').'Added arena to these child arenas: '.@arena['arenaselect']['arenas']);
						} else {
							die(color('gold').'Requires an arena select type (eg. random) and then a comma separated list of child arenas.');
						}
						array_sort(@arena['arenaselect']['arenas']);

					case 'sharedarenas':
						@arena['sharedarenas'] = split(',', @args[3]);
						msg(color('green').'Set shared arenas to '.@arena['sharedarenas']);

					case 'mode':
						@modes = array(
							'dm': 'Death Match',
							'ddm': 'Dynamic Teams DM',
							'ctf': 'Capture the Flag',
							'koth': 'King of the Hill',
							'infection': 'Zombie Infection',
						);
						if(!array_index_exists(@modes, to_lower(@args[3]))) {
							die(color('yellow').'Available modes: ' . @modes);
						}
						@arena['mode'] = to_lower(@args[3]);
						msg(color('green').'Set arena game mode to '.color(10).@args[3]);

					case 'mobprotect':
						if(array_size(@args) < 5) {
							die(color('gold').'Requires a team # and mob type.');
						}
						if(!array_index_exists(@arena, 'mobprotect')) {
							@arena['mobprotect'] = array();
						}
						@loc = ploc();
						@loc = array(floor(@loc['x']) + 0.5, @loc['y'] + 1, floor(@loc['z']) + 0.5, @loc['world']);
						@arena['mobprotect'][@args[3]] = array(
							'loc': @loc,
							'type': @args[4],
						);
						msg(colorize('Set &a' . @args[4] . '&r to spawn at start for team &a' . @args[3]));

					case 'team':
						if(array_size(@args) < 5) {
							die(color('gold').'Usage: /arena set <arena> team &4Team1 &cTeam2');
						}
						@arena['team'][0]['name'] = substr(@args[3], 2);
						@arena['team'][0]['color'] = @args[3][1];
						@arena['team'][1]['name'] = substr(@args[4], 2);
						@arena['team'][1]['color'] = @args[4][1];
						if(length(@arena['team'][0]['name']) > 16
						|| length(@arena['team'][1]['name']) > 16) {
							die(color('gold').'Name too long. (16 character limit)');
						}
						msg(color('green').'Set team names to '.colorize(@args[3]).' vs '.colorize(@args[4]));

					case 'kit':
						if(!array_index_exists(@arena, 'kit')) {
							@arena['kit'] = array(array(), array());
						}
						@inv = pinv();
						_minify_inv(@inv, true);
						if(@args[3] == '0') {
							@arena['kit'][0] = @inv;
							msg(color('green').'Set kit to current inventory.');
						} else if(@args[3] == '1') {
							@arena['kit'][1] = @inv;
							msg(color('green').'Set kit to current inventory.');
						} else {
							die(color('gold').'Only accepts values 0 or 1 for teams, or blank for when there are no teams.');
						}

					case 'restore':
						@regions = array();
						foreach(@region in @args[3..-1]) {
							if(@region == 'none') {
								break();
							}
							@regions[] = @region;
						}
						@arena['restore'] = @regions;
						msg(color('green').'Restore area set to '.color(10).@regions);

					case 'itemspawn':
						if(!array_index_exists(@arena, 'itemspawn')) {
							@arena['itemspawn'] = array();
						}
						if(is_numeric(@args[3])) {
							@cooldown = @args[3];
							@start = true;
							if(array_size(@args) > 4) {
								@start = @args[4] == 'true';
							}
							@item = pinv(player(), null);
							_minify_inv(@item);
							array_push(@arena['itemspawn'], array(
								'start': @start,
								'cooldown': @cooldown,
								'loc': array(round(ploc()[0], 1), ploc()[1] + 1.5, round(ploc()[2], 1), ploc()[3]),
								'item': @item,
							));
							msg(color('green').'Set held item to spawn here '.if(@start, 'on start and '), 'every '.@cooldown.' seconds.');
							psend_block_change(player(), ploc(), data_values('gold_block'));
						} else {
							die(color('gold').'The first value must be an integer of the number of seconds in the cooldown (default: 30).'
								.' The second can be true or false for if the item spawns at match start (default: true).');
						}

					case 'chestgroup':
						if(!array_index_exists(@arena, 'chestgroup')) {
							@arena['chestgroup'] = associative_array();
						}
						@loc = pcursor();
						if(split(':', get_block_at(@loc))[0] !== '54') {
							die(color('gold').'You must look at a chest you want to spawn.');
						}
						@group = @args[3];
						if(!array_index_exists(@arena['chestgroup'], @group)) {
							@arena['chestgroup'][@group] = array();
						}
						foreach(@key: @chestloc in @arena['chestgroup'][@group]) {
							if(@chestloc == @loc) {
								array_remove(@arena['chestgroup'][@group], @key);
								break();
							}
						}
						@arena['chestgroup'][@group][] = @loc;
						msg(color('green').'Added chest to '.color(10).@group.color('r').' group.'
							.' The items in this chest will spawn in chestspawns that specify '.color(10).@group.color('r')
							.' as their chestgroup. Do not remove this chest.');

					case 'chestspawn':
						if(!array_index_exists(@arena, 'chestspawn')) {
							@arena['chestspawn'] = array();
						}
						@loc = pcursor();
						if(split(':', get_block_at(@loc))[0] !== '54') {
							die(color('gold').'You must look at a chest.');
						}
						foreach(@key: @chest in @arena['chestspawn']) {
							if(@chest['loc'][0] == @loc[0]
							&& @chest['loc'][1] == @loc[1]
							&& @chest['loc'][2] == @loc[2]) {
								array_remove(@arena['chestspawn'], @key);
								break();
							}
						}
						if(is_numeric(@args[3])) {
							@start = 'true';
							if(array_size(@args) > 4) {
								@start = @args[4];
							}
							@items = array();
							for(@i = 0, @i < 27, @i++) {
								if(is_null(get_inventory_item(@loc, @i))) {
									break();
								}
								@items[] = get_inventory_item(@loc, @i);
							}
							array_push(@arena['chestspawn'], array(
								'start': @start,
								'cooldown': @args[3],
								'loc': @loc,
								'items': @items,
							))
							msg(color('green').'Set items in chest to respawn here.');
							set_block_at(@loc, '54:0');
						} else {
							array_push(@arena['chestspawn'], array(
								'loc': @loc,
								'group': @args[3],
							));
							msg(color('green').'Set items in that chest group to spawn here at start.');
						}

					case 'rsoutput':
						@loc = pcursor();
						if(get_block_at(@loc) === '69:6' || get_block_at(@loc) === '69:5') {
							@arena['rsoutput'] = @loc;
							msg(color('green').'Set arena\'s start/end lever. Do not use the block it\'s on to transmit power.');
						} else {
							die(color('gold').'You must be looking at a lever placed on top of a block.');
						}

					case 'rsoutputscore':
						@team = @args[3];
						@arena['rsoutputscore'][@team] = pcursor();
						msg(color('green').'Set this block to turn into a redstone torch when team '.color(10).@team.color('r').' scores.');

					case 'effect':
						if(array_size(@args) < 7) {
							die(color('gold').'Requires team#|all, effect, strength, and length.');
						}
						@effects = _get_effects();
						if(!array_contains(array_keys(@effects), @args[4])) {
							die(color('gold').'Unknown potion effect. '.array_keys(@effects));
						}
						@effect = @effects[@args[4]];
						if(!array_index_exists(@arena, 'effect')) {
							@arena['effect'] = array(associative_array(), associative_array(), associative_array());
						}
						@index = @args[3];
						if(@index === 'all') {
							@index = 0;
						} else {
							@index = integer(@index) + 1;
						}
						if(@args[5] == 0 || @args[6] == 0) {
							array_remove(@arena['effect'][@index], @effect)
							if(array_size(@arena['effect'][0]) == 0
							&& array_size(@arena['effect'][1]) == 0
							&& array_size(@arena['effect'][2]) == 0) {
								array_remove(@arena, 'effect');
							}
							msg('Removed potion effect '.@args[4].'.');
						} else {
							@arena['effect'][@index][@effect] = array('strength': @args[5] - 1, 'length': @args[6]);
							msg('Set '.color(10).@args[4].color('r').' with a strength of '.color(10).@args[5].color('r')
								.' and a length of '.color(10).@args[6].color('r').' seconds'
								.' for '.color(10).if(@args[3] != 'all', 'team ').@args[3]);
						}

					case 'denydrop':
						if(to_lower(@args[3]) === 'all') {
							@arena['denydrop'] = 'all';
						} else {
							@arena['denydrop'] = split(',', @args[3]);
						}
						msg('Set '.color(10).@args[3].color('r').' item IDs to not drop on player death.');

					case 'mobspawn':
						if(array_size(@args) < 7) {
							die(color('gold').'Arguments: <type> <quantity> <respawnSecs> <spawnStart>');
						}
						if(!array_index_exists(@arena, 'mobspawn')) {
							@arena['mobspawn'] = array();
						}
						if(!_get_mob(@args[3])) {
							die(color('gold').'Unknown mob type.');
						}
						if(!is_numeric(@args[4])) {
							die(color('gold').'Qty must be a number.');
						}
						if(!is_numeric(@args[5])) {
							die(color('gold').'Respawn time must be a number in seconds.');
						}
						@arena['mobspawn'][] = array(
							'loc': array(round(ploc()[0], 1), ploc()[1] + 1, round(ploc()[2], 1)),
							'type': @args[3],
							'qty': @args[4],
							'respawn': @args[5],
							'start': @args[6] == 'true',
						);
						msg('Set '.color(10).@args[4].' '.@args[3].color('r').' to spawn here every '
							.color(10).@args[5].color('r').' seconds'.if(@args[6] == 'true', ' and at '.color(10).'start.', '.'));

					case 'weapons':
						if(@action === 'add' && array_index_exists(@arena, 'weapons')) {
							@arena['weapons'] = array_merge(@arena['weapons'], split(',', @args[3]));
						} else {
							@arena['weapons'] = split(',', @args[3]);
						}
						foreach(@weapon in @arena['weapons']) {
							if(!file_exists('../weapons.library/'.@weapon.'.ms')) {
								die(color('gold').'Unknown weapon: '.@weapon);
							}
						}
						msg('Weapons activated: '.color(10).@arena['weapons']);

					case 'options':
						if(array_size(@args) < 5) {
							die(color('gold').'Requires an option value after the option name.');
						}
						@options = array('lives', 'score', 'class_picks', 'class_picking');
						if(!array_contains(@options, @args[3])) {
							die(color('gold').'Not an option. '.@options);
						}
						if(@action !== 'add' || !array_index_exists(@arena, 'options')) {
							@arena['options'] = array();
						}
						@arena['options'][@args[3]] = split(',', @args[4]);
						msg(color('green').'Added '.@args[3].' option with values: '.@args[4]);

					default:
						return(false);
				}
				store_value('arena.'.@id, @arena);

			case 'load':
				if(_is_survival_world(pworld()) || !has_permission('group.builder')) {
					die(color('gold').'You do not have permission.');
				}
				if(array_size(@args) < 4) {
					return(false);
				}
				@id = @args[1];
				@setting = @args[2];
				@arena = get_value('arena.'.@id);
				switch(@setting) {
					case 'kit':
						_clear_pinv();
						@team = @args[3];
						if(@team) {
							set_pinv(player(), @arena['kit'][@team]);
						} else {
							set_pinv(player(), @arena['kit'][0]);
						}
						msg(color('yellow').'You can save this kit by using "/arena set '.@id.' kit '.if(@team, @team).'"');

					case 'chestspawn':
						@pcursor = pcursor();
						@loc = array(integer(@pcursor[0]), integer(@pcursor[1]), integer(@pcursor[2]), @pcursor[3]);
						if(split(':', get_block_at(@loc))[0] !== '54') {
							die(color('gold').'This is not a chest');
						}
						foreach(@chest in @arena['chestspawn']) {
							if(@chest['loc'][0] == @loc[0]
							&& @chest['loc'][1] == @loc[1]
							&& @chest['loc'][2] == @loc[2]) {
								if(array_index_exists(@chest, 'items')) {
									foreach(@index: @item in @chest['items']) {
										set_inventory_item(@loc, @index, @item);
									}
									die(color('yellow').'You can save this chestspawn by using "/arena set '.@id
											.' chestspawn '.@chest['cooldown'].' '.@chest['start'].'"');
								} else {
									die(color('yellow').'This chest spawns with items from the chestgroup '.@chest['chestgroup']);
								}
							}
						}
						msg(color('yellow').'No chestspawn found for that location.');
					
					case 'spawn':
						@block = '35:14';
						foreach(@spawn in @arena['spawn'][0]) {
							psend_block_change(@spawn, @block);
						}
						@block = '35:11';
						foreach(@spawn in @arena['spawn'][1]) {
							psend_block_change(@spawn, @block);
						}

					default:
						die(color('gold').'Unsupported setting for loading.');
				}

			case 'move':
				if(!has_permission('group.engineer')) {
					die('You do not have permission.');
				}
				if(array_size(@args) < 2) {
					return(false);
				}
				@id = @args[1];
				if(array_size(@args) < 4) {
					die(color('gold').'Requires a direction after the arena id (north, south, east, west, up, down)'
							.' and an integer specifying the distance. '.color('red').'WARNING: This moves almost ALL'
							.' locations in an arena configuration. You should know what you\'re doing.');
				}
				if(!is_integral(@args[3])) {
					die(color('gold').'Should be a integer after direction.');
				}
				@arena = get_value('arena', @id);
				if(!@arena) {
					die(color('gold').'There is no defined arena by that name.');
				}

				@dir = @args[2]
				@distance = integer(@args[3]);

				if(array_index_exists(@arena, 'lobby')) {
					@arena['lobby'] = _relative(@arena['lobby'], @dir, @distance);
				}

				if(array_index_exists(@arena, 'spawn')) {
					for(@i = 0, @i < array_size(@arena['spawn'][0]), @i++) {
						@arena['spawn'][0][@i] = _relative(@arena['spawn'][0][@i], @dir, @distance);
					}
					for(@i = 0, @i < array_size(@arena['spawn'][1]), @i++) {
						@arena['spawn'][1][@i] = _relative(@arena['spawn'][1][@i], @dir, @distance);
					}
				}

				if(array_index_exists(@arena, 'region')) {
					@region = sk_region_info(@arena['region'], pworld())[0]
					for(@i = 0, @i < array_size(@region), @i++) {
						@region[@i] = _relative(@region[@i], @dir, @distance);
						array_remove(@region[@i], 3);
					}
					sk_region_update(pworld(), @arena['region'], @region);
				}

				if(array_index_exists(@arena, 'kothregion')) {
					@region = sk_region_info(@arena['kothregion'], pworld())[0];
					for(@i = 0, @i < array_size(@region), @i++) {
						@region[@i] = _relative(@region[@i], @dir, @distance);
					}
					sk_region_update(pworld(), @arena['kothregion'], @region);
				}

				if(array_index_exists(@arena, 'mobprotect')) {
					for(@i = 0, @i < array_size(@arena['mobprotect']), @i++) {
						@arena['mobprotect'][@i]['loc'] = _relative(@arena['mobprotect'][@i]['loc'], @dir, @distance);
					}
				}

				if(array_index_exists(@arena, 'restore')) {
					msg(color('red').'WARNING: This has a restore schematic: '.@arena['restore'].'. '
						.'Please copy it in the new location and overwrite the schematic.');
				}

				if(array_index_exists(@arena, 'itemspawn')) {
					for(@i = 0, @i < array_size(@arena['itemspawn']), @i++) {
						@arena['itemspawn'][@i]['loc'] = _relative(@arena['itemspawn'][@i]['loc'], @dir, @distance);
					}
				}

				if(array_index_exists(@arena, 'chestspawn')) {
					for(@i = 0, @i < array_size(@arena['chestspawn']), @i++) {
						@arena['chestspawn'][@i]['loc'] = _relative(@arena['chestspawn'][@i]['loc'], @dir, @distance);
					}
				}

				if(array_index_exists(@arena, 'mobspawn')) {
					for(@i = 0, @i < array_size(@arena['mobspawn']), @i++) {
						@arena['mobspawn'][@i]['loc'] = _relative(@arena['mobspawn'][@i]['loc'], @dir, @distance);
					}
				}

				if(array_index_exists(@arena, 'rsoutput')) {
					@arena['rsoutput'] = _relative(@arena['rsoutput'], @dir, @distance);
				}

				if(array_index_exists(@arena, 'rsoutputscore')) {
					@arena['rsoutputscore'][0] = _relative(@arena['rsoutputscore'][0], @dir, @distance);
					@arena['rsoutputscore'][1] = _relative(@arena['rsoutputscore'][1], @dir, @distance);
				}

				store_value('arena', @id, @arena);
				msg(color('green').'Moved ALL locations in arena configuration.');
				msg(color('yellow').'Make sure to adjust the blocks to the new location too.');
				msg(color('red').'Reset any setting locations that were not moved.');

			case 'rename':
				if(!has_permission('group.builder')) {
					die('You do not have permission.');
				}
				if(array_size(@args) < 2) {
					return(false);
				}
				@id = @args[1];
				if(array_size(@args) < 3) {
					die(color('gold').'This command requires a new arena ID.');
				}
				if(reg_count('^[a-z0-9_]+$', @id) < 1) {
					die(color('gold').'You can only use lowercase alphanumeric characters for the arena ID')
				}
				@arena = get_value('arena', @id);
				if(!@arena) {
					die(color('gold').'There is no defined arena by that name.');
				}
				store_value('arena', @args[2], @arena);
				clear_value('arena', @id);
				msg('Renamed '.@id.' to '.@args[2].'.');

			case 'remove':
			case 'delete':
				if(!has_permission('group.builder')) {
					die(color('gold').'You do not have permission.');
				}
				if(array_size(@args) < 2) {
					return(false);
				}
				@id = @args[1];
				@setting = '';
				@string = '';
				if(array_size(@args) > 2) {
					@setting = @args[2];
					if(array_size(@args) > 3) {
						@string = @args[3];
					}
				}
				@arena = get_value('arena.'.@id);
				if(!@arena) {
					die(color('gold').'There is no defined arena by that name.');
				}
				if(@setting && !array_index_exists(@arena, @setting)) {
					die(color('gold').'No data stored for setting: '.@setting);
				}

				if(!@string || @string == 'all') {
					if(!@setting) {
						clear_value('arena', @id);
						msg(color('green').'Deleted '.@id.' arena permanently.');
					} else {
						array_remove(@arena, @setting);
						msg(color('green').'Deleted "'.@setting.'" setting for '.@id.'.');
						store_value('arena', @id, @arena);
					}
					die();
				}

				switch(@setting) {
					case 'arenaselect':
						foreach(@value in split(',', @string)) {
							array_remove_values(@arena[@setting]['arenas'], @value);
						}
						msg('Removed '.@string.' from '.@setting.': '.@arena[@setting]);

					case 'spawn':
						@loc = ploc();
						@loc = array(round(@loc[0], 1), round(@loc[1], 1), round(@loc[2], 1), @loc[3]);
						@found = false;
						foreach(@index: @spawn in @arena['spawn'][0]) {
							if(@spawn[0] < @loc[0] + 2 && @spawn[0] > @loc[0] + 2
							&& @spawn[1] < @loc[1] + 2 && @spawn[1] > @loc[1] + 2
							&& @spawn[2] < @loc[2] + 2 && @spawn[2] > @loc[2] + 2) {
								@found = true;
								array_remove(@arena['spawn'][0], @index);
								msg('Removed this spawn location'.if(array_index_exists(@arena, 'team'), ' for team 0.', '.'));
								break();
							}
						}
						if(!@found) {
							foreach(@spawn in @arena['spawn'][1]) {
								if(@spawn[0] < @loc[0] + 2 && @spawn[0] > @loc[0] + 2
								&& @spawn[1] < @loc[1] + 2 && @spawn[1] > @loc[1] + 2
								&& @spawn[2] < @loc[2] + 2 && @spawn[2] > @loc[2] + 2) {
									array_remove(@arena['spawn'][1], @index);
									msg(color('green').'Removed this spawn location'.if(array_index_exists(@arena, 'team'), ' for team 1.', '.'));
									break();
								}
							}
						}

					case 'itemspawn':
						@loc = ploc();
						@loc = array(round(@loc[0], 1), round(@loc[1], 1) + 1.5, round(@loc[2], 1), @loc[3]);
						foreach(@index: @spawn in @arena['itemspawn']) {
							if(@spawn['loc'][0] < @loc[0] + 2 && @spawn['loc'][0] > @loc[0] - 2
							&& @spawn['loc'][1] < @loc[1] + 2 && @spawn['loc'][1] > @loc[1] - 2
							&& @spawn['loc'][2] < @loc[2] + 2 && @spawn['loc'][2] > @loc[2] - 2) {
								array_remove(@arena['itemspawn'], @index);
								msg(color('green').'Removed this item spawn.');
								break();
							}
						}

					case 'chestspawn':
					case 'chestgroup':
						@loc = pcursor();
						if(split(':', get_block_at(@loc))[0] !== '54') {
							die(color('gold').'Please look at a chest to remove it.');
						}
						foreach(@key: @chest in @arena[@setting]) {
							if(@chest['loc'][0] == @loc[0]
							&& @chest['loc'][1] == @loc[1]
							&& @chest['loc'][2] == @loc[2]) {
								set_block_at(@loc, 0);
								array_remove(@arena[@setting], @key);
								msg(color('green').'Removed this '.@setting.' location.');
								break();
							}
						}

					case 'weapons':
					case 'flags':
						foreach(@value in split(',', @args[3])) {
							array_remove_values(@arena[@setting], @value);
						}
						msg(color('green').'Activated '.@setting.': '.@arena[@setting]);

					case 'options':
						foreach(@key in array_keys(@arena[@setting])) {
							if(@key == @args[3]) {
								array_remove(@arena[@setting], @args[3]);
								msg(color('green').'Deleted "'.@args[3].'" from "'.@setting.'" for '.@id.'.');
								break();
							}
						}

					default:
						array_remove(@arena, @setting);
						msg(color('green').'Deleted ' . @setting . ' from ' . @id);

				}
				store_value('arena', @id, @arena);

			case 'info':
			case 'i':
				if(array_size(@args) < 2) {
					return(false);
				}
				@id = @args[1];
				@arena = get_value('arena.'.@id)
				if(!@arena) {
					die(color('gold').'There is no defined arena by that name.');
				}
				msg(color('gray').'-------------------------------------');
				if(array_size(@args) > 2) {
					if(!array_index_exists(@arena, @args[2])) {
						die(color('gold').'That setting is not defined for this arena.');
					}
					msg(@args[2].' '.color('gray').@arena[@args[2]]);
				} else {
					msg(color('l').':: '.to_upper(@id).' :: '.if(array_index_exists(@arena, 'team'),
						color(@arena['team'][0]['color']).@arena['team'][0]['name'].color('gray').' vs '
						.color(@arena['team'][1]['color']).@arena['team'][1]['name']))
					if(!array_index_exists(@arena, 'parent')) {
						# dependent settings
						if(array_index_exists(@arena, 'captain') && !array_index_exists(@arena, 'classes'),
							msg(color('gold').'classes '.color(7).'(required for setting "captain")'));
						if(array_index_exists(@arena, 'captain') && !array_index_exists(@arena, 'respawntime'),
							msg(color('gold').'respawntime '.color(7).'(required for setting "captain")'));
						if(array_index_exists(@arena, 'ctfflag') && !array_index_exists(@arena, 'mode'),
							msg(color('gold').'mode '.color(7).'("ctf" required for setting "ctfflag")'));
						if(array_index_exists(@arena, 'score') && !array_index_exists(@arena, 'mode'),
							msg(color('gold').'mode '.color(7).'("koth" or "ctf" required for setting "score")'));
						if(array_index_exists(@arena, 'kothregion') && !array_index_exists(@arena, 'mode'),
							msg(color('gold').'mode '.color(7).'("koth" required for setting "kothregion")'));
						if(array_index_exists(@arena, 'rsoutputscore') && !array_index_exists(@arena, 'mode'),
							msg(color('gold').'mode '.color(7).'("ctf" required for setting "rsoutputscore")'));
						if(array_index_exists(@arena, 'dropchance') && !array_contains(@arena['flags'], 'keepinventory'),
							msg(color('gold').'keepinventory '.color(7).'(this flag required for "dropchance")'));
					}
					foreach(@setting: @value in @arena) {
						if(array_contains(array('spawn', 'kit', 'itemspawn', 'chestspawn', 'mobspawn', 'classes', 'respawn'), @setting)) {
							msg(@setting.' '.color('gray').'['.array_size(@value).' value(s) ...]');
						} else if(array_contains(array('team'), @setting)) {
							continue();
						} else {
							msg(@setting.' '.color('gray').@value);
						}
					}
				}
				msg(color('gray').'-------------------------------------');

			case 'stats':
				if(array_size(@args) < 2) {
					return(false);
				}
				@id = @args[1];
				@arena = get_value('arena.'.@id);
				if(!@arena) {
					die(color('gold').'There is no defined arena by that name.');
				}
				if(array_index_exists(@arena, 'played')) {
					msg(color('gold').'Played: '.color(7).@arena['played'].' times');
				}
				if(array_index_exists(@arena, 'classes')) {
					foreach(@class: @c in @arena['classes']) {
						if(array_index_exists(@c, 'picked')) {
							msg(color('gold').to_upper(@class).': '.color(7).@c['picked']);
						}
					}
				}

			case 'resetstats':
				if(!has_permission('group.builder')) {
					die(color('gold').'You do not have permission.');
				}
				if(array_size(@args) < 2) {
					return(false);
				}
				@id = @args[1];
				@arena = get_value('arena.'.@id);
				if(!@arena) {
					die(color('gold').'There is no defined arena by that name.');
				}
				if(array_index_exists(@arena, 'played')) {
					array_remove(@arena, 'played');
				}
				if(array_index_exists(@arena, 'classes')) {
					foreach(@class: @c in @arena['classes']) {
						if(array_index_exists(@c, 'picked')) {
							array_remove(@arena['classes'][@class], 'picked');
						}
					}
				}
				store_value('arena.'.@id, @arena);
				msg(color('gold').'Reset stats for '.@id);

			case 'list':
				@arenas = get_values('arena');
				@list = '';
				foreach(@name: @arena in @arenas) {
					@list .= split('.', @name)[1].if(array_index_exists(@arena, 'played'), '('.@arena['played'].')').' ';
				}
				msg(color('gray').'PVP ARENAS: '.color('r').@list);

			default:
				return(false);
		}
	}
));

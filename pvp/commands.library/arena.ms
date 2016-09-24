proc _arena(@action, @id, @setting, @string) {
	if(@string) {
		@args = parse_args(@string);
	} else {
		@args = array();
	}
	array_resize(@args, 4);
	switch(@action) {
		case 'set':
		case 's':
		case 'add':
			if(!has_permission('group.builder'), die('You do not have permission.'))
			if(reg_count('^[a-z0-9]+$', @id) < 1, die('You can only use lowercase alphanumeric characters for the ID'))
			@arena = get_value('arena.'.@id)
			if(!@arena, @arena = associative_array())
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

					if(!is_integral(@args[0])) {
						die(@setting . ' requires an integer.');
					}
					@arena[@setting] = integer(@args[0]);
					msg(colorize('Set &a' . @setting . '&r to &a' . @args[0]));

				# 2 integer options
				case 'timer':

					if(!@args[0] || !@args[1] || !is_integral(@args[0]) || !is_integral(@args[1])) {
						die(@setting . ' requires two integers.');
					}
					@arena[@setting] = array(integer(@args[0]) - 1, integer(@args[1]));
					msg(colorize('Set &a' . @setting . '&r for team &a' . @args[0] . '&r to &a' . @args[1]));

				# string options
				case 'broadcast':
				case 'class_picking':
				case 'kothregion':
				case 'parent':
				case 'powerup':
				case 'region':
				case 'resourcepack':
				case 'respawnmode':

					@arena[@setting] = @args[0];
					msg(colorize('Set &a' . @setting . '&r to &a' . @args[0]));

				# 2 string options
				case 'captain':
				case 'nametags':

					@arena[@setting][0] = array(@args[0], @args[1]);
					msg(colorize('Set &a' . @setting . '&r to &a' . @args[0] . '&r and &a' . @args[1] . '&r.'));

				# boolean option (true default)
				case 'ff':
				case 'stats':
					switch(@args[0]) {
						case 'true':
						case 'on':
						case '1':
						case 'yes':
							try {
								array_remove(@arena, @setting);
							} catch(IndexOverflowException @ex) {
								die('Already set to true by default.');
							}
							msg(colorize('Turned &a' . @setting . '&r on (default)'));

						case 'false':
						case 'off':
						case '0':
						case 'no':
							@arena[@setting] = false;
							msg(colorize('Turned &a' . @setting . '&r off'));

						default:
							die('Only accepts values: true or false');
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
				case 'script':

					switch(@args[0]) {
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
							die('Only accepts values: true or false');
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

					if(pworld() !== 'custom') {
						die('You can only set location in the custom world.');
					}
					@loc = ploc();
					@arena[@setting] = array(round(@loc['x'], 1), @loc['y'], round(@loc['z'], 1), @loc['world']);
					msg(colorize('Set &a' . @setting . '&r to current location.'));

				# single exact locations w/ teams (y++)
				case 'ctfflag':

					if(!@args[0] || !is_integral(@args[0])) {
						die('This requires a team #.');
					}
					@team = @args[0] - 1;
					@loc = ploc();
					@loc = array(
						round(@loc['x'], 1),
						round(@loc['y'], 1) + 1,
						round(@loc['z'], 1),
						@loc['world'],
					);
					@arena[@setting][@team] = @loc;
					msg(colorize('Set &a' . @setting . '&r for team &a' . @args[0] . '&r to this location.'));

				# multiple exact locations w/ teams
				case 'respawn':
				case 'spawn':

					if(pworld() !== 'custom') {
						die('You can only set location in the custom world.');
					}
					if(!array_index_exists(@arena, @setting)) {
						@arena[@setting] = array(array(), array());
					}
					@loc = ploc();
					@loc = array(round(@loc['x'], 1), round(@loc['y'], 1), round(@loc['z'], 1), @loc['world']);
					@team = 0;
					if(@args[0] === '2') {
						@team = 1;
					}
					@arena[@setting][@team][] = @loc;
					msg(colorize('Set a &a' . @setting . '&r to current location for team &a' . (@team + 1)));

				case 'arenaselect':
					if(array_size(@args) == 2) {
						@arena['arenaselect'] = array('type': @args[0], 'arenas': split(',', @args[1]));
						msg('Set arena to select '.@args[0].'ly from these child arenas: '.@arena['arenaselect']['arenas']);
					} else if(@action == 'add') {
						@arena['arenaselect']['arenas'][] = @args[0];
						msg('Added arena to these child arenas: '.@arena['arenaselect']['arenas']);
					} else {
						die('Requires an arena select type (eg. random) and then a comma separated list of child arenas.');
					}
					array_sort(@arena['arenaselect']['arenas']);

				case 'sharedarenas':
					@arena['sharedarenas'] = split(',', @args[0])
					msg('Set shared arenas to '.@arena['sharedarenas'])

				case 'spawnblock':
					@block = get_block_at(pcursor());
					if(!@args[0]) {
						die('Requires a valid block id.');
					}
					@arena['spawnblock'][@args[0]] = @block;
					msg('Set spawnblock to '.color(10).@block
						.if(array_size(@args) == 1, color('r').' for team '.color(10).@args[0]));

				case 'mode':
					@modes = array(
						'dm': 'Death Match',
						'ddm': 'Dynamic Teams DM',
						'tdm': 'Team DM',
						'ctf': 'Capture the Flag',
						'koth': 'King of the Hill',
						'infection': 'Zombie Infection',
						'tntrun': 'TNT Run Survival',
					);
					if(!array_index_exists(@modes, to_lower(@args[0]))) {
						die('Available modes: ' . @modes);
					}
					@arena['mode'] = to_lower(@args[0]);
					msg('Set arena game mode to '.color(10).@args[0]);

				case 'mobprotect':
					if(!@args[1]) {
						die('Requires a team # and mob type.');
					}
					if(!array_index_exists(@arena, 'mobprotect')) {
						@arena['mobprotect'] = array();
					}
					@loc = ploc();
					@loc = array(floor(@loc['x']) + 0.5, @loc['y'] + 1, floor(@loc['z']) + 0.5, @loc['world']);
					@arena['mobprotect'][@args[0] - 1] = array(
						'loc': @loc,
						'type': @args[1],
					);
					msg(colorize('Set &a' . @args[1] . '&r to spawn at start for team &a' . @args[0]));

				case 'teamratio':
					if(array_size(@args) < 2, die('Needs two integers, for team 1 and team 2.'))
					@arena['teamratio'] = array(@args[0], @args[1])
					msg('Set team ratio to '.color(10).@args[0].':'.@args[1])

				case 'team':
					if(!@args[0] || !@args[1], die('Usage: /arena set <arena> team &4Team1 &cTeam2'))
					if(@args[2], die('Too many arguments. Usage: /arena set <arena> team &4Team1 &cTeam2'))
					@arena['team'][0]['name'] = substr(@args[0], 2)
					@arena['team'][0]['color'] = @args[0][1]
					@arena['team'][1]['name'] = substr(@args[1], 2)
					@arena['team'][1]['color'] = @args[1][1]
					if(length(@arena['team'][0]['name']) > 16
					|| length(@arena['team'][1]['name']) > 16, die('Name too long. (16 character limit)'))
					msg('Set team names to '.colorize(@args[0]).' vs '.colorize(@args[1]))

				case 'kit':
					if(!array_index_exists(@arena, 'kit'), @arena['kit'] = array(array(), array()))
					@inv = pinv();
					_minify_inv(@inv, true);
					if(!@args[0] || @args[0] == 1) {
						@arena['kit'][0] = @inv
						msg('Set kit to current inventory.')
					} else if(@args[0] == 2) {
						@arena['kit'][1] = @inv
						msg('Set kit to current inventory.')
					} else {
						die('Only accepts values 1 or 2 for teams, or blank for when there are no teams.')
					}

				case 'restore':
					if(!has_permission('group.engineer'), die('Only engineers, moderators and admins can do this.'))
					@regions = array()
					foreach(@region in @args) {
						if(!is_null(@region)) {
							array_push(@regions, @region)
						}
					}
					@arena['restore'] = @regions
					msg('Restore area set to '.color(10).@regions)

				case 'itemspawn':
					if(!array_index_exists(@arena, 'itemspawn'), @arena['itemspawn'] = array())
					if(!@args[0] || is_numeric(@args[0])) {
						if(!@args[0], @cooldown = 60, @cooldown = @args[0])
						if(!@args[1], @start = true, @start = @args[1])
						@item = pinv(player(), null);
						_minify_inv(@item);
						array_push(@arena['itemspawn'], array(
							'start': @start,
							'cooldown': @cooldown,
							'loc': array(round(ploc()[0], 1), ploc()[1] + 1.5, round(ploc()[2], 1), ploc()[3]),
							'item': @item
						))
						msg('Set current item to spawn here.')
						psend_block_change(player(), ploc(), data_values('gold_block'))
					} else {
						die('The first value must be an integer of the number of seconds in the cooldown (default: 30).'
							.' The second can be true or false for if the item spawns at match start (default: true).')
					}

				case 'chestgroup':
					if(!array_index_exists(@arena, 'chestgroup'), @arena['chestgroup'] = associative_array())
					if(!@args[0], die('Arguments: <chestGroupName>'))
					@loc = pcursor()
					if(split(':', get_block_at(@loc))[0] !== '54', die('You must look at a chest you want to spawn.'))
					if(!array_index_exists(@arena['chestgroup'], @args[0])) {
						@arena['chestgroup'][@args[0]] = array()
					}
					foreach(@key: @chestloc in @arena['chestgroup'][@args[0]]) {
						if(@chestloc == @loc) {
							array_remove(@arena['chestgroup'][@args[0]], @key)
							break()
						}
					}
					array_push(@arena['chestgroup'][@args[0]], @loc)
					msg('Added chest to '.color(10).@args[0].color('r').' group.'
						.' The items in this chest will spawn in chestspawns that specify '.color(10).@args[0].color('r')
						.' as their chestgroup. Do not remove this chest.')

				case 'chestspawn':
					if(!array_index_exists(@arena, 'chestspawn'), @arena['chestspawn'] = array())
					if(!@args[0], die('Arguments: <chestGroupName> | <cooldownSecs> <spawnStart>'))
					@loc = pcursor()
					if(split(':', get_block_at(@loc))[0] !== '54', die('You must look at a chest.'))
					foreach(@key: @chest in @arena['chestspawn']) {
						if(@chest['loc'][0] == @loc[0]
						&& @chest['loc'][1] == @loc[1]
						&& @chest['loc'][2] == @loc[2]) {
							array_remove(@arena['chestspawn'], @key)
							break()
						}
					}
					if(is_numeric(@args[0])) {
						if(!@args[1], @start = 'true', @start = @args[1])
						@items = array()
						for(@i = 0, @i < 27, @i++) {
							if(is_null(get_inventory_item(@loc, @i)), break())
							array_push(@items, get_inventory_item(@loc, @i))
						}
						array_push(@arena['chestspawn'], array(
							'start': @start,
							'cooldown': @args[0],
							'loc': @loc,
							'items': @items
						))
						msg('Set items in chest to respawn here.')
						set_block_at(@loc, '54:0')
					} else {
						array_push(@arena['chestspawn'], array(
							'loc': @loc,
							'group': @args[0]
						))
						msg('Set items in that chest group to spawn here at start.')
					}

				case 'rsoutput':
					@loc = pcursor()
					if(get_block_at(@loc) === '69:6' || get_block_at(@loc) === '69:5') {
						@arena['rsoutput'] = @loc
						msg('Set arena\'s start/end lever. Do not use the block it\'s on to transmit power.')
					} else {
						die('You must be looking at a lever placed on top of a block.')
					}

				case 'rsoutputscore':
					if(!@args[0], die('This requires a team #.'))
					@team = @args[0] - 1
					@arena['rsoutputscore'][@team] = pcursor()
					msg('Set this block to turn into a redstone torch when team '.color(10).@args[0].color('r').' scores.')

				case 'effect':
					@effects = _get_effects()
					if(!array_contains(array_keys(@effects), @args[1])) {
						die('Unknown potion effect. '.array_keys(@effects))
					}
					@effect = @effects[@args[1]]
					if(!array_index_exists(@arena, 'effect')) {
						@arena['effect'] = array(associative_array(), associative_array(), associative_array())
					}
					if(@args[0] === 'all', @args[0] = 0)
					if(@args[2] == 0 || @args[3] == 0) {
						array_remove(@arena['effect'][@args[0]], @effect)
						if(array_size(@arena['effect'][0]) == 0
						&& array_size(@arena['effect'][1]) == 0
						&& array_size(@arena['effect'][2]) == 0) {
							array_remove(@arena, 'effect')
						}
						msg('Removed potion effect '.@args[1].'.')
					} else {
						@arena['effect'][@args[0]][@effect] = array('strength': @args[2] - 1, 'length': @args[3])
						msg('Set '.color(10).@args[1].color('r').' with a strength of '.color(10).@args[2].color('r')
							.' and a length of '.color(10).@args[3].color('r').' seconds'
							.' for '.color(10).if(@args[0] != 0, 'team ').@args[0])
					}

				case 'denydrop':
					if(!@args[0] || @args[1], die('You need to specify a comma separated list of item IDs. (no spaces)'))
					if(to_lower(@args[0]) === 'all') {
						@arena['denydrop'] = 'all'
					} else {
						@arena['denydrop'] = split(',', @args[0])
					}
					msg('Set '.color(10).@args[0].color('r').' item IDs to not drop on player death.')

				case 'mobspawn':
					if(array_size(@args) < 4, die('Arguments: <type> <quantity> <respawnSecs> <spawnStart>'))
					if(!array_index_exists(@arena, 'mobspawn'), @arena['mobspawn'] = array())
					if(!_get_mob(@args[0]), die('Unknown mob type.'))
					if(!is_numeric(@args[1]), die('Qty must be a number.'))
					if(!is_numeric(@args[2]), die('Respawn time must be a number in seconds.'))
					array_push(@arena['mobspawn'], array(
						'loc': array(round(ploc()[0], 1), ploc()[1] + 1, round(ploc()[2], 1)),
						'type': @args[0],
						'qty': @args[1],
						'respawn': @args[2],
						'start': if(@args[3], 1, 0)
					))
					msg('Set '.color(10).@args[1].' '.@args[0].color('r').' to spawn here every '
						.color(10).@args[2].color('r').' seconds'.if(@args[3], ' and at '.color(10).'start.', '.'))

				case 'weapons':
					@weapons = array('endernades', 'skullrockets',  'shotgunballs', 'primedtnt', 'pistoltears', 'firefire',
						'railgun', 'fireball', 'firebreath', 'spawner', 'grapple', 'tracker', 'mine');
					if(!@args[0] || @args[1]) {
						die('You need to specify a comma separated list of pre-defined weapons.'
							.'(no spaces) Current available weapons: '.@weapons)
					}
					if(@action === 'add' && array_index_exists(@arena, 'weapons')) {
						@arena['weapons'] = array_merge(@arena['weapons'], split(',', @args[0]));
					} else {
						@arena['weapons'] = split(',', @args[0]);
					}
					foreach(@weapon in @arena['weapons']) {
						if(!array_contains(@weapons, @weapon), die('Unknown flag: '.@weapon))
					}
					msg('Weapons activated: '.color(10).@arena['weapons']);

				case 'options':
					@options = array('lives', 'score', 'class_picks', 'class_picking');
					if(!array_contains(@options, @args[0])) {
						die('Not an option. '.@options);
					}
					if(@action !== 'add' || !array_index_exists(@arena, 'options')) {
						@arena['options'] = array();
					}
					@arena['options'][@args[0]] = split(',', @args[1]);
					msg('Added '.@args[0].' option with values: '.@args[1]);

				default:
					die('This requires a valid setting. Type "/arena help" to see settings.')
			}
			store_value('arena.'.@id, @arena)

		case 'load':
			if(_is_survival_world(pworld()) || !has_permission('group.builder')) {
				die('You do not have permission.')
			}
			if(!@id || !@setting) {
				die('Loads a setting where applicable. This currently only applies to kit and chestspawn.'
					.' Chestspawn requires to you look at a chest at a previously defined chestspawn location.')
			}
			@arena = get_value('arena.'.@id)
			switch(@setting) {
				case 'kit':
					_clear_pinv()
					if(@args[0]) {
						set_pinv(player(), @arena['kit'][@args[0] - 1])
					} else {
						set_pinv(player(), @arena['kit'][0])
					}
					msg('You can save this kit by using "/arena set '.@id.' kit '.if(array_size(@args) > 0, @args[0]).'"')

				case 'chestspawn':
					@pcursor = pcursor();
					@loc = array(integer(@pcursor[0]), integer(@pcursor[1]), integer(@pcursor[2]), @pcursor[3]);
					if(split(':', get_block_at(@loc))[0] !== '54', die('This is not a chest'))
					foreach(@chest in @arena['chestspawn']) {
						if(@chest['loc'][0] == @loc[0]
						&& @chest['loc'][1] == @loc[1]
						&& @chest['loc'][2] == @loc[2]) {
							if(array_index_exists(@chest, 'items')) {
								foreach(@index: @item in @chest['items']) {
									set_inventory_item(@loc, @index, @item)
								}
								die('You can save this chestspawn by using "/arena set '.@id.' chestspawn '
									.@chest['cooldown'].' '.@chest['start'].'"')
							} else {
								die('This chest spawns with items from the chestgroup '.@chest['chestgroup'])
							}
						}
					}
					msg('No chestspawn found for that location.')

				default:
					die('Unsupported setting for loading.')
			}

		case 'show':
			if(!has_permission('group.builder')) {
				die('You do not have permission.')
			};
			if(!@id) {
				die('You need to specify an arena.');
			}
			@arena = get_value('arena.'.@id);
			switch(@setting) {
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
					die('Nothing to show for this setting.');
			}

		case 'move':
			if(!has_permission('group.engineer'), die('You do not have permission.'))
			if(!@id, die('This requires an arena id.'))
			if(!@setting, die('Requires a direction after the arena id. (north, south, east, west, up, down)'))
			if(!is_integral(@string), die('Should be a integer after direction.'))
			@arena = get_value('arena', @id)
			if(!@arena, die('There is no defined arena by that name.'))

			@dir = @setting
			@distance = @string

			if(array_index_exists(@arena, 'lobby')) {
				@arena['lobby'] = _relative(@arena['lobby'], @dir, @distance)
			}

			if(array_index_exists(@arena, 'spawn')) {
				for(@i = 0, @i < array_size(@arena['spawn'][0]), @i++) {
					@arena['spawn'][0][@i] = _relative(@arena['spawn'][0][@i], @dir, @distance)
				}
				for(@i = 0, @i < array_size(@arena['spawn'][1]), @i++) {
					@arena['spawn'][1][@i] = _relative(@arena['spawn'][1][@i], @dir, @distance)
				}
			}

			if(array_index_exists(@arena, 'region')) {
				@region = sk_region_info(@arena['region'], 'custom')[0]
				for(@i = 0, @i < array_size(@region), @i++) {
					@region[@i] = _relative(@region[@i], @dir, @distance)
					array_remove(@region[@i], 3);
				}
				sk_region_update('custom', @arena['region'], @region)
			}

			if(array_index_exists(@arena, 'broadcast')
			&& (!array_index_exists(@arena, 'region') || @arena['broadcast'] != @arena['region'])) {
				@region = sk_region_info(@arena['broadcast'], 'custom')[0]
				for(@i = 0, @i < array_size(@region), @i++) {
					@region[@i] = _relative(@region[@i], @dir, @distance)
					array_remove(@region[@i], 3);
				}
				sk_region_update('custom', @arena['broadcast'], @region)
			}

			if(array_index_exists(@arena, 'kothregion')) {
				@region = sk_region_info(@arena['kothregion'], 'custom')[0]
				for(@i = 0, @i < array_size(@region), @i++) {
					@region[@i] = _relative(@region[@i], @dir, @distance)
				}
				sk_region_update('custom', @arena['kothregion'], @region)
			}

			if(array_index_exists(@arena, 'mobprotect')) {
				for(@i = 0, @i < array_size(@arena['mobprotect']), @i++) {
					@arena['mobprotect'][@i]['loc'] = _relative(@arena['mobprotect'][@i]['loc'], @dir, @distance)
				}
			}

			if(array_index_exists(@arena, 'restore')) {
				msg(color('red').'WARNING: This has a restore schematic: '.@arena['restore'].'. '
					.'Please copy it in the new location and overwrite the schematic.')
			}

			if(array_index_exists(@arena, 'itemspawn')) {
				for(@i = 0, @i < array_size(@arena['itemspawn']), @i++) {
					@arena['itemspawn'][@i]['loc'] = _relative(@arena['itemspawn'][@i]['loc'], @dir, @distance)
				}
			}

			if(array_index_exists(@arena, 'chestspawn')) {
				for(@i = 0, @i < array_size(@arena['chestspawn']), @i++) {
					@arena['chestspawn'][@i]['loc'] = _relative(@arena['chestspawn'][@i]['loc'], @dir, @distance)
				}
			}

			if(array_index_exists(@arena, 'mobspawn')) {
				for(@i = 0, @i < array_size(@arena['mobspawn']), @i++) {
					@arena['mobspawn'][@i]['loc'] = _relative(@arena['mobspawn'][@i]['loc'], @dir, @distance)
				}
			}

			if(array_index_exists(@arena, 'rsoutput')) {
				@arena['rsoutput'] = _relative(@arena['rsoutput'], @dir, @distance)
			}

			if(array_index_exists(@arena, 'rsoutputscore')) {
				@arena['rsoutputscore'][0] = _relative(@arena['rsoutputscore'][0], @dir, @distance)
				@arena['rsoutputscore'][1] = _relative(@arena['rsoutputscore'][1], @dir, @distance)
			}

			store_value('arena', @id, @arena)
			msg('Moved ALL locations in arena configuration.')
			msg('Make sure to adjust the blocks to the new location too.')
			msg('Reset any setting locations that were not moved.')

		case 'rename':
			if(!has_permission('group.builder'), die('You do not have permission.'))
			if(!@id, die('This command renames one arena ID to another ID. Usage: /arena rename oldName newName'))
			if(!@setting, die('This command requires a new arena ID.'))
			if(reg_count('^[a-z0-9]+$', @id) < 1) {
				die('You can only use lowercase alphanumeric characters for the arena ID')
			}
			@arena = get_value('arena', @id)
			if(!@arena, die('There is no defined arena by that name.'))
			store_value('arena', @setting, @arena)
			clear_value('arena', @id)
			msg('Renamed '.@id.' to '.@setting.'.')

		case 'remove':
		case 'delete':
			if(!has_permission('group.builder'), die('You do not have permission.'))
			if(!@id) {
				die('Permanently deletes a setting\'s contents, or if no setting is provided,'
					.' it will delete the whole arena.')
			}
			@arena = get_value('arena.'.@id)
			if(!@arena, die('There is no defined arena by that name.'))
			if(@setting && !array_index_exists(@arena, @setting)) {
				die('No data stored for setting: '.@setting);
			}

			if(!@string || @args[0] == 'all') {
				if(!@setting) {
					clear_value('arena', @id);
					die('Deleted '.@id.' arena permanently.');
				}
				array_remove(@arena, @setting);
				msg('Deleted "'.@setting.'" setting for '.@id.'.');
				store_value('arena', @id, @arena);
				die();
			}

			switch(@setting) {
				case 'arenaselect':
					foreach(@value in split(',', @args[0])) {
						array_remove_values(@arena[@setting]['arenas'], @value);
					}
					msg('Removed '.@args[0].' from '.@setting.': '.@arena[@setting]);

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
							msg('Removed this spawn location'.if(array_index_exists(@arena, 'team'), ' for team 1.', '.'));
							break();
						}
					}
					if(!@found) {
						foreach(@spawn in @arena['spawn'][1]) {
							if(@spawn[0] < @loc[0] + 2 && @spawn[0] > @loc[0] + 2
							&& @spawn[1] < @loc[1] + 2 && @spawn[1] > @loc[1] + 2
							&& @spawn[2] < @loc[2] + 2 && @spawn[2] > @loc[2] + 2) {
								array_remove(@arena['spawn'][1], @index);
								msg('Removed this spawn location'.if(array_index_exists(@arena, 'team'), ' for team 2.', '.'));
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
							msg('Removed this item spawn.');
							break();
						}
					}

				case 'chestspawn':
				case 'chestgroup':
					@loc = pcursor();
					if(split(':', get_block_at(@loc))[0] !== '54') {
						die('Please look at a chest to remove it.');
					}
					foreach(@key: @chest in @arena[@setting]) {
						if(@chest['loc'][0] == @loc[0]
						&& @chest['loc'][1] == @loc[1]
						&& @chest['loc'][2] == @loc[2]) {
							set_block_at(@loc, 0)
							array_remove(@arena[@setting], @key)
							msg('Removed this '.@setting.' location.')
							break()
						}
					}

				case 'weapons':
				case 'flags':
					foreach(@value in split(',', @args[0])) {
						array_remove_values(@arena[@setting], @value);
					}
					msg('Activated '.@setting.': '.@arena[@setting]);

				case 'options':
					foreach(@key in array_keys(@arena[@setting])) {
						if(@key == @args[0]) {
							array_remove(@arena[@setting], @args[0]);
							msg('Deleted "'.@args[0].'" from "'.@setting.'" for '.@id.'.');
							break();
						}
					}

				default:
					array_remove(@arena, @setting);
					msg('Deleted ' . @setting . ' from ' . @id);

			}
			store_value('arena', @id, @arena);

		case 'info':
		case 'i':
			if(!@id) {
				die('Displays settings for specified arena. Certain settings [...] require that setting to be provided to'
					.' get detailed information.')
			}
			@arena = get_value('arena.'.@id)
			if(!@arena, die('There is no defined arena by that name.'))
			msg(color('gray').'-------------------------------------')
			if(@setting) {
				if(!array_index_exists(@arena, @setting), die('That setting is not defined for this arena.'))
				msg(@setting.' '.color('gray').@arena[@setting])
			} else {
				msg(color('l').':: '.to_upper(@id).' :: '.if(array_index_exists(@arena, 'team'),
					color(@arena['team'][0]['color']).@arena['team'][0]['name'].color('gray').' vs '
					.color(@arena['team'][1]['color']).@arena['team'][1]['name']))
				if(!array_index_exists(@arena, 'parent')) {
					# dependent settings
					if(array_index_exists(@arena, 'captain') && !array_index_exists(@arena, 'classes'),
						msg(color('gold').'classes '.color(7).'(required for setting "captain")'))
					if(array_index_exists(@arena, 'captain') && !array_index_exists(@arena, 'respawntime'),
						msg(color('gold').'respawntime '.color(7).'(required for setting "captain")'))
					if(array_index_exists(@arena, 'ctfflag') && !array_index_exists(@arena, 'mode'),
						msg(color('gold').'mode '.color(7).'("ctf" required for setting "ctfflag")'))
					if(array_index_exists(@arena, 'score') && !array_index_exists(@arena, 'mode'),
						msg(color('gold').'mode '.color(7).'("koth" or "ctf" required for setting "score")'))
					if(array_index_exists(@arena, 'kothregion') && !array_index_exists(@arena, 'mode'),
						msg(color('gold').'mode '.color(7).'("koth" required for setting "kothregion")'))
					if(array_index_exists(@arena, 'rsoutputscore') && !array_index_exists(@arena, 'mode'),
						msg(color('gold').'mode '.color(7).'("ctf" required for setting "rsoutputscore")'))
					if(array_index_exists(@arena, 'team') && !array_index_exists(@arena, 'mode'),
						msg(color('gold').'mode '.color(7).'(team mode required for "team")'))
					if(array_index_exists(@arena, 'teamratio') && !array_index_exists(@arena, 'mode'),
						msg(color('gold').'mode '.color(7).'(team mode required for "teamratio")'))
					if(array_index_exists(@arena, 'dropchance') && !array_contains(@arena['flags'], 'keepinventory'),
						msg(color('gold').'keepinventory '.color(7).'(this flag required for "dropchance")'))
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
			msg(color('gray').'-------------------------------------')

		case 'stats':
			if(!@id) {
				die('Requires an arena id to get stats.');
			}
			@arena = get_value('arena.'.@id);
			if(!@arena) {
				die('There is no defined arena by that name.');
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
			if(!@id) {
				die('Requires an arena id to get stats.');
			}
			@arena = get_value('arena.'.@id);
			if(!@arena) {
				die('There is no defined arena by that name.');
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
			msg('Reset stats for '.@id);

		case 'list':
			@arenas = get_values('arena')
			@list = ''
			foreach(@name: @arena in @arenas) {
				@list .= split('.', @name)[1].if(array_index_exists(@arena, 'played'), '('.@arena['played'].')').' '
			}
			msg(color('gray').'PVP ARENAS: '.color('r').@list)

		default:
			msg(color('bold').'SUBCOMMANDS ---------------');
			msg('/arena set <id> <setting> [value(s)] '.color('gray').'Creates/overwrites settings');
			msg('/arena add <id> <setting> <value> '.color('gray').'Adds a value to a list setting');
			msg('/arena remove <id> <setting> <value> '.color('gray').'Removes a value to a list setting');
			msg('/arena show <id> <setting> '.color('gray').'Displays hidden locations for settings');
			msg('/arena move <id> <direction> <distance> '.color('greay').'Shifts all locations in arena');
			msg('/arena load <id> <setting> '.color('gray').'Loads kits & chestspawns');
			msg('/arena delete <id> [setting] '.color('gray').'Delete arenas, settings, or chests');
			msg('/arena rename <old-id> <new-id> '.color('gray').'Rename the arena.');
			msg('/arena info [id] [setting] '.color('gray').'View arenas and their settings');
			msg('/arena stats id '.color('gray').'View stats for arena.');
			msg('/arena resetstats id '.color('gray').'Reset stats for arena.');
			msg('/arena list '.color('gray').'List all arenas');
			msg(color('bold').'SETTINGS ------------------');
			msg('lobby '.color('gray').'Sets the lobby warp point');
			msg('spawn '.color('gray').'Adds a spawn point');
			msg('region '.color('gray').'The combat region name');
			msg('parent '.color('gray').'The parent arena configuration.');
			msg('arenaselect '.color('gray').'Type of select and then a comma list of arenas.');
			msg('sharedarenas '.color('gray').'A comma separated list of arena ids.');
			msg('broadcast '.color('gray').'The region all messages are broadcasted.');
			msg('mode '.color('gray').'dm, tdm, ctf, infection, koth.');
			msg('ctfflag '.color('gray').'The flag spawn location for CTF (1 is red, 2 is blue)');
			msg('kothregion '.color('gray').'The king of the hill region - feet position');
			msg('lives '.color('gray').'Number of lives until elimination');
			msg('score '.color('gray').'The target score to win. (ctf: 5, koth: 60)');
			msg('mobprotect '.color('gray').'Team protects mob [team type].');
			msg('teamratio '.color('gray').'The ratio of players for team 1 and 2.');
			msg('team '.color('gray').'Team info - [&4Team1 &cTeam2]');
			msg('nametags '.color('gray').'Name tag visiblity per team');
			msg('kit '.color('gray').'Sets the respawn kits - accepts team num as value');
			msg('classes '.color('gray').'Available classes [team1list team2list]');
			msg('captain '.color('gray').'The captain class for each team');
			msg('delay '.color('gray').'The starting delay (10 or 45 when classes)');
			msg('respawntime '.color('gray').'The respawn time in seconds');
			msg('respawnmode '.color('gray').'"normal" (default) or "mob" for villager respawns');
			msg('restore '.color('gray').'A list of schematics to restore.');
			msg('time '.color('gray').'The starting time');
			msg('ff '.color('gray').'Sets team friendly-fire (true)');
			msg('itemspawn '.color('gray').'Set item drop. (60 sec, no spawn @ start)');
			msg('chestspawn '.color('gray').'Set chest spawn (60 sec, no spawn @ start)');
			msg('mobspawn '.color('gray').'Spawn mob @ loc [type qty respawnTime onStart]');
			msg('rsoutput '.color('gray').'The lever that turns on at start and off at end.');
			msg('rsoutputscore '.color('gray').'Redstone torch appears when a team scores');
			msg('min '.color('gray').'The minimum num of players to start a match. (2)');
			msg('max '.color('gray').'Start the match as soon as this number of players join.');
			msg('effect '.color('gray').'The starting potion effect for all or team.');
			msg('denydrop '.color('gray').'Comma list of IDs not dropped on death or "all"');
			msg('dropchance '.color('gray').'Chance to drop an item when keepinventory is enabled');
			msg('delay '.color('gray').'Delay before game starts after command (3)');
			msg('timer '.color('gray').'Time in minutes till team num wins.');
			msg('resourcepack '.color('gray').'Custom resource pack to load.');
			msg('weapons '.color('gray').'Comma list of special weapons to enable');
			msg('flags '.color('gray').'Special game behavior modifiers');

			die('DETAILED INFORMATION AT:\n'
			.' http://finalscoremc.com/arena-configuration/');
	}
}

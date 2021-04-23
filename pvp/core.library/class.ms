proc _class(@action, @player, @classname, @pvp) {
	@class = @pvp['arena']['classes'][@classname];
	if(array_index_exists(@class, 'script')) {
		include('../classes.library/'.@classname.'.ms');
	}

	switch(@action) {
		case 'load':
			if(array_index_exists(@class, 'hunger') && !is_numeric(@class['hunger'][1])) {
				bind('food_level_changed', array('id': @player.'food'), array('player': @player), @event) {
					cancel();
				}
			}

		case 'equip':
			if(array_index_exists(@class, 'hunger')) {
				set_phunger(@player, @class['hunger'][0]);
				if(is_numeric(@class['hunger'][1])) {
					set_psaturation(@player, @class['hunger'][1]);
				}
			}
			if(array_index_exists(@class, 'kit')) {
				set_pinv(@player, @class['kit']);
			}
			if(array_index_exists(@class, 'speed')) {
				set_pwalkspeed(@player, 0.2); # this workaround is required for after respawns
				set_pwalkspeed(@player, @class['speed']);
			}
			if(array_index_exists(@class, 'effect')) {
				set_timeout(1, closure(){
					foreach(@eid: @e in @class['effect']) {
						set_peffect(@player, @eid, @e['strength'], @e['length'], true);
					}
				});
			}
			if(array_index_exists(@class, 'xp')) {
				set_pexp(@player, @class['xp']);
			}

		case 'powerup':
			set_phunger(@player, min(20, phunger(@player) + 4));
			set_phealth(@player, min(20, phealth(@player) + 1));
			set_ponfire(@player, false);
			if(!array_index_exists(get_peffect(@player), 'night_vision')) {
				set_peffect(@player, 'NIGHT_VISION', 0, 1, true);
			}
			set_peffect(@player, 'REGENERATION', 0, 8, true);
			play_sound(ploc(@player), array('sound': 'ENTITY_ENDERMAN_TELEPORT', 'pitch': 2), @player);
			if(array_index_exists(@class, 'ammo')) {
				@inv = pinv(@player);
				foreach(@slot: @item in @class['ammo']) {
					@max = 64;
					if(@item && array_index_exists(@class, 'stacklimit')
					&& array_index_exists(@class['stacklimit'], @item['name'])) {
						@name = @item['name'];
						@max = @class['stacklimit'][@name];
					}
					@item = @item[];
					if(!is_null(@inv[@slot])) {
						@item['qty'] = min(@max, if(array_index_exists(@item, 'qty'), @item['qty'], 1) + @inv[@slot]['qty']);
					}
					@inv[@slot] = @item;
				}
				set_pinv(@player, @inv);
			}

		case 'unload':
			unbind(@player.'food');
			if(pmode(@player) != 'SPECTATOR') {
				set_pflight(@player, false);
			}
			set_pwalkspeed(@player, 0.2);

	}
}

proc _class_select_random(@player, @pvp) {
	@rand = array_rand(@pvp['arena']['classes'], array_size(@pvp['arena']['classes']));
	@class = '';
	foreach(@c in @rand) {
		if(!array_index_exists(@pvp['arena']['classes'][@c], 'disabled')
		&& (!array_index_exists(@pvp['arena']['classes'][@c], 'team')
		|| @pvp['players'][@player]['team'] == @pvp['arena']['classes'][@c]['team'])) {
			@class = @c;
			break();
		}
	}
	if(@class) {
		if(array_index_exists(@pvp['players'][@player], 'class')) {
			_class('unload', @player, @pvp['players'][@player]['class'], @pvp);
			_class('load', @player, @class, @pvp);
		}
		@pvp['players'][@player]['class'] = @class;
	}
}

proc _class_select(@id, @pvp) {
	if(@pvp['arena']['class_picking'] === 'random'
	|| (array_index_exists(@pvp['arena'], 'class_picks')
	&& @pvp['arena']['class_picks'] == 0)) {
		return();
	}
	@size1 = 1
	@size2 = 1
	foreach(@class in @pvp['arena']['classes']) {
		if(!array_index_exists(@class, 'team') || @class['team'] == 0) {
			@size1 += 1
		}
		if(!array_index_exists(@class, 'team') || @class['team'] == 1) {
			@size2 += 1
		}
	}
	@chestsize1 = 0;
	if(@size1 > 2) {
		@chestsize1 = ceil(@size1 / 9) * 9
		create_virtual_inventory(@id.'0', @chestsize1, 'Choose a Class');
	}
	@chestsize2 = 0;
	if(@size2 > 2) {
		@chestsize2 = ceil(@size2 / 9) * 9
		create_virtual_inventory(@id.'1', @chestsize2, 'Choose a Class');
	}
	@chest = array(array(), array())
	foreach(@class in @pvp['arena']['classes']) {
		if((!array_index_exists(@class, 'team') || @class['team'] == 0)
		&& @size1 > 2
		&& !array_index_exists(@class, 'disabled')
		&& array_index_exists(@class, 'selector')) {
			@chest[0][] = @class['selector']
		}
		if((!array_index_exists(@class, 'team') || @class['team'] == 1)
		&& @size2 > 2
		&& !array_index_exists(@class, 'disabled')
		&& array_index_exists(@class, 'selector')) {
			@chest[1][] = @class['selector']
		}
	}
	if(@chest[0]) {
		@chest[0][@chestsize1 - 1] = array('name': 'COMMAND_BLOCK', 'meta': array(
			'display': 'RANDOM',
			'lore': array('Randomly assign a class'),
		));
		set_inventory(@id.'0', @chest[0])
	}
	if(@chest[1]) {
		@chest[1][@chestsize2 - 1] = array('name': 'COMMAND_BLOCK', 'meta': array(
			'display': 'RANDOM',
			'lore': array('Randomly assign a class'),
		));
		set_inventory(@id.'1', @chest[1])
	}
	foreach(@p: @pdata in @pvp['players']) {
		if(@size1 > 2 && (!array_index_exists(@pdata, 'team') || @pdata['team'] == 0)) {
			if(array_index_exists(@pvp['arena'], 'class_picks')) {
				@pvp['players'][@p]['picks'] = @pvp['arena']['class_picks'];
			}
			popen_inventory(@p, @id.'0');
		} else if(@size2 > 2 && @pdata['team'] == 1) {
			if(array_index_exists(@pvp['arena'], 'class_picks')) {
				@pvp['players'][@p]['picks'] = @pvp['arena']['class_picks'];
			}
			popen_inventory(@p, @id.'1');
		}
	}

	if(@size1 > 2 || @size2 > 2) {
		@pvp['binds'][] = @id.'classselector';
		bind('inventory_click', array('id': @id.'classselector', 'priority': 'HIGH'), array('virtual': true), @e, @id) {
			@pvp = import('pvp'.@id);
			if(!array_index_exists(@pvp['players'], player())
			|| is_null(@e['slotitem'])
			|| is_null(@e['slotitem']['meta'])
			|| is_null(@e['slotitem']['meta']['display'])) {
				die();
			}
			@class = to_lower(strip_colors(@e['slotitem']['meta']['display']))
			if(!array_index_exists(@pvp['arena']['classes'], @class) && @class !== 'random') {
				die();
			}
			if(array_index_exists(@pvp['players'][player()], 'picks')) {
				@pvp['players'][player()]['picks'] -= 1;
			}
			if(array_index_exists(@pvp['arena'], 'captain')) {
				@team = @pvp['players'][player()]['team'];
				if(array_contains(@pvp['arena']['captain'], @class)) {
					set_inventory_item(@id.@team, @e['slot'], null);
					@pvp['team'][@team]['captain'] = player();
				} else if(@pvp['running'] < 2 && array_size(get_inventory_viewers(@id.@team)) == 1) {
					@captain = false;
					foreach(@name: @player in @pvp['players']) {
						@playerTeam = @player['team'];
						if(@playerTeam == @team && array_index_exists(@player, 'class')
						&& @player['class'] == @pvp['arena']['captain'][@playerTeam]) {
							@captain = true;
						}
					}
					if(!@captain) {
						foreach(@slot: @item in get_inventory(@id.@team)) {
							if(is_array(@item) && !is_null(@item['meta']) && !is_null(@item['meta']['display'])
							&& @pvp['arena']['captain'][@team] == to_lower(strip_colors(@item['meta']['display']))) {
								set_inventory_item(@id.@team, integer(@slot), null);
								@pvp['team'][@team]['captain'] = player();
								@class = @pvp['arena']['captain'][@team];
								break();
							}
						}
					}
				}
			}
			play_sound(ploc(), array('sound': 'UI_BUTTON_CLICK'));
			consume();
			cancel();

			if(@class === 'random') {
				@classes = @pvp['arena']['classes'];
				if(array_index_exists(@pvp['players'][player()], 'team')) {
					@classes = array_filter(@pvp['arena']['classes'], closure(@key, @value){
						return(!array_index_exists(@value, 'disabled')
						&& (!array_index_exists(@value, 'team') || @value['team'] == @pvp['players'][player()]['team']));
					});
				}
				if(@classes) {
					do {
						@class = array_rand(@classes, 1, true)[0];
					} while(array_index_exists(@pvp['arena']['classes'][@class], 'disabled'));
				} else {
					@class = array_rand(@pvp['arena']['classes'], 1, true)[0];
				}
			}
			msg(color('green')._to_upper_camel_case(@class).color('r').' has been selected.');
			if(array_index_exists(@pvp['arena']['classes'][@class], 'limit')) {
				@team = @pvp['players'][player()]['team'];
				@count = 1;
				foreach(@name: @player in @pvp['players']) {
					if(@player['team'] == @team && array_index_exists(@player, 'class')
					&& @player['class'] == @class) {
						@count++;
					}
				}
				if(@count >= @pvp['arena']['classes'][@class]['limit']) {
					foreach(@slot: @item in get_inventory(@id.@team)) {
						if(is_array(@item) && !is_null(@item['meta'])
						&& @class == to_lower(strip_colors(@item['meta']['display']))) {
							set_inventory_item(@id.@team, integer(@slot), null);
							break();
						}
					}
				}
			}
			@pvp['players'][player()]['class'] = @class;
			close_pinv();
		}
	}
}

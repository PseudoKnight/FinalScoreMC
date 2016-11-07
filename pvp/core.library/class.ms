proc _class(@action, @player, @class, @pvp) {
	if(array_index_exists(@pvp['arena']['classes'][@class], 'script')) {
		include('../classes.library/'.@class.'.ms')
	}

	switch(@action) {
	case 'load':
		if(array_index_exists(@pvp['arena']['classes'][@class], 'hunger')
		&& !is_numeric(@pvp['arena']['classes'][@class]['hunger'][1])) {
			bind(food_level_changed, array('id': @player.'food'), array(player: @player), @event) {
				cancel()
			}
		}

	case 'equip':
		if(array_index_exists(@pvp['arena']['classes'][@class], 'hunger')) {
			set_phunger(@player, @pvp['arena']['classes'][@class]['hunger'][0])
			if(is_numeric(@pvp['arena']['classes'][@class]['hunger'][1])) {
				set_psaturation(@player, @pvp['arena']['classes'][@class]['hunger'][1])
			}
		}
		if(array_index_exists(@pvp['arena']['classes'][@class], 'kit')) {
			set_pinv(@player, @pvp['arena']['classes'][@class]['kit'])
		}
		if(array_index_exists(@pvp['arena']['classes'][@class], 'speed')) {
			set_pwalkspeed(@player, 0.2) # this workaround is required for after respawns
			set_pwalkspeed(@player, @pvp['arena']['classes'][@class]['speed'])
		}
		if(array_index_exists(@pvp['arena']['classes'][@class], 'effect')) {
			queue_push(closure(){
				foreach(@eid: @e in @pvp['arena']['classes'][@class]['effect']) {
					set_peffect(@player, @eid, @e['strength'], @e['length'], true)
				}
			})
		}
		if(array_index_exists(@pvp['arena']['classes'][@class], 'xp')) {
			set_pexp(@player, @pvp['arena']['classes'][@class]['xp'])
		}

	case 'powerup':
		set_phunger(@player, min(20, phunger(@player) + 4));
		set_ponfire(@player, false);
		@flash = true;
		foreach(@effect in get_peffect(@player)) {
			if(@effect['id'] == 16) {
				@flash = false
			}
		}
		if(@flash) {
			set_peffect(@player, 16, 0, 1, true)
		}
		set_peffect(@player, 10, 1, 5, true);
		play_sound(ploc(@player), array('sound': 'enderman_teleport', 'pitch': 2), @player)
		if(array_index_exists(@pvp['arena']['classes'][@class], 'ammo')) {
			@inv = pinv(@player);
			foreach(@slot: @item in @pvp['arena']['classes'][@class]['ammo']) {
				@max = 64;
				if(@item && array_index_exists(@pvp['arena']['classes'][@class], 'stacklimit')
				&& array_index_exists(@pvp['arena']['classes'][@class]['stacklimit'], @item['name'])) {
					@max = @pvp['arena']['classes'][@class]['stacklimit'][@item['name']];
				}
				@item = @item[];
				if(!is_null(@inv[@slot])) {
					@item['qty'] = min(@max, if(array_index_exists(@item, 'qty'), @item['qty'], 1) + @inv[@slot]['qty']);
					if(@max == 1) {
						@item['data'] = 0;
					}
				}
				@inv[@slot] = @item;
			}
			set_pinv(@player, @inv);
		}

	case 'unload':
		unbind(@player.'food');
		set_pflight(@player, false);
		set_pwalkspeed(@player, 0.2);

	}
}

proc _class_select_random(@player, @pvp) {
	@rand = array_rand(@pvp['arena']['classes'], array_size(@pvp['arena']['classes']));
	@class = '';
	foreach(@c in @rand) {
		if(!array_index_exists(@pvp['arena']['classes'][@c], 'team')
		|| @pvp['players'][@player]['team'] == @pvp['arena']['classes'][@c]['team']) {
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
	if(@size1 > 2) {
		@chestsize1 = ceil(@size1 / 9) * 9
		create_virtualchest(array(
			'id': @id.'0',
			'size': @chestsize1,
			'title': 'Choose a Class'
		))
	}
	if(@size2 > 2) {
		@chestsize2 = ceil(@size2 / 9) * 9
		create_virtualchest(array(
			'id': @id.'1',
			'size': @chestsize2,
			'title': 'Choose a Class'
		))
	}
	@chest = array(array(), array())
	foreach(@class in @pvp['arena']['classes']) {
		if((!array_index_exists(@class, 'team') || @class['team'] == 0)
		&& @size1 > 2
		&& array_index_exists(@class, 'selector')) {
			@chest[0][] = @class['selector']
		}
		if((!array_index_exists(@class, 'team') || @class['team'] == 1)
		&& @size2 > 2
		&& array_index_exists(@class, 'selector')) {
			@chest[1][] = @class['selector']
		}
	}
	if(@chest[0]) {
		@chest[0][@chestsize1 - 1] = array('type': 1, 'data': 7, 'meta': array(
			'display': 'RANDOM',
			'lore': array('Randomly assign a class'),
		));
		update_virtualchest(@id.'0', @chest[0])
	}
	if(@chest[1]) {
		@chest[1][@chestsize2 - 1] = array('type': 1, 'data': 7, 'meta': array(
			'display': 'RANDOM',
			'lore': array('Randomly assign a class'),
		));
		update_virtualchest(@id.'1', @chest[1])
	}
	foreach(@p: @pdata in @pvp['players']) {
		if(@size1 > 2 && (!array_index_exists(@pdata, 'team') || @pdata['team'] == 0)) {
			if(array_index_exists(@pvp['arena'], 'class_picks')) {
				@pvp['players'][@p]['picks'] = @pvp['arena']['class_picks'];
			}
			popen_virtualchest(@p, @id.'0');
		} else if(@size2 > 2 && @pdata['team'] == 1) {
			popen_virtualchest(@p, @id.'1');
		}
	}

	if(@size1 > 2 || @size2 > 2) {
		array_push(@pvp['binds'], @id.'classselector')
		bind(inventory_click, array('id': @id.'classselector'), array('slottype': 'CONTAINER'), @e, @id) {
			@pvp = import('pvp'.@id)
			if(!array_index_exists(@pvp['players'], player())
			|| pworld() !== 'custom'
			|| is_null(@e['slotitem'])
			|| is_null(@e['slotitem']['meta'])
			|| is_null(@e['slotitem']['meta']['display'])) {
				die()
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
					clear_virtualchest(@id.@team, @e['slot']);
					@pvp['team'][@team]['captain'] = player();
				} else if(@pvp['running'] < 2 && array_size(pviewing_virtualchest(@id.@team)) == 1) {
					@captain = false;
					foreach(@name: @player in @pvp['players']) {
						if(@player['team'] == @team && array_index_exists(@player, 'class')
						&& @player['class'] == @pvp['arena']['captain'][@player['team']]) {
							@captain = true;
						}
					}
					if(!@captain) {
						foreach(@slot: @item in get_virtualchest(@id.@team)) {
							if(is_array(@item) && !is_null(@item['meta']) && !is_null(@item['meta']['display'])
							&& @pvp['arena']['captain'][@team] == to_lower(strip_colors(@item['meta']['display']))) {
								clear_virtualchest(@id.@team, @slot);
								@pvp['team'][@team]['captain'] = player();
								@class = @pvp['arena']['captain'][@team];
								break();
							}
						}
					}
				}
			}
			play_sound(ploc(), array('sound': 'CLICK'))
			cancel()

			if(@class === 'random') {
				@classes = @pvp['arena']['classes'];
				if(array_index_exists(@pvp['players'][player()], 'team')) {
					@classes = array_filter(@pvp['arena']['classes'], closure(@key, @value){
						return(!array_index_exists(@value, 'team') || @value['team'] == @pvp['players'][player()]['team']);
					});
				}
				if(@classes) {
					@class = array_rand(@classes, 1, true)[0];
				} else {
					@class = array_rand(@pvp['arena']['classes'], 1, true)[0];
				}
			}
			msg(color('green').to_upper(@class).color('r').' has been selected.');
			if(array_index_exists(@pvp['players'][player()], 'class')) {
				_class('unload', player(), @pvp['players'][player()]['class'], @pvp);
				_class('load', player(), @class, @pvp);
			}
			@pvp['players'][player()]['class'] = @class
			close_pinv()
		}
	}
}

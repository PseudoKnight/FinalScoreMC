proc _class(@action, @player, @class, @pvp) {
	if(array_index_exists(@pvp['arena']['classes'][@class], 'script')) {
		include('../classes.library/'.@class.'.ms')
	}
	
	switch(@action) {
	case 'load':
		if(array_index_exists(@pvp['arena']['classes'][@class], 'doublejump')) {
			set_pflight(@player, true)
			set_pexp(@player, 100)
			bind(player_toggle_flight, array('id': @player.'doublejump'), array('flying': true, 'player': @player), @e) {
				cancel()
				@vel = entity_velocity(puuid())
				set_pvelocity(@vel['x'] * 1.9, 0.9, @vel['z'] * 1.9)
				play_effect(_relative(ploc(), 'up'), 'cloud', array('speed': 0, 'particleCount': 5, 'offsetX': 0.4, 'offsetZ': 0.4, 'offsetY': 0))
				set_pflight(false)
				set_pexp(0)
				queue_delay(900, player().'doublejump')
				queue_push(closure(){
					set_pexp(100)
					set_pflight(true)
				}, player().'doublejump')
			}
		}
		
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
		set_phealth(@player, min(20, pinfo(@player, 5) + 2));
		set_phunger(@player, min(20, phunger(@player) + 4));
		set_psaturation(@player, psaturation(@player) + 2);
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
		play_sound(ploc(@player), array('sound': 'enderman_teleport', 'pitch': 2), @player)
		if(array_index_exists(@pvp['arena']['classes'][@class], 'ammo')) {
			@inv = pinv(@player);
			foreach(@slot: @item in @pvp['arena']['classes'][@class]['ammo']) {
				@max = 64;
				if(array_index_exists(@pvp['arena']['classes'][@class], 'stacklimit')
				&& array_index_exists(@pvp['arena']['classes'][@class]['stacklimit'], @item['type'])) {
					@max = @pvp['arena']['classes'][@class]['stacklimit'][@item['type']];
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
		unbind(@player.'doublejump')
		unbind(@player.'food')
		queue_clear(@player.'doublejump')
		set_pflight(@player, false)
		set_pwalkspeed(@player, 0.2)

	}
}

proc _class_select_random(@player, @pvp) {
	if(array_index_exists(@pvp['players'][@player], 'class')) {
		_class('unload', @player, @pvp['players'][@player]['class'], @pvp);
	}
	@rand = array_rand(@pvp['arena']['classes'], array_size(@pvp['arena']['classes']));
	foreach(@r in @rand) {
		if(!array_index_exists(@pvp['arena']['classes'][@r], 'team')
		|| @pvp['players'][@player]['team'] == @pvp['arena']['classes'][@r]['team']) {
			@pvp['players'][@player]['class'] = @r;
			break();
		}
	}
	if(array_index_exists(@pvp['players'][@player], 'class')) {
		_class('load', @player, @pvp['players'][@player]['class'], @pvp);
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
		if(@size1 > 2
		&& (!array_index_exists(@pdata, 'team') || @pdata['team'] == 0)) {
			if(array_index_exists(@pvp['arena'], 'class_picks')) {
				@pvp['players'][@p]['picks'] = @pvp['arena']['class_picks'];
			}
			popen_virtualchest(@p, @id.'0');
		} else if(@size2 > 2
		&& @pdata['team'] == 1) {
			if(array_index_exists(@pvp['arena'], 'class_picks')) {
				@pvp['players'][@p]['picks'] = @pvp['arena']['class_picks'];
			}
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
			@pvp['players'][player()]
			if(@class !== 'random') {
				if(!array_index_exists(@pvp['arena']['classes'][@class], 'picked')) {
					@pvp['arena']['classes'][@class]['picked'] = 1;
				} else {
					@pvp['arena']['classes'][@class]['picked'] += 1;
				}
			}
			if(array_index_exists(@pvp['arena'], 'captain')) {
				if(array_contains(@pvp['arena']['captain'], @class)) {
					clear_virtualchest(@id.@pvp['players'][player()]['team'], 0);
					@pvp['team'][@pvp['players'][player()]['team']]['captain'] = player();
				} else if(!is_null(@e['inventory'][0])) {
					@count = 0;
					foreach(@name: @player in @pvp['players']) {
						if(@name != player()
						&& @player['team'] == @pvp['players'][player()]['team']
						&& (pget_virtualchest(@p) == @id.@player['team'] 
						|| @player['class'] == @pvp['arena']['captain'][@player['team']])) {
							@count++;
						}
					}
					if(@count == 0) {
						# No players choosing or chose captain
						clear_virtualchest(@id.@pvp['players'][player()]['team'], 0);
						@pvp['team'][@pvp['players'][player()]['team']]['captain'] = player();
						@class = @pvp['arena']['captain'][@pvp['players'][player()]['team']];
					}
				}
			}
			play_sound(ploc(), array('sound': 'CLICK'))
			cancel()
			if(array_index_exists(@pvp['players'][player()], 'class')) {
				_class('unload', player(), @pvp['players'][player()]['class'], @pvp)
			}
			if(@class === 'random') {
				@classes = @pvp['arena']['classes'];
				# if(array_index_exists(@pvp['players'][player()], 'team')) {
					# @classes = array_filter(@pvp['arena']['classes'], closure(@key, @value){
						# return(@value['team'] == @pvp['players'][player()]['team']);
					# });
				# }
				@class = array_rand(@classes, 1, true)[0];
			}
			msg(color('green').to_upper(@class).color('r').' has been selected.');
			@pvp['players'][player()]['class'] = @class
			_class('load', player(), @class, @pvp)
			close_pinv()
		}
	}
}
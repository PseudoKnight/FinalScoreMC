proc('_class', @action, @player, @class, @pvp) {
	if(array_index_exists(@pvp['arena']['classes'][@class], 'script')) {
		include('../classes.library/'.@class.'.ms')
	}
	
	switch(@action) {
	case 'load':
		if(array_index_exists(@pvp['arena']['classes'][@class], 'doublejump')) {
			set_pflight(@player, true)
			set_pexp(@player, 100)
			bind('player_toggle_flight', array('id': @player.'doublejump'), array('flying': true, 'player': @player), @e) {
				cancel()
				@vel = entity_velocity(pinfo(player(), 13))
				set_pvelocity(@vel['x'] * 1.9, 0.9, @vel['z'] * 1.9)
				play_effect(_relative(ploc(), 'up'), 'cloud', array('speed': 0, 'particleCount': 5, 'offsetX': 0.4, 'offsetZ': 0.4, 'offsetY': 0))
				set_pflight(false)
				set_pexp(0)
				queue_delay(1000, player().'doublejump')
				queue_push(closure(){
					set_pexp(100)
					set_pflight(true)
				}, player().'doublejump')
			}
		}
		
		if(array_index_exists(@pvp['arena']['classes'][@class], 'spawner')) {
			bind('player_interact', array('id': @player.'spawner'), array('button': 'right', 'item': 383, 'player': @player), @e) {
				if(@e['action'] == 'right_click_block') {
					cancel()
					@item = pinv(player(), null)
					if(is_null(@item['meta'])
					|| is_null(@item['meta']['display'])) {
						die()
					}
					@loc = _relative(@e['location'], @e['facing'])
					@mob = to_lower(@item['meta']['display'])
					if(!is_null(@item['meta']['lore'])
					&& @item['meta']['lore'][0] == 'Target Near') {
						foreach(@player in players_in_radius(@loc, 20)) {
							if(@player == player(), continue())
							_spawn_mob(@mob, 1, @loc, @player)
						}
					} else {
						_spawn_mob(@mob, 1, @loc, player())
					}
					play_sound(@loc, array('sound': 'ZOMBIE_INFECT', 'pitch': 1.5))
					play_effect(@loc, 'cloud', array('speed': 0, 'particleCount': 10, 'offsetX': 0.4, 'offsetZ': 0.4, 'offsetY': 0.4))

					@item['qty'] -= 1
					if(@item['qty'] > 0) {
						@slot = pinfo(player(), 15)
						@item['type'] = 361
						set_pinv(array(null: @item))
						queue_delay(2000, player().'spawner')
						queue_push(closure(){
							@item = pinv(player(), @slot)
							if(!is_null(@item) && @item['type'] == 361) {
								@item['type'] = 383
								@inv = array()
								@inv[@slot] = @item
								set_pinv(@inv)
							}
						}, player().'spawner')
					} else {
						set_pinv(array(null: null))
					}
				}
			}
		}
		
	case 'equip':
		if(array_index_exists(@pvp['arena']['classes'][@class], 'hunger')) {
			set_phunger(@player, @pvp['arena']['classes'][@class]['hunger'][0])
			set_psaturation(@player, @pvp['arena']['classes'][@class]['hunger'][1])
		}
		if(array_index_exists(@pvp['arena']['classes'][@class], 'kit')) {
			set_pinv(@player, @pvp['arena']['classes'][@class]['kit'])
		}
		if(array_index_exists(@pvp['arena']['classes'][@class], 'speed')) {
			set_pwalkspeed(@player, 0.2) # this workaround is required for after respawns
			set_pwalkspeed(@player, @pvp['arena']['classes'][@class]['speed'])
		}
		if(array_index_exists(@pvp['arena']['classes'][@class], 'effect')) {
			set_timeout(50, closure(){
				foreach(@pvp['arena']['classes'][@class]['effect'], @eid, @e) {
					set_peffect(@player, @eid, @e['strength'], @e['length'], true)
				}
			})
		}
		if(array_index_exists(@pvp['arena']['classes'][@class], 'xp')) {
			set_pexp(@player, @pvp['arena']['classes'][@class]['xp'])
		}
		
	case 'powerup':
		set_phealth(@player, min(20, pinfo(@player, 5) + 2))
		set_phunger(@player, min(20, phunger(@player) + 2))
		@flash = true
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
			@inv = pinv(@player)
			foreach(@slot: @item in @pvp['arena']['classes'][@class]['ammo']) {
				@item = @item[]
				if(!is_null(@inv[@slot])) {
					@item['qty'] = min(64, @item['qty'] + @inv[@slot]['qty'])
				}
				@inv[@slot] = @item
			}
			set_pinv(@player, @inv)
		}
		
	case 'unload':
		unbind(@player.'feed')
		unbind(@player.'doublejump')
		unbind(@player.'spawner')
		unbind(@player.'target')
		queue_clear(@player.'doublejump')
		set_pflight(@player, false)
		set_pwalkspeed(@player, 0.2)

	}
}

proc('_class_select', @id, @pvp) {
	@size1 = 0
	@size2 = 0
	foreach(@class in @pvp['arena']['classes']) {
		if(!array_index_exists(@class, 'team') || @class['team'] == 0) {
			@size1 += 1
		}
		if(!array_index_exists(@class, 'team') || @class['team'] == 1) {
			@size2 += 1
		}
	}
	if(@size1 > 1) {
		@chestsize1 = ceil(@size1 / 9) * 9
		create_virtualchest(array(
			'id': @id.'0',
			'size': @chestsize1,
			'title': 'Choose a Class'
		))
	}
	if(@size2 > 1) {
		@chestsize2 = ceil(@size2 / 9) * 9
		create_virtualchest(array(
			'id': @id.'1',
			'size': @chestsize2,
			'title': 'Choose a Class'
		))
	}
	foreach(@class in @pvp['arena']['classes']) {
		if((!array_index_exists(@class, 'team') || @class['team'] == 0)
		&& @size1 > 1
		&& array_index_exists(@class, 'selector')) {
			addto_virtualchest(@id.'0', 
				@class['selector']['type'].':'.@class['selector']['data'], 
				@class['selector']['qty'],
				@class['selector']['meta']
			)
		}
		if((!array_index_exists(@class, 'team') || @class['team'] == 1)
		&& @size2 > 1
		&& array_index_exists(@class, 'selector')) {
			addto_virtualchest(@id.'1', 
				@class['selector']['type'].':'.@class['selector']['data'], 
				@class['selector']['qty'],
				@class['selector']['meta']
			)
		}
	}
	foreach(@pvp['players'], @p, @pdata) {
		if(@size1 > 1
		&& (!array_index_exists(@pdata, 'team') || @pdata['team'] == 0)) {
			popen_virtualchest(@p, @id.'0')
		} else if(@size2 > 1
		&& @pdata['team'] == 1) {
			popen_virtualchest(@p, @id.'1')
		}
	}

	if(@size1 > 1 || @size2 > 1) {
		array_push(@pvp['binds'], @id.'classselector')
		bind('inventory_click', array('id': @id.'classselector'), array('slottype': 'CONTAINER'), @e, @id = @id) {
			@pvp = import('pvp'.@id)
			if(!array_index_exists(@pvp['players'], player())
			|| is_null(@e['slotitem'])
			|| is_null(@e['slotitem']['meta'])
			|| is_null(@e['slotitem']['meta']['display'])) {
				die()
			}
			@class = to_lower(strip_colors(@e['slotitem']['meta']['display']))
			if(!array_index_exists(@pvp['arena']['classes'], @class)) {
				die()
			}
			if(array_index_exists(@pvp['arena'], 'captain')
			&& array_contains(@pvp['arena']['captain'], @class)) {
				clear_virtualchest(@id.@pvp['players'][player()]['team'], 0)
				@pvp['team'][@pvp['players'][player()]['team']]['captain'] = player()
			}
			play_sound(ploc(), array('sound': 'CLICK'))
			cancel()
			if(array_index_exists(@pvp['players'][player()], 'class')) {
				_class('unload', player(), @pvp['players'][player()]['class'], @pvp)
			}
			@pvp['players'][player()]['class'] = @class
			_class('load', player(), @class, @pvp)
			close_pinv()
			export('pvp'.@id, @pvp)
		}
	}
}
proc('_class', @action, @player, @class) {
	switch(@class) {
	case 'vector':
		switch(@action) {
		case 'load':
			bind('player_interact', array('id': @player.'interact'), array('player': @player, 'button': 'right', 'item': '292'), @e) {
				cancel()
				if(get_block_at(ploc())[0] == '0', die())
				@facing = pfacing(player())
				@facing[0] = @facing[0] + 90
				@facing[1] = 0 - @facing[1]
				@x = 1.45 * cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
				@y = max((1.45 * sin(to_radians(@facing[1]))) + 0.2, 0.2)
				@z = 1.45 * sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
				set_timeout(50, closure(){
					set_pvelocity(player(), @x, @y, @z)
					play_sound(ploc(), array('sound': 'GHAST_CHARGE', 'pitch': 2, 'volume': 2))
					if(psaturation() > 1) {
						set_psaturation(psaturation() - 1)
					} else if(phunger() >= 1) {
						set_phunger(phunger() - 1)
					}
				})
			}
			bind('entity_damage', array('id': @player.'falldamage'), array('type': 'PLAYER', 'cause': 'FALL', 'world': 'custom'), @e, @p = @player) {
				if(@e['player'] == @p, cancel())
			}
			bind('entity_damage', array('id': @player.'damage'), array('type': 'PLAYER', 'cause': 'ENTITY_ATTACK', 'world': 'custom'), @e, @p = @player) {
				if(@e['damager'] == @p, modify_event('amount', 16))
				if(@e['player'] == @p && is_numeric(@e['damager']) && to_lower(entity_type(@e['damager'])) == 'zombie', cancel())
			}
			bind('player_death', array('id': @player.'death'), array('player': @player), @e) {
				play_sound(ploc(), array('sound': 'GHAST_DEATH', 'pitch': 0))
			}
			
			proc('_manti_noise', @player) {
				if(ponline(@player)) {
					if(pinfo(@player, 5) > 0) {
						play_sound(ploc(@player), array('sound': 'CAT_PURREOW', 'pitch': 0, 'volume': 2))
					}
					queue_delay(1000 * rand(6, 20), @player)
					queue_push(closure(_manti_noise()), @player)
				}
			}
			_manti_noise(@player)
			set_pwalkspeed(@player, 0.23)
			tmsg(@player, 'Right-click to leap.')
			
		case 'equip':
			set_pinv(@player, array(
				0: array('type': 292, 'meta': array('display': 'Claw', 'lore': array('Right-click to leap'))),
				103: array('type': 120),
				102: array('type': 299, 'meta': array('color': array('r': 255, 'g': 255, 'b': 170))),
				101: array('type': 300, 'meta': array('color': array('r': 255, 'g': 255, 'b': 170))),
				100: array('type': 301, 'meta': array('color': array('r': 255, 'g': 255, 'b': 170)))
			))
			set_timeout(50, closure(){
				set_peffect(@player, 14, 0, 999, true)
				set_peffect(@player, 16, 0, 999, true)
			})
	
		case 'unload':
			unbind(@player.'interact')
			unbind(@player.'falldamage')
			unbind(@player.'damage')
			unbind(@player.'death')
			queue_clear(@player)
			set_pwalkspeed(@player, 0.2)
			set_peffect(@player, 14, 0, 0)
		}
		
	case 'human':
		switch(@action) {
		case 'load':
			bind('player_interact', array('id': @player.'interact'), array('player': @player, 'button': 'right', 'item': 359), @e) {
				if(split(':', @e['block'])[0] != '77' && pexp() >= 99) {
					cancel()
					@arrow = shoot_projectile(player(), 'ARROW')
					@velocity = entity_velocity(@arrow)
					set_entity_velocity(@arrow, array(@velocity['x'] * 3, @velocity['y'] * 3, @velocity['z'] * 3))
					set_entity_onfire(@arrow, 1)
					play_sound(ploc(), array('sound': 'ENDERDRAGON_HIT', 'pitch': 2))
					set_pexp(0)
					set_timeout(500, closure(){
						if(ponline(player()) && pinfo(player(), 5) > 0) {
							set_pexp(99)
						}
					})
				}
			}
			bind('projectile_hit', array('id': @player.'hit'), array('type': 'ARROW'), @e, @shooter = pinfo(@player, 13)) {
				if(@e['shooter'] == @shooter && entity_type(@e['id']), try(entity_remove(@e['id'])))
			}
			bind('entity_damage', array('id': @player.'damage'), array('cause': 'PROJECTILE', 'world': 'custom'), @e, @p = @player) {
				if(@e['shooter'] == @p, modify_event('amount', 28))
			}
			bind('player_death', array('id': @player.'death'), array('player': @player), @e) {
				play_sound(ploc(), array('sound': 'ZOMBIE_UNFECT', 'pitch': 1, 'volume': 3))
			}
			set_pwalkspeed(@player, 0.16)
			tmsg(@player, 'Right-click to fire.')
			
		case 'equip':
			set_pinv(@player, array(
				0: array('type': 359, 'meta': array('display': 'Plasma Gun', 'lore': array('Right-click to fire.', 'Quickly re-charges.', 'Developed by Frog Co.'))),
				103: array('type': 20),
				102: array('type': 307),
				101: array('type': 308),
				100: array('type': 309)
			))
			set_pexp(@player, 99)
			set_timeout(50, closure(){
				set_peffect(@player, 8, -1, 999, true)
				set_phunger(@player, 3)
			})
			
		case 'unload':
			unbind(@player.'interact')
			unbind(@player.'hit')
			unbind(@player.'damage')
			unbind(@player.'death')
			set_pwalkspeed(@player, 0.2)
			set_peffect(@player, 8, 0, 0)
		}
		
	default: 
		@class = get_value('class', @class)
		if(!@class, return(false))
		switch(@action) {
		case 'load':
			if(array_index_exists(@class, 'doublejump')) {
				set_pflight(@player, true)
				bind('player_toggle_flight', array('id': @player.'doublejump'), array('flying': true), @e) {
					cancel()
					@vel = entity_velocity(pinfo(player(), 13))
					if(@vel['y'] < 0) {
						@y = abs(@vel['y']) * 3
					} else {
						@y = @vel['y'] * 2
					}
					set_pvelocity(@vel['x'] * 2, @y, @vel['z'] * 2)
				}
			}
			
		case 'equip':
			if(array_index_exists(@class, 'kit')) {
				set_pinv(@player, @class['kit'])
			}
			if(array_index_exists(@class, 'effect')) {
				set_timeout(50, closure(){
					foreach(@class['effect'], @eid, @e) {
						set_peffect(@player, @eid, @e['strength'], @e['length'], true)
					}
				})
			}
			
		case 'unload':
			unbind(@player.'doublejump')
			set_pflight(@player, false)
		
		}
	}
}

proc('_class_select', @id, @pvp) {
	@size = array_size(@pvp['arena']['classes'][0]) + if(array_index_exists(@pvp['arena'], 'captain'), 1, 0)
	if(@size > 1) {
		@size = ceil(@size / 9) * 9
		create_virtualchest(array(
			'id': @id.'0',
			'size': @size,
			'title': 'Choose a Class'
		))
		if(array_index_exists(@pvp['arena'], 'captain')) {
			@class = get_value('class.'.@pvp['arena']['captain'][0])
			addto_virtualchest(@id.'0', 
				@class['selector']['type'].':'.@class['selector']['data'], 
				@class['selector']['qty'],
				@class['selector']['meta']
			)
		}
		for(@i = 0, @i < array_size(@pvp['arena']['classes'][0]), @i++) {
			@class = get_value('class.'.@pvp['arena']['classes'][0][@i])
			if(!@class, continue())
			addto_virtualchest(@id.'0', 
				@class['selector']['type'].':'.@class['selector']['data'], 
				@class['selector']['qty'],
				@class['selector']['meta']
			)
		}
		foreach(@pvp['players'], @p, @pdata) {
			if(!array_index_exists(@pdata, 'team') || @pdata['team'] == 0) {
				popen_virtualchest(@p, @id.'0')
			}
		}
	}
	@size = array_size(@pvp['arena']['classes'][1]) + if(array_index_exists(@pvp['arena'], 'captain'), 1, 0)
	if(@size > 1) {
		@size = ceil(@size / 9) * 9
		create_virtualchest(array(
			'id': @id.'1',
			'size': @size,
			'title': 'Choose a Class'
		))
		if(array_index_exists(@pvp['arena'], 'captain')) {
			@class = get_value('class.'.@pvp['arena']['captain'][1])
			addto_virtualchest(@id.'1', 
				@class['selector']['type'].':'.@class['selector']['data'], 
				@class['selector']['qty'],
				@class['selector']['meta']
			)
		}
		for(@i = 0, @i < array_size(@pvp['arena']['classes'][1]), @i++) {
			@class = get_value('class.'.@pvp['arena']['classes'][1][@i])
			if(!@class, continue())
			addto_virtualchest(@id.'1', 
				@class['selector']['type'].':'.@class['selector']['data'], 
				@class['selector']['qty'],
				@class['selector']['meta']
			)
		}
		foreach(@pvp['players'], @p, @pdata) {
			if(!pget_virtualchest(@p) && @pdata['team'] == 1) {
				popen_virtualchest(@p, @id.'1')
			}
		}
	}
	if(array_size(@pvp['arena']['classes'][0]) > 1 || array_size(@pvp['arena']['classes'][1]) > 1) {
		array_push(@pvp['binds'], @id.'classselector')
		bind('inventory_click', array('id': @id.'classselector'), array('slottype': 'CONTAINER'), @e, @id = @id) {
			@pvp = import('pvp'.@id)
			if(!array_index_exists(@pvp['players'], player())
			|| is_null(@e['slotitem'])
			|| is_null(@e['slotitem']['meta'])
			|| is_null(@e['slotitem']['meta']['display'])) {
				die()
			}
			@class = strip_colors(@e['slotitem']['meta']['display'])
			if((!array_index_exists(@pvp, 'team')
			&& array_contains_ic(@pvp['arena']['classes'][0], @class))
			|| (array_index_exists(@pvp, 'team')
			&& (array_contains_ic(@pvp['arena']['classes'][@pvp['players'][player()]['team']], @class)
			|| equals_ic(@class, @pvp['arena']['captain'][@pvp['players'][player()]['team']])))) {
				play_sound(ploc(), array('sound': 'CLICK'))
				cancel()
				@class = to_lower(@class)
				if(@pvp['arena']['captain'][@pvp['players'][player()]['team']] == @class) {
					clear_virtualchest(@id.@pvp['players'][player()]['team'], 0)
					@pvp['team'][@pvp['players'][player()]['team']]['captain'] = player()
				}
				if(array_index_exists(@pvp['players'][player()], 'class')) {
					_class('unload', player(), @pvp['players'][player()]['class'])
				}
				@pvp['players'][player()]['class'] = @class
				_class('load', player(), @class)
				close_pinv()
				export('pvp'.@id, @pvp)
			}
		}
	}
}
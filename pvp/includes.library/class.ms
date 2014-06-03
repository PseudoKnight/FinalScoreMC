proc('_class', @action, @player, @class, @pvp) {
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
				@x = 1.40 * cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
				@y = max((1.40 * sin(to_radians(@facing[1]))) + 0.2, 0.2)
				@z = 1.40 * sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
				set_timeout(50, closure(){
					set_pvelocity(player(), @x, @y, @z)
					play_sound(ploc(), array('sound': 'GHAST_CHARGE', 'pitch': 2, 'volume': 2))
					if(psaturation() >= 1) {
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
				if(@e['damager'] == @p) {
					@armor = pinv(@e['player'], 102)
					if(@armor && @armor['type'] == 307) {
						modify_event('amount', 16)
						play_sound(ploc(@e['player']), array('sound': 'ZOMBIE_WOODBREAK', 'pitch': 2))
					} else {
						modify_event('amount', 9)
					}
				} else if(@e['player'] == @p 
				&& is_numeric(@e['damager'])
				&& entity_type(@e['damager']) == 'ZOMBIE') {
					cancel()
				}
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
					set_timeout(450, closure(){
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
		switch(@action) {
		case 'load':
			if(array_index_exists(@pvp['arena']['classes'][@class], 'doublejump')) {
				set_pflight(@player, true)
				set_pexp(@player, 100)
				bind('player_toggle_flight', array('id': @player.'doublejump'), array('flying': true, 'player': @player), @e) {
					cancel()
					@vel = entity_velocity(pinfo(player(), 13))
					set_pvelocity(@vel['x'] * 1.9, 0.9, @vel['z'] * 1.9)
					set_pflight(false)
					set_pexp(0)
					set_timeout(1000, closure(){
						set_pexp(100)
						set_pflight(true)
					})
				}
			}
			
			if(array_index_exists(@pvp['arena']['classes'][@class], 'speed')) {
				set_pwalkspeed(@player, @pvp['arena']['classes'][@class]['speed'])
			}
			
			if(array_index_exists(@pvp['arena']['classes'][@class], 'feed')) {
				bind('player_death', array('id': @player.'feed'), null, @e, @player = @player.'', @feedamount = @pvp['arena']['classes'][@class]['feed']) {
					if(@player == @e['killer']) {
						set_phunger(@e['killer'], min(20, phunger(@e['killer']) + @feedamount[0]))
						set_psaturation(@e['killer'], min(20, psaturation(@e['killer']) + @feedamount[1]))
						play_sound(ploc(@e['killer']), array('sound': 'EAT', 'pitch': 0.7))
						set_timeout(500, closure(){
							play_sound(ploc(@e['killer']), array('sound': 'EAT', 'pitch': 0.7))
						})
					}
				}
			}
			
			if(array_index_exists(@pvp['arena']['classes'][@class], 'spawner')) {
				bind('player_interact', array('id': @player.'spawner'), array('button': 'right', 'item': 383, 'player': @player), @e) {
					if(@e['action'] == 'right_click_block') {
						cancel()
						@item = pinv(player(), null)
						switch(@item['data']) {
						case 54:
							@mob = 'ZOMBIE'
						case 51:
							@mob = 'SKELETON'
						default:
							die()
						}
						@loc = _relative(@e['location'], 'up')
						@entity = spawn_mob(@mob, 1, @loc)[0]
						play_sound(@loc, array('sound': 'ZOMBIE_INFECT', 'pitch': 1.5))
						
						if(@mob == 'SKELETON') {
							queue_push(closure(){
								set_mob_equipment(@entity, array('WEAPON': array('type': 261)))
							}, player().'spawner')
						}
						
						@item['qty'] -= 1
						if(@item['qty'] > 0) {
							@slot = pinfo(player(), 15)
							@item['type'] = 361
							set_pinv(array(null: @item))
							queue_delay(100, player().'spawner')
							queue_push(closure(){
								@item['type'] = 383
								@inv = array()
								@inv[@slot] = @item
								set_pinv(@inv)
							}, player().'spawner')
						} else {
							set_pinv(array(null: null))
						}
					}
				}
				
				bind('target_player', array('id': @player.'target'), array('player': @player), @e) {
					cancel()
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
			if(array_index_exists(@pvp['arena']['classes'][@class], 'effect')) {
				set_timeout(50, closure(){
					foreach(@pvp['arena']['classes'][@class]['effect'], @eid, @e) {
						set_peffect(@player, @eid, @e['strength'], @e['length'], true)
					}
				})
			}
			
		case 'unload':
			unbind(@player.'feed')
			unbind(@player.'doublejump')
			unbind(@player.'spawner')
			unbind(@player.'target')
			set_pflight(@player, false)
			set_pwalkspeed(@player, 0.2)
		}
	}
}

proc('_class_select', @id, @pvp) {
	@size1 = 0
	@size2 = 0
	foreach(@class in @pvp['arena']['classes']) {
		if(!array_index_exists(@class, 'team') || @class['team'] == 0) {
			@size1 += 1
		}
		if(array_index_exists(@class, 'team') && @class['team'] == 1) {
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
		if((array_index_exists(@class, 'team') && @class['team'] == 1)
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
		&& !array_index_exists(@pdata, 'team') || @pdata['team'] == 0) {
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
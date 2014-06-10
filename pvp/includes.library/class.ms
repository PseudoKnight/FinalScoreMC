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
					@helm = pinv(@e['player'], 102)
					if(@armor && @armor['type'] == 20) {
						modify_event('amount', 16)
					} else {
						modify_event('amount', 8)
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
			
		case 'equip':
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
			
		case 'equip':
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
			set_peffect(@player, 8, 0, 0)
		}
	
	case 'werewolf':
		switch(@action) {
		case 'load':
			bind('entity_damage_player', array('id': @player.'werewolf'), null, @e, @p = @player) {
				if(@e['player'] == @p) {
					if(is_null(pinv(@p, 103))) {
						set_peffect(@p, 1, 2, 20)
						set_peffect(@p, 16, 0, 25)
						set_peffect(@p, 5, 3, 20)
						play_sound(ploc(@p), array('sound': 'WOLF_HOWL', 'pitch': 0.9, 'volume': 2))
						set_pinv(@p, array(
							100: array('type': 301, 'meta': array('color': array('r': 50, 'g': 50, 'b': 50))),
							101: array('type': 300, 'meta': array('color': array('r': 50, 'g': 50, 'b': 50))),
							102: array('type': 299, 'meta': array('color': array('r': 50, 'g': 50, 'b': 50))),
							103: array('type': 35, 'data': 7),
						))
						queue_clear(@p.'evolve')
						queue_delay(20000, @p.'evolve')
						queue_push(closure(){
							@r = rand(0, 256)
							@g = rand(0, 256)
							@b = rand(0, 256)
							set_pinv(@p, array(
								100: array('type': 301, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
								101: array('type': 300, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
								102: array('type': 299, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
								103: null,
							))
							_clear_peffects(@p)
						}, @p.'evolve')
					} else {
						play_sound(ploc(@p), array('sound': 'WOLF_HURT', 'pitch': 0.75))
					}
				} else if(@e['data'] == @p && !is_null(pinv(@p, 103)) && !rand(4)) {
					play_sound(ploc(@p), array('sound': 'WOLF_GROWL', 'pitch': 0.9))
				}
			}
			
			bind('player_death', array('id': @player.'kill'), null, @e, @player = @player) {
				if(@e['killer'] == @player) {
					set_phealth(@player, min(20, pinfo(@player, 5) + 4))
					play_sound(ploc(@player), array('sound': 'EAT', 'pitch': 0.5))
				}
			}
			
		case 'equip':
			@r = rand(0, 256)
			@g = rand(0, 256)
			@b = rand(0, 256)
			set_pinv(@player, array(
				100: array('type': 301, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
				101: array('type': 300, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
				102: array('type': 299, 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
			))
		
		case 'unload':
			unbind(@player.'werewolf')
			unbind(@player.'kill')
			queue_clear(@player.'evolve')
		
		}
		
	case 'ninja':
		switch(@action) {
		case 'load':
			@armor = array(
				100: @pvp['arena']['classes'][@class]['kit'][100],
				101: @pvp['arena']['classes'][@class]['kit'][101],
				102: @pvp['arena']['classes'][@class]['kit'][102],
				103: @pvp['arena']['classes'][@class]['kit'][103],
			)
			bind('player_toggle_sneak', array('id': @player.'ninja'), array('player': @player), @e, @armor) {
				if(@e['sneaking']) {
					set_pinv(array(
						100: null,
						101: null,
						102: null,
						103: null,
					))
					set_peffect(player(), 16, 0, 30)
					set_peffect(player(), 14, 0, 30)
					play_effect(_relative(ploc(), 'up', 2), 'spell', array('speed': 0, 'particleCount': 10, 'offsetY': 0.4, 'offsetX': 0.2, 'offsetZ': 0.2))
				} else {
					set_pinv(@armor)
					set_peffect(player(), 14, 0, 0)
					set_peffect(player(), 16, 0, 0)
					play_effect(_relative(ploc(), 'up', 2), 'spell', array('speed': 0, 'particleCount': 10, 'offsetY': 0.4, 'offsetX': 0.2, 'offsetZ': 0.2))
				}
			}
		
		case 'unload':
			unbind(@player.'ninja')
		
		}
	
	case 'necromancer':
		switch(@action) {
		case 'load':		
			bind('target_player', array('id': @player.'necrotarget'), array('player': @player), @e) {
				cancel()
			}
			bind('entity_damage', array('id': @player.'necrodamage', 'priority': 'HIGH'), array('type': 'PLAYER', 'world': 'custom'), @e, @p = @player) {
				if(@e['player'] == @p 
				&& ((array_index_exists(@e, 'damager')
				&& is_numeric(@e['damager'])
				&& entity_type(@e['damager']) == 'ZOMBIE')
				|| (array_index_exists(@e, 'shooter')
				&& is_numeric(@e['shooter'])
				&& entity_type(@e['shooter']) == 'SKELETON'))) {
					cancel()
					consume()
				}
			}
			
		case 'unload':
			unbind(@player.'necrotarget')
			unbind(@player.'necrodamage')
		}
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
					@mob = to_lower(@item['meta']['display'])
					@loc = ptarget_space()
					_spawn_mob(@mob, 1, @loc, player())
					play_sound(@loc, array('sound': 'ZOMBIE_INFECT', 'pitch': 1.5))
					play_effect(@loc, 'cloud', array('speed': 0, 'particleCount': 10, 'offsetX': 0.4, 'offsetZ': 0.4, 'offsetY': 0.4))

					@item['qty'] -= 1
					if(@item['qty'] > 0) {
						@slot = pinfo(player(), 15)
						@item['type'] = 361
						set_pinv(array(null: @item))
						queue_delay(2000, player().'spawner')
						queue_push(closure(){
							if(!is_null(pinv(player(), @slot))) {
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
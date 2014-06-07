if(array_contains(@pvp['arena']['weapons'], 'railgun')) {
	array_push(@pvp['binds'], @id.'railgun')
	bind('player_interact', array('id': @id.'railgun'), array('item': 175, 'button': 'right'), @e, assign(@id, @id)) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())
		@origin = _relative(ploc(), 'up', 2.3)
		@facing = pfacing(player())
		@facing[0] = @facing[0] + 90
		@facing[1] = 0 - @facing[1]
		@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
		@y = sin(to_radians(@facing[1]))
		@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]))
		@n = 0
		@loc = @origin[]
		while(@n < 100) {
			@loc['x'] += @x
			@loc['y'] += @y
			@loc['z'] += @z
			if(get_block_info(@loc)['solid']) {
				play_effect(@loc, 'lava_pop', array('particleCount': 8))
				break()
			} else {
				if(rand(2)) {
					play_effect(@loc, 'cloud', array('speed': 0))
				} else {
					play_effect(@loc, 'crit', array('speed': 0, 'radius': 64))
				}
				@n++
			}
		}
		
		foreach(@player in array_keys(@pvp['players'])) {
			if(@player == player(), continue())
			@ploc = ploc(@player)
			@ploc['y'] += 1.5
			@dist = _squared_distance_to_segment(@ploc, @origin, @loc)
			@hit = false
			if(@dist < 0.5625) { # 0.75 ^ 2
				@hit = true
			} else if(@dist < 2.25) { # (0.75 * 2) ^ 2
				@ploc['y'] += 1
				@dist = _squared_distance_to_segment(@ploc, @origin, @loc)
				if(@dist < 0.5625) { # 0.75 ^ 2
					@hit = true
				}
			}
			if(@hit) {
				damage_entity(pinfo(@player, 13), 19)
				play_effect(@loc, 'lava_pop', array('particleCount': 8))
			}
		}
		
		play_sound(ploc(), array('sound': 'ZOMBIE_REMEDY', 'pitch': 1.8, 'volume': 3))
		@item = pinv(player(), null)
		@item['type'] = 402
		set_pinv(array(null: @item))
		@slot = pinfo(player(), 15)
		set_timeout(10000, closure(){
			if(!is_null(pinv(player(), @slot))) {
				play_sound(ploc(), array('sound': 'ORB_PICKUP'))
				@inv = array()
				@item['type'] = 175
				@inv[@slot] = @item
				set_pinv(@inv)
			}
		})
	}
}

if(array_contains(@pvp['arena']['weapons'], 'endernades')) {
	array_push(@pvp['binds'], @id.'endernades')
	bind('player_teleport', array('id': @id.'endernades'), array('type': 'ENDER_PEARL'), @e, assign(@id, @id)) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())
		explosion(@e['to'], 2)
		if(function_exists('play_effect')) {
			play_effect(@e['to'], 'EXPLOSION_LARGE')
		}
		cancel()
	}

	array_push(@pvp['binds'], @id.'endernadesreload')
	bind('player_interact', array('id': @id.'endernadesreload', 'priority': 'highest'), array('item': 368, 'button': 'right'), @e, assign(@id, @id)) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())
		cancel()
		shoot_projectile(player(), 'ENDER_PEARL')
		play_sound(ploc(), array('sound': 'SHOOT_ARROW', 'pitch': 0.5))
		@item = pinv(player(), null)
		@item['qty'] -= 1
		if(@item['qty'] == 0) {
			set_pinv(array(null: null))
		} else {
			@item['type'] = 378
			set_pinv(array(null: @item))
			@slot = pinfo(player(), 15)
			set_timeout(800, closure(){
				if(pinv(player(), @slot) && pinv(player(), @slot)['type'] == 378) {
					play_sound(ploc(), array('sound': 'IRONGOLEM_THROW'))
					@inv = array()
					@item['type'] = 368
					@inv[@slot] = @item
					set_pinv(@inv)
				}
			})
		}
	}
}

if(array_contains(@pvp['arena']['weapons'], 'skullrockets')) {
	array_push(@pvp['binds'], @id.'interactskulls')
	bind('player_interact', array('id': @id.'interactskulls'), array('item': 397, 'button': 'right'), @e, assign(@id, @id)) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())
		if(@e['item'] != '397:1', die())

		@skull = shoot_projectile(player(), 'wither_skull')
		ptake_item('397:1', 1)
		cancel()
	}
}

if(array_contains(@pvp['arena']['weapons'], 'primedtnt')) {
	array_push(@pvp['binds'], @id.'primedtnt')
	bind('player_interact', array('id': @id.'primedtnt'), array('item': 46, 'button': 'right'), @e, assign(@id, @id)) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player())
		|| @e['action'] != 'right_click_block', die())
		cancel()
		if(@loc = _relative(@e['location'], @e['facing'])) {
			@loc = array(@loc[0] + 0.5, @loc[1] + 0.5, @loc[2] + 0.5, @loc[3])
			ptake_item(46, 1)
			@tnt = spawn_entity('PRIMED_TNT', 1, @loc)[0]
			set_entity_spec(@tnt, array('fuseticks': 60))
		}
	}
}

if(array_contains(@pvp['arena']['weapons'], 'shotgunballs')) {
	array_push(@pvp['binds'], @id.'shotgunshoot')
	bind('player_interact', array('id': @id.'shotgunshoot'), array('item': 332, 'button': 'right'), @e, assign(@id, @id)) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())
		cancel()
		@entities = array()
		for(@i = 0, @i < 8, @i++) {
			@entities[@i] = shoot_projectile(player(), 'SNOWBALL')
			@v = entity_velocity(@entities[@i])
			set_entity_velocity(@entities[@i], array(@v['x'] * 3.4 + ((rand(3) - 1)), @v['y'] * 3.4 + ((rand(3) - 1)), @v['z'] * 3.4 + ((rand(3) - 1))))
		}
		play_sound(ploc(), array('sound': 'ZOMBIE_WOOD', 'pitch': 1.5, 'volume': 2))
		play_sound(ploc(), array('sound': 'EXPLODE', 'pitch': 2, 'volume': 2))
		@item = pinv(player(), null)
		@item['qty'] = @item['qty'] - 1
		if(@item['qty'] == 0) {
			set_pinv(array(null: null))
		} else {
			@item['type'] = 341
			set_pinv(array(null: @item))
			@slot = pinfo(player(), 15)
			set_timeout(300, closure(){
			for(@i = 0, @i < 8, @i++) {
				if(entity_exists(@entities[@i]), entity_remove(@entities[@i]))
			}
			set_timeout(600, closure(){
				if(pinv(player(), @slot) && pinv(player(), @slot)['type'] == 341) {
					play_sound(ploc(), array('sound': 'PISTON_RETRACT', 'pitch': 1.5))
					@inv = array()
					@item['type'] = 332
					@inv[@slot] = @item
					set_pinv(@inv)
				}
			})
			})
		}
	}
	array_push(@pvp['binds'], @id.'shotgunreload')
	bind('entity_damage', array('id': @id.'shotgunreload'), array('type': 'PLAYER', 'cause': 'PROJECTILE', 'world': 'custom'), @e, assign(@id, @id)) {
		if(ponline(@e['shooter'])) {
			@pvp = import('pvp'.@id)
			if(array_index_exists(@pvp['players'], @e['shooter'])
			&& pinv(@e['shooter'], null)
			&& pinv(@e['shooter'], null)['type'] == 341) {
				modify_event('amount', 8)
			}
		}
	}
}

if(array_contains(@pvp['arena']['weapons'], 'pistoltears')) {
	array_push(@pvp['binds'], @id.'pistoltears')
	bind('player_interact', array('id': @id.'pistoltears'), array('item': 370, 'button': 'right'), @e, assign(@id, @id)) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())
		@entity = shoot_projectile(player(), 'ARROW')
		@v = entity_velocity(@entity)
		set_entity_velocity(@entity, array(@v['x'] * 3, @v['y'] * 3, @v['z'] * 3))
		play_sound(ploc(), array('sound': 'ZOMBIE_WOOD', 'pitch': 2, 'volume': 2))
		@item = pinv(player(), null)
		@item['qty'] = @item['qty'] - 1
		if(@item['qty'] == 0) {
			set_pinv(array(null: null))
		} else {
			@item['type'] = 371
			set_pinv(array(null: @item))
			@slot = pinfo(player(), 15)
			set_timeout(2000, closure(){
				if(pinv(player(), @slot) && pinv(player(), @slot)['type'] == 371) {
					play_sound(ploc(), array('sound': 'DOOR_OPEN', 'pitch': 2))
					@inv = array()
					@item['type'] = 370
					@inv[@slot] = @item
					set_pinv(@inv)
				}
			})
		}
	}
}

if(array_contains(@pvp['arena']['weapons'], 'firefire')) {
	array_push(@pvp['binds'], @id.'firefire')
	bind('player_interact', array('id': @id.'firefire'), array('item': 259), @e, assign(@id, @id)) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player())
		|| !array_index_exists(@e, 'location'), die())
		@loc = ptarget_space()
		if(sk_region_check_flag(@loc, 'lighter')) {
			set_block_at(@loc, '51:0')
		}
	}
}
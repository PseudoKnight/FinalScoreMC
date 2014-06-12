set_interval(8 * 60 * 1000, closure(){
	if(player() == '~console') {
		run('/save-all')
	} else {
		runas('~console', '/save-all')
	}
})

bind('player_login', null, null, @event) {
	if(@event['result'] != 'ALLOWED', die())
	@update = false
	@pdata = get_value('player.'.to_lower(@event['player']))
	if(!@pdata) {
		@pdata = array('ips': array())
	}
	if(array_index_exists(@pdata, 'ban')) {
		if(!array_index_exists(@pdata['ban'], 'time') || @pdata['ban']['time'] > time()) {
			modify_event('result', 'KICK_BANNED')
			if(array_index_exists(@pdata['ban'], 'message')) {
				modify_event('kickmsg', @pdata['ban']['message'])
			} else {
				modify_event('kickmsg', 'Banned. Appeal at FinalScoreMC.com')
			}
			die()
		} else {
			array_remove(@pdata, 'ban')
			console('Ban on '.@event['player'].' expired.')
			@update = true
		}
	}
	if(get_server_info(10)) {
		if(!array_index_exists(@pdata, 'ips'), @pdata['ips'] = array())
		if(!array_contains(@pdata['ips'], @event['ip'])) {
			@pdata['ips'][] = @event['ip']
			if(array_size(@pdata['ips']) > 2) {
				array_remove(@pdata['ips'], 0)
			}
			@update = true
		}

	} else {
		if(!array_contains(@pdata['ips'], @event['ip'])) {
			console(@event['player'].': '.@event['ip'].', '.@pdata['ips'])
			modify_event('result', 'KICK_OTHER')
			modify_event('kickmsg', 'Minecraft auth servers are down and your IP doesn\'t match our records.')
		}
	}
	if(@update) {
		store_value('player.'.to_lower(@event['player']), @pdata)
	}
}

# Player join messages and tab list colors
bind('player_join', null, null, @event) {
	set_timeout(250, closure(@loc = ploc(), @player = player()){
		if(!ponline(@player), die())
		#Store the player's UUID
		_bm_request('set_user_uuid', 'a1634f37480a4bb9a0b2200266597ac0', 
			array('username': @player, 'user_uuid': entity_uuid(pinfo(@player, 13))),
			closure(@result, console('User UUID stored in the ban manager.')), 
			closure(@error_msg, console('Error while storing the UUID in the ban manager. Error: '.@error_msg))
		)
		#Welcome messages
		msg(color('1').color('l').'--------------------')
		msg(color('gold').' \u2302'.color('red').' \u2302'.color('aqua').' \u2302'.color('dark_red').' \u2302'.color('gold').color('l').' FINALSCORE '.color('yellow').color('l').'\u00AB'.color('r').' \u25AA \u25AA \u25AA')
		msg(color('1').color('l').'--------------------')
		if(@motd = get_value('motd')) {
			if(length(@motd) < 20, @motd = ' '.@motd)
			msg(@motd)
			msg(color('1').color('l').'--------------------')
		}
		#Tab list colors
		if(length(player()) > 14) {
			set_list_name(_colorname().substr(player(), 0, 14))
		} else {
			set_list_name(_colorname().player())
		}
		# homeless players are players left on deleted worlds
		@pdata = get_value('player.'.to_lower(player()))
		if(array_index_exists(@pdata, 'mail')) {
			foreach(@mail in @pdata['mail']) {
				msg(color('gray').@mail[0].' (From '.@mail[1].'): '.color('r').@mail[2])
			}
			array_remove(@pdata, 'mail')
			store_value('player.'.to_lower(player()), @pdata)
		}
		if(array_index_exists(@pdata, 'homeless')) {
			@loc = get_spawn('world')
			set_ploc(@loc)
			array_remove(@pdata, 'homeless')
			store_value('player.'.to_lower(player()), @pdata)
		} else if(!has_permission('group.everyone')) {
			@warp = get_value('warp.intro')
			@loc = @warp['loc']
			set_ploc(@warp['loc'])
			pfacing(@warp['yaw'], @warp['pitch'])
		}
		if(pworld() == 'custom') {
			_equip_park()
		}
		set_timeout(800, closure(){
			if(@loc[1] > ploc()[1]) {
				set_ploc(@loc)
			}
		})
	})
}

bind('player_death', null, null, @event) {
	if(!array_contains(array('custom', 'dev'), pworld())) {
		@log = @event['player'].' died @ '.round(@event['location'][0]).','.round(@event['location'][1]).','.round(@event['location'][2]).' on '.@event['location'][3].', dropping '.@event['xp'].'xp and '
		foreach(@drop in @event['drops']) {
			if(is_array(@drop)) {
				@log .= if(@drop['qty'] > 1, @drop['qty']).' '.data_name(@drop['type']).if(@drop['data'] > 0, ':'.@drop['data']).' '.if(array_size(@drop['enchants']) > 0, 'with '.@drop['enchants']. 'enchants').' - '
			}
		}
		console(@log, false)
		msg('You died @ ', round(@event['location'][0]), ',', round(@event['location'][1]), ',', round(@event['location'][2]))
	} else {
		modify_event('death_message', null)
	}
}

# Log commands
bind('player_command', null, null, @event) {
	if(is_alias(@event['command'])) {
		console(@event['player'].' ran: '.@event['command'], false)
	}
}

# Block wither
bind('block_place', null, array('type': 144), @event) {
	if(!array_contains(array('custom', 'dev','outworld_nether', 'outworld', 'outworld_the_end'), pworld())
	&& get_block_at(_relative(@event['location'], 'down')) == '88:0'
	&& pinv(player(), null) != null
	&& pinv(player(), null)['data'] == 1) {
		cancel()
		msg(color('yellow').'You can only spawn withers in the outworld.')
	}
}

# Infinite Cauldrons
bind('player_interact', null, array('block': 118, 'button': 'right'), @event) {
	if(@event['block'] == '118:3') {
		switch(@event['item']) {
		case '325:0':
			@bucket = pinv(player(), null)
			if(@bucket['qty'] == 1) {
				set_pinv(array(null: array('type': 326, 'qty': 1)))
			} else {
				@bucket['qty'] -= 1
				set_pinv(array(null: @bucket))
				pgive_item(326, 1)
			}
		case '374:0':
			set_timeout(50, closure(){
				set_block_at(@event['location'], '118:3')
			})
		}
	}
}

# Block lighters
bind('player_interact', null, array('item': 259, 'button': 'right'), @event) {
	if(has_permission('group.regulars'), die())
	if(!array_index_exists(@event, 'location'), die())
	@loc = @event['location']
	if(get_block_at(@loc) == '46:0') {
		die()
	} else if(get_block_at(@loc) == '49:0' && @event['facing'] == 'up') {
		set_timeout(50, closure(){
			if(reg_split('\\:', get_block_at(_relative(@loc, 'up')))[0] != '90') {
				set_block_at(_relative(@loc, 'up'), 0)
			}
		})
	} else {
		if(!sk_regions_at(_relative(@loc, 'up')) || !sk_can_build(_relative(@loc, 'up'))) {
			cancel()
			msg('Use of flint and steel is restricted here, except on nether portals and TNT.')
		}
	}
}

# Button commands
bind('player_interact', null, array('block': 77, 'button': 'right'), @event) {
	@sign = _relative(@event['location'], 'up')
	if(is_sign_at(@sign)) { 
		@signtext = get_sign_text(@sign)
		if(@type = reg_match('\u00A7[0-9a-f]{1}\\[(.+)\\]', @signtext[1])) {
			if(is_alias('/'.to_lower(@type[1]).if(@signtext[2] != '', ' '.to_lower(@signtext[2])).if(@signtext[3] != '', ' '.to_lower(@signtext[3])))) {
				call_alias('/'.to_lower(trim(@type[1])).' '.to_lower(trim(@signtext[2])).' '.to_lower(trim(@signtext[3])))
			} else {
				die('Unknown button command.')
			}
		} else if(length(@signtext[1]) > 1 && @signtext[1][0] == '/' && length(@signtext[0]) > 2 && substr(@signtext[0], 0, 2) == color(1)) {
			msg('Ran command:' @signtext[1] @signtext[2] @signtext[3])
			if(!call_alias(@signtext[1] @signtext[2] @signtext[3]), run(@signtext[1] @signtext[2] @signtext[3]))
		}
	}
}

# color signs for moderators
bind('sign_changed', null, null, @event) {
	if(has_permission('group.moderators'))  {
		modify_event('text', array(
			0: colorize(@event['text'][0]),
			1: colorize(@event['text'][1]),
			2: colorize(@event['text'][2]),
			3: colorize(@event['text'][3]),
		))
	}
}

# Sponge splitting
# bind('block_break', null, array('type': 19), @event) {
	# if(rand(16) < 1) {
		# drop_item(@event['location'], array('type': 19), 1)
	# }
# }

# prevent people from pushing minecart hoppers underneath chests
bind('vehicle_collide', null, array('type': 'MINECART_HOPPER', 'collisiontype': 'ENTITY', 'hittype': 'PLAYER'), @event) {
	cancel()
}

bind('vehicle_leave', array('priority': 'highest'), null, @event) {
	if(@event['player'] && entity_exists(@event['vehicle'])) {
		@vehicleloc = entity_loc(@event['vehicle'])
		set_timeout(50, closure(){
			if(!get_entity_vehicle(pinfo(@event['player'], 13))) {
				set_ploc(@event['player'], @vehicleloc)
			}
		})
	}
}

# prevent enderdragon egg teleportation
bind('player_interact', null, array('block': 122), @event) {
	if(pmode() != 'CREATIVE' && (pworld() == 'custom' || pworld() == 'dev')) {
		cancel()
	}
}

# DISPENER PARKING
bind('vehicle_collide', null, array('type': 'MINECART', 'collisiontype': 'BLOCK', 'hittype': 23), @event) {
	for(@i = 0, @i < get_inventory_size(@event['block']), @i++) {
		if(is_null(get_inventory_item(@event['block'], @i))) {
			set_inventory_item(@event['block'], @i, array('type': 328, 'qty': 1))
			entity_remove(@event['id'])
			break()
		}
	}
}

# prevent non-owners from riding a horse, unless shared
bind('player_interact_entity', null, array('clicked': 'HORSE'), @event) {
	if(pworld() == 'custom' || pworld() == 'dev', die())
	if(get_mob_owner(@event['id'])
	&& get_mob_owner(@event['id']) != player()) {
		@yVelocity = round(entity_spec(@event['id'])['jump'], 2)
		@jump = 0
		while(@yVelocity > 0) {
			@jump += @yVelocity
			@yVelocity -= 0.08
			@yVelocity *= 0.98
		}
		@jump = round(@jump, 1)
		@health = round(get_max_health(@event['id']) / 2, 1)
		
		msg('This horse is owned by '.get_mob_owner(@event['id']).' '
		.color('red').@health.' \u2764'.color('r').' '.color('yellow').@jump.' \u279A')
		
		@item = pinv(player(), null)
		if(!has_permission('group.moderators')
		&& (!@item
		|| (@item['type'] != 322
		&& @item['type'] != 396))) {
			@pdata = get_value('player.'.to_lower(get_mob_owner(@event['id'])))
			if(!@pdata
			|| !array_index_exists(@pdata, 'shared')
			|| !array_index_exists(@pdata['shared'], player())
			|| !array_contains(@pdata['shared'][player()], 'horses')) {
				cancel()
			}
		}
	}
}

# don't allow most horse damage unless being rode
bind('entity_damage', null, array('type': 'HORSE'), @event) {
	if(get_mob_age(@event['id']) < -24000) {
		cancel()
		die()
	}
	
	@world = entity_loc(@event['id'])['world']
	if(@world == 'custom' || @world == 'dev') {
		die()
	}
	
	@owner = get_mob_owner(@event['id'])
	if(is_null(@owner)) {
		 die()
	}
	
	switch(@event['cause']) {
	case 'VOID':
	case 'SUFFOCATION':
	case 'DROWNING':
		die()
		
	case 'ENTITY_ATTACK':
		@isplayer = ponline(@event['damager'])
		
		if((@isplayer && @owner != @event['damager'])
		|| (!@isplayer && !get_entity_rider(@event['id']))) {
			cancel()
		}
		
	case 'PROJECTILE':
		@isplayer = ponline(@event['shooter'])
		
		if((@isplayer && @owner != @event['shooter'])
		|| (!@isplayer && !get_entity_rider(@event['id']))) {
			cancel()
		}
		
	default: 
		if(!get_entity_rider(@event['id'])) {
			cancel()
		}
	}
}

# Let one player in a world make the sun rise
bind('player_enter_bed', null, null, @event) {
    if(get_world_time() > 13700 && get_world_time() < 22300) {
		set_world_time(22300)
		msg(color('aqua').'You made the sun rise.')
    } else if(get_world_time() < 13700 && get_world_time() > 11300) {
		@time = get_world_time() - 11300
		@time = 700 - @time
		if(@time < 0) {
			@time = @time + 24000
		}
		set_world_time(@time)
		msg(color('aqua').'You made the sun rise.')
    }
}

# bind('block_dispense', null, array('type': 'DISPENSER'), @e,
	# if(@e['location']['world'] == 'dev') {
		# try(@inv = get_inventory(@e['location']), die())
		# for(@i = 0, @i < array_size(@inv), @i++,
			# if(@inv[@i]) {
				# @inv[@i]['qty'] = 64
			# }
		# )
		# set_timeout(50, closure(
		# set_inventory(@e['location'], @inv)
		# ))
	# }
# )

# Limit the number of mobs that can be built up from a mob spawner
bind('creature_spawn', null, array('reason': 'SPAWNER'), @event) {
	@entities = 0
	# check a 3x3 chunk area (48x256x48 area)
	for(@x = -16, @x <= 16, @x += 16) {
		for(@z = -16, @z <= 16, @z += 16) {
			@entities += array_size(all_entities(@event['location']['world'], @event['location']['x'] + @x, @event['location']['z'] + @z))
		}
	}
	if(@entities > 100) {
		cancel()
	}
}

# Anti-xray helper
bind('block_break', null, array('type': 56), @event) {
	if(pworld() == 'dev' || pworld() == 'custom', die())
	set_timeout(50, closure(){
		for(@x = @event['location']['x'] - 1, @x <= @event['location']['x'] + 1, @x++) {
			for(@y = @event['location']['y'] - 1, @y <= @event['location']['y'] + 1, @y++) {
				for(@z = @event['location']['z'] - 1, @z <= @event['location']['z'] + 1, @z++) {
					if(get_block_at(@x, @y, @z) == '56:0') {
						die()
					}
				}
			}
		}
	
		broadcast(color('c').'[!] '.color('f').player().' found '.color('b').'diamonds '.color(7).if(get_light_at(@event['location']) < 7, '(light level: '.get_light_at(@event['location']).')'),
		'group.moderators')
	})
}

# leash villagers
bind('player_interact_entity', null, array('clicked': 'VILLAGER'), @event) {
	@item = pinv(player(), null)
	if(@item && @item['type'] == 420
	&& get_player_from_entity_id(get_leashholder(@event['id'])) != player()) {
		cancel()
		set_leashholder(@event['id'], pinfo(player(), 13))
		@item['qty'] = @item['qty'] - 1
		set_pinv(array(null: @item))
	}
}

bind('entity_enter_portal', null, null, @event) {
	if(@event['type'] != 'PLAYER'
	&& (@event['location']['world'] == 'custom'	|| @event['location']['world'] == 'dev')) {
		entity_remove(@event['id'])
	}
}
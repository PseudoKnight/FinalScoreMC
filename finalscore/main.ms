set_interval(8 * 60 * 1000, closure(
	if(player() == '~console') {
		run('/save-all')
	} else {
		runas('~console', '/save-all')
	}
))

bind('player_login', null, null, @e,
	if(@e['result'] != 'ALLOWED', die())
	@update = false
	@pdata = get_value('player.'.to_lower(@e['player']))
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
			console('Ban on '.@e['player'].' expired.')
			@update = true
		}
	}
	if(get_server_info(10)) {
		if(!array_index_exists(@pdata, 'ips'), @pdata['ips'] = array())
		if(!array_contains(@pdata['ips'], @e['ip'])) {
			array_push(@pdata['ips'], @e['ip'])
			if(array_size(@pdata['ips']) > 3) {
				array_remove(@pdata['ips'], 0)
			}
			@update = true
		}

	} else {
		if(!array_contains(@pdata['ips'], @e['ip'])) {
			console(@e['player'].': '.@e['ip'].', '.@pdata['ips'])
			modify_event('result', 'KICK_OTHER')
			modify_event('kickmsg', 'Minecraft auth servers are down and your IP doesn\'t match our records.')
		}
	}
	if(@update) {
		store_value('player.'.to_lower(@e['player']), @pdata)
	}
)

# Player join messages and tab list colors
bind('player_join', null, null, @event,
	set_timeout(250, closure(@loc = ploc(), @player = player(),
		if(!ponline(@player), die())
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
		set_timeout(800, closure(
			if(@loc[1] > ploc()[1]) {
				set_ploc(@loc)
			}
		))
	))
)

bind('player_death', null, null, @event,
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
)

# Log commands
bind('player_command', null, null, @event,
	if(is_alias(@event['command'])) {
		console(@event['player'].' ran: '.@event['command'], false)
	}
)

# Block wither
bind('block_place', null, array('type': 144), @e,
	if(!array_contains(array('custom', 'dev','outworld_nether', 'outworld', 'outworld_the_end'), pworld())
	&& get_block_at(_relative(@e['location'], 'down')) == '88:0'
	&& pinv(player(), null) != null
	&& pinv(player(), null)['data'] == 1) {
		cancel()
		msg(color('yellow').'You can only spawn withers in the outworld.')
	}
)

# Infinite Cauldrons
bind('player_interact', null, array('block': 118, 'button': 'right'), @event,
	if(equals(@event['block'], '118:3')) {
		switch(@event['item'],
		'325:0',
			@bucket = pinv(player(), null)
			if(@bucket['qty'] == 1) {
				set_pinv(array(null: array('type': 326, 'qty': 1)))
			} else {
				array_set(@bucket, 'qty', @bucket['qty'] - 1)
				set_pinv(array(null: @bucket))
				pgive_item(326, 1)
			},
		'374:0',
			set_timeout(100, closure(assign(@location, @event['location']), set_block_at(@location, '118:3')))
		)
	}
)

# Block lighters
bind('player_interact', null, array('item': 259, 'button': 'right'), @event,
	if(has_permission('group.regulars'), die())
	if(!array_index_exists(@event, 'location'), die())
	@loc = @event['location']
	if(get_block_at(@loc) == '46:0') {
		die()
	} else if(get_block_at(@loc) == '49:0' && @event['facing'] == 'up') {
		set_timeout(50, closure(
			if(reg_split('\\:', get_block_at(_relative(@loc, 'up')))[0] != '90') {
				set_block_at(_relative(@loc, 'up'), 0)
			}
		))
	} else {
		if(!sk_regions_at(_relative(@loc, 'up')) || !sk_can_build(_relative(@loc, 'up'))) {
			cancel()
			msg('Use of flint and steel is restricted here, except on nether portals and TNT.')
		}
	}
)

# Button commands
bind('player_interact', null, array('block': 77, 'button': 'right'), @event,
	@sign = _relative(@event['location'], 'up')
	if(is_sign_at(@sign)) { 
		@signtext = get_sign_text(@sign)
		if(@type = reg_match('\u00A7[0-9a-f]{1}\\[(.+)\\]', @signtext[1])) {
			switch(@type[1]
			, 'CONNECT4',
				switch(@signtext[2],
				'Reset',
					proc(_set_sand, @x, @y, @z,
						if(get_block_at(@x, @y, @z, pworld()) == '0:0', set_block_at(@x, @y, @z, 12, pworld()))
					)
					proc(_set_gravel, @x, @y, @z,
						if(get_block_at(@x, @y, @z, pworld()) == '0:0', set_block_at(@x, @y, @z, 13, pworld()))
					)
					_iterate_cuboid(array(-499, 73, -348), array(-499, 78, -342), '_set_sand')
					_iterate_cuboid(array(-499, 81, -348), array(-499, 86, -342), '_set_gravel')
				)
			, 'SNOWSPLEEF',
				switch(@signtext[2],
				'Reset Floor',
					proc(_set_snowblock, @x, @y, @z,
						if(get_block_at(@x, @y, @z, pworld()) == '0:0', set_block_at(@x, @y, @z, 80, pworld()))
					)
					_iterate_cuboid(array(-667, 63, -260), array(-644, 63, -283), '_set_snowblock')
					msg('Reset.')
				)
			, # else
				if(is_alias('/'.to_lower(@type[1]).if(@signtext[2] != '', ' '.to_lower(@signtext[2])).if(@signtext[3] != '', ' '.to_lower(@signtext[3])))) {
					call_alias('/'.to_lower(trim(@type[1])).' '.to_lower(trim(@signtext[2])).' '.to_lower(trim(@signtext[3])))
				} else {
					die('Unknown button command.')
				}
			)
		} else if(length(@signtext[1]) > 1 && @signtext[1][0] == '/' && length(@signtext[0]) > 2 && substr(@signtext[0], 0, 2) == color(1)) {
			msg('Ran command:' @signtext[1] @signtext[2] @signtext[3])
			if(!call_alias(@signtext[1] @signtext[2] @signtext[3]), run(@signtext[1] @signtext[2] @signtext[3]))
		}
	}
)

# color signs for moderators
bind('sign_changed', null, null, @e,
	if(has_permission('group.moderators'))  {
		modify_event('text', array(
			0: colorize(@e['text'][0]),
			1: colorize(@e['text'][1]),
			2: colorize(@e['text'][2]),
			3: colorize(@e['text'][3])
		))
	}
)

# Sponge splitting
bind('block_break', null, array('type': 19), @event,
	if(rand(16) < 1, drop_item(@event['location'], array('type': 19), 1))
)

# prevent people from pushing minecart hoppers underneath chests
bind('vehicle_collide', null, array('type': 'MINECART_HOPPER', 'collisiontype': 'ENTITY', 'hittype': 'PLAYER'), @e,
	cancel()
)

bind('vehicle_leave', array('priority': 'highest'), null, @e,
	if(@e['player'] && entity_exists(@e['vehicle'])) {
		@vehicleloc = entity_loc(@e['vehicle'])
		set_timeout(50, closure(
			if(!get_entity_vehicle(pinfo(@e['player'], 13))) {
				set_ploc(@e['player'], @vehicleloc)
			}
		))
	}
)

# prevent enderdragon egg teleportation
bind('player_interact', null, array('block': 122), @e,
	if(pmode() != 'CREATIVE' && (pworld() == 'custom' || pworld() == 'dev'), cancel())
)

bind('entity_explode', null, null, @e,
	if(@e['location'][3] == 'dev'
	|| (@e['location'][3] == 'custom' 
	&& ((@e['type'] != 'PRIMED_TNT'
	&& @e['type'] != 'CREEPER')
	|| (!array_contains(sk_regions_at(entity_loc(@e['id'])), 'skypirates')
	&& !array_contains(sk_regions_at(entity_loc(@e['id'])), 'antfarm')
	&& !array_contains(sk_regions_at(entity_loc(@e['id'])), 'bomberman'))))) {
		cancel()
	}
)

# DISPENER PARKING
bind('vehicle_collide', null, array('type': 'MINECART', 'collisiontype': 'BLOCK', 'hittype': 23), @e,
	for(@i = 0, @i < get_inventory_size(@e['block']), @i++) {
		if(is_null(get_inventory_item(@e['block'], @i))) {
			set_inventory_item(@e['block'], @i, array('type': 328, 'qty': 1))
			entity_remove(@e['id'])
			break()
		}
	}
)

# prevent non-owners from riding a horse, unless shared
bind('player_interact_entity', null, array('clicked': 'HORSE'), @e,
	if(pworld() == 'custom' || pworld() == 'dev', die())
	if(get_mob_owner(@e['id'])
	&& get_mob_owner(@e['id']) != player()) {
		@yVelocity = round(entity_spec(@e['id'])['jump'], 2)
		@jump = 0
		while(@yVelocity > 0) {
			@jump += @yVelocity
			@yVelocity -= 0.08
			@yVelocity *= 0.98
		}
		@jump = round(@jump, 1)
		@health = round(get_max_health(@e['id']) / 2, 1)
		msg('This horse is owned by '.get_mob_owner(@e['id']).' '
		.color('red').@health.' \u2764'.color('r').' '.color('yellow').@jump.' \u279A')
		if(!has_permission('group.moderators')
		&& (!pinv(player(), null)
		|| (pinv(player(), null)['type'] != 322
		&& pinv(player(), null)['type'] != 396))) {
			@pdata = get_value('player.'.to_lower(get_mob_owner(@e['id'])))
			if(!@pdata
			|| !array_index_exists(@pdata, 'shared')
			|| !array_index_exists(@pdata['shared'], player())
			|| !array_contains(@pdata['shared'][player()], 'horses')) {
				cancel()
			}
		}
	}
)

# don't allow most horse damage unless being rode
bind('entity_damage', null, array('type': 'HORSE'), @e,
	if(get_mob_age(@e['id']) < -24000) {
		cancel()
		die()
	}
	
	if(!get_mob_owner(@e['id']), die())
	switch(@e['cause']
	, array('VOID', 'SUFFOCATION', 'DROWNING'),
		die()
		
	, 'ENTITY_ATTACK',
		if((ponline(@e['damager'])
		&& get_mob_owner(@e['id']) != @e['damager'])
		|| (!ponline(@e['damager'])
		&& !get_entity_rider(@e['id']))) {
			cancel()
		}
		
	, 'PROJECTILE',
		if((ponline(@e['shooter'])
		&& get_mob_owner(@e['id']) != @e['shooter'])
		|| (!ponline(@e['shooter'])
		&& !get_entity_rider(@e['id']))) {
			cancel()
		}
		
	, 
		if(!get_entity_rider(@e['id'])) {
			cancel()
		}
	)
)

# Let one player in a world make the sun rise
bind('player_enter_bed', null, null, @e,
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
    
)

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
bind('creature_spawn', null, array('reason': 'SPAWNER'), @e,
	if(array_size(entities_in_radius(@e['location'], 32, @e['type'])) > 50) {
		cancel()
	}
)

# Anti-xray helper
bind('block_break', null, array('type': 56), @e,
	if(pworld() == 'dev' || pworld() == 'custom', die())
	set_timeout(50, closure(
		for(@x = @e['location']['x'] - 1, @x <= @e['location']['x'] + 1, @x++,
			for(@y = @e['location']['y'] - 1, @y <= @e['location']['y'] + 1, @y++,
				for(@z = @e['location']['z'] - 1, @z <= @e['location']['z'] + 1, @z++,
					if(get_block_at(@x, @y, @z) == '56:0') {
						die()
					}
				)
			)
		)
	
		broadcast(color('c').'[!] '.color('f').player().' found '.color('b').'diamonds '.color(7).if(get_light_at(@e['location']) < 7, '(light level: '.get_light_at(@e['location']).')'),
		'group.moderators')
	))
)

# leash villagers
bind('player_interact_entity', null, array('clicked': 'VILLAGER'), @e,
	@slot = pinv(player(), null)
	if(@slot && @slot['type'] == 420
	&& get_player_from_entity_id(get_leashholder(@e['id'])) != player()) {
		cancel()
		set_leashholder(@e['id'], pinfo(player(), 13))
		@slot['qty'] = @slot['qty'] - 1
		set_pinv(array(null: @slot))
	}
)

bind('entity_enter_portal', null, null, @e,
	if(@e['type'] != 'PLAYER'
	&& (@e['location']['world'] == 'custom'	|| @e['location']['world'] == 'dev')) {
		entity_remove(@e['id'])
	}
)
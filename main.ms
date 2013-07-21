#prime variables
@requests = get_value('session.requests')
if(!@requests, @requests = array(), clear_value('session.requests'))
export('requests', @requests)
@conv = get_value('session.conv')
if(!@conv, @conv = array(), clear_value('session.conv'))
export('conv', @conv)
@stopwatch = get_value('session.stopwatch')
if(!@stopwatch, @stopwatch = array(), clear_value('session.stopwatch'))
export('stopwatch', @stopwatch)
@ignorelist = array()
export('ignorelist', @ignorelist)

set_world_time('dev', 700)
set_interval(8 * 60 * 1000, closure(
	runas('~console', '/save-all')
	set_world_time('dev', 700)
))

bind('player_login', null, null, @e,
	if(@e['result'] != 'ALLOWED', die())
	@update = false
	@pdata = get_value('player.'.to_lower(@e['player']))
	if(!@pdata) {
		@pdata = array('ips': array())
	}
	if(array_index_exists(@pdata, 'ban'),
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
	)
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
	if(@update, store_value('player.'.to_lower(@e['player']), @pdata))
)

# Player join messages and tab list colors
bind('player_join', null, null, @event,
	set_timeout(250, closure(assign(@loc, ploc()),
		#anti-cheat codes
		msg('\u00A7f \u00A7f \u00A71 \u00A70 \u00A72 \u00A74 \u00A7f \u00A7f \u00A72 \u00A70 \u00A74 \u00A78 \u00A73 \u00A79 \u00A72 \u00A70 \u00A70 \u00A70 \u00A70\u00A70\u00A71\u00A72\u00A73\u00A74\u00A75\u00A76\u00A77\u00A78\u00A7f\u00A7e')
		#Welcome messages
		msg(color(1).color('l').'--------------------')
		msg(color('gold'), color('l'), '\u2302', color('red'), color('l'), '\u2302', color('aqua'), color('l'), '\u2302', color('dark_red'), color('l'), '\u2302', color('gold'), color('l'), ' FINALSCORE ', color('yellow'), color('l'), '\u00AB', color('r'), ' \u25AA \u25AA \u25AA')
		msg(color(1).color('l').'--------------------')
		msg(get_value('motd'))
		#Tab list colors
		if(length(player()) > 14) {
			set_list_name(_colorname().substr(player(), 0, 14))
		} else {
			set_list_name(_colorname().player())
		}
		# homeless players are players left on deleted worlds
		@pdata = get_value('player.'.to_lower(player()))
		if(array_index_exists(@pdata, 'homeless')) {
			@loc = get_spawn('world')
			set_ploc(@loc)
			array_remove(@pdata, 'homeless')
			store_value('player.'.to_lower(player()), @pdata)
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
		foreach(@event['drops'], @drop,
			if(is_array(@drop)) {
				@log .= if(@drop['qty'] > 1, @drop['qty']).' '.data_name(@drop['type']).if(@drop['data'] > 0, ':'.@drop['data']).' '.if(array_size(@drop['enchants']) > 0, 'with '.@drop['enchants']. 'enchants').' - '
			}
		)
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
	if(equals(@event['block'], '118:3'),
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
	)
)

# Block lighters
bind('player_interact', null, array('item': 259, 'button': 'right'), @event,
	if(has_permission('group.regulars'), die())
	try(@loc = @event['location'], die())
	if(get_block_at(@loc) == '46:0') {
		die()
	} else if(get_block_at(@loc) == '49:0' && @event['facing'] == 'up') {
		set_timeout(50, closure(
			if(reg_split('\\:', get_block_at(@loc[0], @event['location'][1] + 1, @loc[2]))[0] != '90') {
				set_block_at(@loc[0], @loc[1] + 1, @loc[2], 0)
			}
		))
	} else {
		cancel()
		msg('Use of flint and steel is restricted here, except on nether portals and TNT.')
	}
)

bind('player_interact', null, array('block': 143, 'button': 'right'), @e,
	if(@e['location'][0] == '118' && @e['location'][1] == '63' && @e['location'][2] == '345' && @e['location'][3] == 'world3') {
		set_timeout(1500, closure(
			run('/dial supergate outworld galaxy')
		))
	}
)

# Button commands
bind('player_interact', null, array('block': 77, 'button': 'right'), @event,
	@sign = _relative(@event['location'], 'up')
	if(is_sign_at(@sign)) { 
		@signtext = get_sign_text(@sign)
		if(@type = reg_match('\u00A7[0-9a-f]{1}\\[(.+)\\]', @signtext[1])) {
			switch(@type[1]
			, 'STOPWATCH',
				switch(@signtext[2],
				'Start',
					@stopwatch = import('stopwatch')
					if(!@stopwatch, @stopwatch = associative_array())
					@stopwatch[player()] = time()
					export('stopwatch', @stopwatch)
					msg(color('a').'[STOPWATCH] '.color('white').'GO!'),
				'Stop',
					@stopwatch = import('stopwatch')
					if(!array_index_exists(@stopwatch, player()), die('Did you start the stopwatch?'))
					@time = round(divide(subtract(time(), @stopwatch[player()]), 1000), 1)
					msg(color('a').'[STOPWATCH] '.color('white').'Time: '.@time.' seconds.')
					console(player().' got a time of '.@time.' at '.sk_current_regions())
					array_remove(@stopwatch, player())
					export('stopwatch', @stopwatch)
				),
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
	if(rand(16) < 1, drop_item(@event['location'], array('type': 19)))
)

#disable hopper minecarts
bind('player_interact', null, array('item': 408), @event,
	if(pworld() != 'custom' && pworld() != 'dev') {
		msg(color('red').'Hopper minecarts are currently disabled.')
		cancel()
	}
)

bind('inventory_click', null, array('slottype': 'RESULT', 'slotitem': 408), @event,
	msg(color('red').'Hopper minecarts are currently disabled.')
	cancel()
)

bind('player_interact', null, array('block': 122), @e,
	if(pmode() != 'CREATIVE' && (pworld() == 'custom' || pworld() == 'dev'), cancel())
)

bind('entity_explode', null, null, @e,
	if(@e['location'][3] == 'custom' && @e['type'] != 'PRIMED_TNT', cancel())
)

# DISPENER PARKING
bind('vehicle_collide', null, array('type': 'MINECART', 'collisiontype': 'BLOCK', 'hittype': 23), @e,
	for(@i = 0, @i < get_inventory_size(@e['block']), @i++,
		if(is_null(get_inventory_item(@e['block'], @i))) {
			set_inventory_item(@e['block'], @i, array('type': 328, 'qty': 1))
			entity_remove(@e['id'])
			break()
		}
	)
)

bind('player_interact_entity', null, array('clicked': 'HORSE'), @e,
	if(get_mob_owner(@e['id'])
	&& get_mob_owner(@e['id']) != player()
	&& (!pinv(player(), null)
	|| (pinv(player(), null)['type'] != 322
	&& pinv(player(), null)['type'] != 396))) {
		cancel()
		msg('This horse is owned by '.get_mob_owner(@e['id']).'.')
	}
)

bind('entity_damage', null, array('type': 'HORSE'), @e,
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


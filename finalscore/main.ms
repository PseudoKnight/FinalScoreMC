set_cron('*/4 * * * *', closure(){
	foreach(@world in get_worlds()) {
		queue_push(closure(){
			save_world(@world);
		});
	}
	queue_push(closure(){
		save_players();
		@currently = import('currently');
		@allocMem = get_server_info(15);
		@freeMem = get_server_info(16);
		console('---[ SAVED ]---[ TPS: '.tps()[0].' ]'
			.'---[ MEM: '.floor((@allocMem - @freeMem) / 1000000).' / '.floor(@allocMem / 1000000).' / 2863 MB ]'
			.'---[ PLAYERS: '.array_size(all_players()).' ]'
			.'---'.if(!is_null(@currently), '[ CURRENTLY: '.@currently.' ]---'), false);
	});
})

bind(server_ping, null, null, @event) {
	@currently = import('currently')
	modify_event('motd', colorize('&6&l\u1260&d&l\u1260&b&l\u1260&4&l\u1260 &6&lFINALSCORE&e&lMC \u00AB &f\u25AA \u25AA \u25AA'
		.if(!is_null(@currently), '\n&aNow Playing&f: '.@currently)));
}

bind(player_login, null, null, @event) {
	if(@event['result'] !== 'ALLOWED') {
		die();
	}
	@update = false;
	@pdata = null;
	@uuidDashed = get_value('players', to_lower(@event['player']));
	if(is_null(@uuidDashed)) { # new player or changed name
		@uuid = replace(@event['uuid'], '-', '');
		@pdata = get_value('uuids', @uuid);
		store_value('players', to_lower(@event['player']), @event['uuid']);
		@update = true;
		if(@pdata) { # someone changed their name or name doesn't exist
			if(array_index_exists(@pdata, 'name')) {
				export('pdata.'.to_lower(@pdata['name']), null);
				if(!array_index_exists(@pdata, 'names')) {
					@pdata['names'] = array();
				}
				array_remove_values(@pdata['names'], @pdata['name']);
				@pdata['names'][] = @pdata['name'];
			} else {
				msg('WARNING: ' . @event['player'] . ' did not have their name stored.');
			}
			@pdata['name'] = @event['player'];
		} else { # new player!
			@pdata = array(
				'joined': simple_date('YYYY-MM-dd'),
				'name': @event['player'],
			);
		}

	} else { # existing player
		if(@uuidDashed != @event['uuid']) {
			modify_event('result', 'KICK_OTHER');
			modify_event('kickmsg', 'You seem to be using a reserved player name.'
				.' Please contact an administrator if this is in error.');
			die();
		}

		@uuid = replace(@uuidDashed, '-', '');
		@pdata = get_value('uuids', @uuid);

		if(is_null(@pdata)) {
			modify_event('result', 'KICK_OTHER');
			modify_event('kickmsg', 'ERROR: User data is missing for known player.');
			die();
		}

		if(!array_index_exists(@pdata, 'name')) {
			@pdata['name'] = @event['player'];
			@update = true;

		} else if(@pdata['name'] != @event['player']) {
			# player changed their name back or data was inaccurate
			if(!array_index_exists(@pdata, 'names')) {
				@pdata['names'] = array(@pdata['name']);
			}
			array_remove_values(@pdata['names'], @event['player']);
			@pdata['name'] = @event['player'];
			@update = true;
		}
	}

	# Check if player is banned.
	if(array_index_exists(@pdata, 'ban')) {
		if(!array_index_exists(@pdata['ban'], 'time') || @pdata['ban']['time'] > time()) {
			modify_event('result', 'KICK_BANNED');
			if(array_index_exists(@pdata['ban'], 'message')) {
				modify_event('kickmsg', @pdata['ban']['message']);
			} else {
				modify_event('kickmsg', 'Banned. Appeal at FinalScoreMC.com');
			}
		} else {
			array_remove(@pdata, 'ban');
			console('Ban on '.@event['player'].' expired.');
			@update = true;
		}
	}

	if(!array_index_exists(@pdata, 'ips')) {
		@pdata['ips'] = array();
	}
	if(!array_contains(@pdata['ips'], @event['ip'])) {
		@pdata['ips'][] = @event['ip'];
		if(array_size(@pdata['ips']) > 2) {
			array_remove(@pdata['ips'], 0);
		}
		@update = true;
	}

	export('pdata.'.to_lower(@event['player']), @pdata);

	if(@update) {
		store_value('uuids', @uuid, @pdata);
	}
}

# Player join messages and tab list colors
bind(player_join, null, null, @event) {
	modify_event('join_message', null);

	# BLOCK CODES
	# Disables cheat features in mods that play nice.
	/*
	msg(colorize('&f &f &2 &0 &4 &8 ')); # Zombe zcheat
	msg(colorize('&f &f &4 &0 &9 &6 ')); # Zombe noclip
	msg(colorize('&f &f &1 &0 &2 &4 ')); # Zombe fly
	msg(colorize('&3 &9 &2 &0 &0 &2 ')); # CJB xray
	msg(colorize('&3 &9 &2 &0 &0 &1 ')); # CJB fly
	msg(colorize('&3 &9 &2 &0 &0 &3 ')); # CJB radar
	msg(colorize('&0&0&1&e&f')); # Rei's Minimap cave
	msg(colorize('&0&0&2&3&4&5&6&7&e&f')); # Rei's Minimap radar
	msg(colorize('&0&1&0&1&2&f&f')); # Smart-moving climb
	msg(colorize('&0&1&3&4&f&f')); # Smart-moving swim
	msg(colorize('&0&1&5&f&f')); # Smart-moving crawl
	msg(colorize('&0&1&6&f&f')); # Smart-moving slide
	msg(colorize('&0&1&7&f&f')); # Smart-moving fly
	msg(colorize('&0&1&8&9&a&b&f&f')); # Smart-moving jump
	msg(colorize('&3 &6 &3 &6 &3 &6 &e ')); # Voxelmap radar
	msg(colorize('&3 &6 &3 &6 &3 &6 &d ')); # Voxelmap cave
	*/

	set_timeout(250, closure(@loc = ploc(), @player = player()){
		if(!ponline(@player)) {
			console('ERROR: Player was not online 250ms after joining.');
			die();
		}

		@pdata = _pdata(player());
		if(!(has_permission('group.admin') && get_value('silentjoin'))) {
			@msg = _colorname().'&o'.player().'&e&o ';
			if(array_index_exists(@pdata, 'enter')) {
				@msg .= @pdata['enter'];
			} else {
				@msg .= 'joined the game';
			}
			broadcast(colorize('&8'.simple_date('h:mm').' &2\u00bb &o'.@msg));
		}

		# Makes a call to the ban manager to store the player's UUID
		# @endpoint - String - The action to take in the ban manager.
		# @player - String - The player name making the call to the ban manager, or the UUID of the player.
		# This player must be an admin or moderator.
		# @params - Associative Array - The parameters to post to the ban manager.
		# @error - Closure (Optional) - Closure to execute when the request returns an error.
		# The closure is passed the error message. Defaults to printing the error message to the user.
		proc _bm_request(@endpoint, @player, @params,
			@error = closure(@error_msg, console('Error saving UUID to ban manager: '.@error_msg, false))) {

				# Add the authentication parameters
				@params['accessor_token'] = 'final-score-minecraft-server';
				@params['timestamp'] = simple_date('yyyy-MM-dd HH:mm:ss Z');
				@params['nonce'] = rand();
				@params['uuid'] = @player;

				# Generate the HMAC
				@hmac_key = comp_read('key.txt');
				@msg = '';
				foreach(@key in array_keys(@params)) {
					@msg .= @key . @params[@key];
				}
				@params['hmac'] = hmac_sha1(@hmac_key, @msg);

				http_request('http://finalscoremc.com/fsmcbm/ban-manager.php?action='.@endpoint, array(
					'method': 'POST',
					'params': @params,
					'success': closure(@response){
						@result = json_decode(@response['body']);
						if(@result && array_index_exists(@result, 'error') && @result['error'] !== 'Nothing found.') {
							execute(@result['error'], @error);
						}
					}
				))
		}

		_bm_request('set_user_uuid', 'a1634f37480a4bb9a0b2200266597ac0',
			array('username': player(), 'user_uuid': puuid())
		);

		#Welcome messages
		@line = color('1').color('l').'----------------------';
		msg(@line);
		msg(colorize(' &6&l\u1260&d&l\u1260&b&l\u1260&4&l\u1260 &6&lFINALSCORE&e&lMC \u00AB &r\u25AA \u25AA \u25AA'));
		msg(@line);

		@updatePdata = false;
		if(array_index_exists(@pdata, 'mail')) {
			foreach(@mail in @pdata['mail']) {
				msg(color('gray').@mail[0].' (From '.@mail[1].'): '.color('r').@mail[2]);
			}
			array_remove(@pdata, 'mail');
			@updatePdata = true;
		} else if(@motd = get_value('motd')) {
			msg(@motd);
			msg(@line);
		} //else {
			//run('/mumble');
		//}

		_refresh_tablist(all_players());

		# SET NEW LOCATION
		if(array_index_exists(@pdata, 'homeless')) {
		# homeless players are players left on deleted worlds
			@loc = get_spawn('omega');
			set_ploc(@loc);
			array_remove(@pdata, 'homeless');
			@updatePdata = true;
		} else if(!has_permission('group.member')) {
			@warp = get_value('warp.intro');
			set_ploc(@warp);
		}

		if(@updatePdata) {
			_store_pdata(player(), @pdata);
		}

		set_timeout(800, closure(){
			if(pworld() === 'custom') {
				_equip_park();
			}
		});
	});
}

bind(player_command, null, null, @event) {
	if(length(@event['prefix']) > 1 && @event['prefix'][1] !== '/') {
		console(@event['player'].' ran: '.@event['command'], false);
	}
}

bind(player_quit, null, null, @event) {
	modify_event('message', null);
	@pdata = _pdata(@event['player']);
	@msg = _colorname().'&o'.player().'&e&o ';
	if(array_index_exists(@pdata, 'exit')) {
		@msg .= @pdata['exit'];
	} else {
		@msg .= 'left the game';
	}
	broadcast(colorize('&8'.simple_date('h:mm').' &4\u00ab &o'.@msg));
	try {
		@pdata['world'] = pworld();
		_store_pdata(@event['player'], @pdata);
	} catch(PlayerOfflineException @e) {
		msg('Cannot fetch player world while quitting.');
	}
	export('pdata.'.to_lower(@event['player']), null);
	save_players();
	console('---[ SAVED ]---[ PLAYERS ]---', false);
}

bind(player_death, null, null, @event) {
	if(_is_survival_world(@event['location']['world'])) {
		@loc = floor(@event['location'][0]).','.floor(@event['location'][1]).','.floor(@event['location'][2]);
		@log = @event['player'].' died @ '.@loc.' on '.@event['location'][3].': ';
		_minify_inv(@event['drops']);
		@log .= json_encode(@event['drops']);
		console(@log, false);
		msg('You died @ '.@loc);
		@time = array(60);
		set_interval(1000, closure(){
			if(!ponline(player()) || pinfo(player(), 5) > 0) {
				clear_task();
			} else {
				@time[0] -= 1;
				if(@time[0] < 30) {
					if(@time[0] == 0) {
						clear_task();
						pkick(player(), 'Kicked after sitting in death screen for 60 seconds.');
					} else {
						action_msg(@time[0]);
					}
				}
			}
		});
	} else {
		modify_event('death_message', null);
	}
}

/*
	Blocks spawning of the wither
*/
bind(block_place, null, array('type': 144), @event) {
	if(pworld() != 'outworld' && pworld() != 'outworld_nether') {
		foreach(@dir in array('north', 'south', 'east', 'west', 'up', 'down')) {
			if(get_block_at(_relative(@event['location'], @dir)) == '88:0') {
				@item = pinv(player(), null);
				if(@item && @item['data'] == 1) {
					cancel();
					msg(color('yellow').'You can only spawn withers in the outworld.');
					break();
				}
			}
		}
	}
}

/*
	Infinite Cauldrons
	Refills buckets and water bottles without reducing water levels
*/
bind(player_interact, null, array('block': 118, 'button': 'right'), @event) {
	if(@event['block'] === '118:3') {
		@result = null;
		switch(pinfo(player(), 6)) {
			case '325:0':
				@result = 326;
			case '374:0':
				@result = 373;
			default:
				die();
		}
		cancel();
		@item = pinv(player(), null);
		if(@item['qty'] == 1) {
			set_pinv(array(null: array('type': @result, 'qty': 1)));
		} else {
			@item['qty'] -= 1;
			set_pinv(array(null: @item));
			pgive_item(@result, 1);
		}
	}
}

# Block lighters
bind(player_interact, null, array('item': 259, 'button': 'right'), @event) {
	if(has_permission('group.regular')
	|| !array_index_exists(@event, 'location')
	|| pworld() === 'outworld'
	|| pworld() === 'outworld_nether') {
		die();
	}
	@loc = @event['location'];
	if(get_block_at(@loc) === '46:0') {
		die();
	} else if(get_block_at(@loc) === '49:0' && @event['facing'] === 'up') {
		queue_push(closure(){
			if(reg_split('\\:', get_block_at(_relative(@loc, 'up')))[0] !== '90') {
				set_block_at(_relative(@loc, 'up'), 0);
			}
		});
	} else {
		if(!sk_regions_at(_relative(@loc, 'up')) || !sk_can_build(_relative(@loc, 'up'))) {
			cancel();
			msg('Use of flint and steel is restricted here, except on nether portals and TNT.');
		}
	}
}

# Button commands
bind(player_interact, null, array('block': 77, 'button': 'right'), @event) {
	@sign = _relative(@event['location'], 'up');
	if(is_sign_at(@sign)) {
		@line = get_sign_text(@sign);
		if(@type = reg_match('\u00A7[0-9a-f]{1}\\[(.+)\\]', @line[1])) {
			if(is_alias('/'.to_lower(@type[1]).if(@line[2], ' ').to_lower(@line[2]).if(@line[3], ' ').to_lower(@line[3]))) {
				call_alias('/'.to_lower(trim(@type[1])).' '.to_lower(trim(@line[2])).' '.to_lower(trim(@line[3])));
			} else {
				die('Unknown button command.');
			}
		} else if(length(@line[1]) > 1
		&& @line[1][0] === '/'
		&& length(@line[0]) > 2
		&& substr(@line[0], 0, 2) == color(1)) {
			msg('Ran command:' @line[1] @line[2] @line[3]);
			run_cmd(@line[1] @line[2] @line[3]);
			console('Deprecated sign command @ '.@event['location']);
		}
	}
}

# prevent people from pushing minecart hoppers underneath chests
bind(vehicle_collide, null, array('type': 'MINECART_HOPPER', 'hittype': 'PLAYER'), @event) {
	cancel();
}

# prevent enderdragon egg teleportation
bind(player_interact, null, array('block': 122), @event) {
	if(!_is_survival_world(pworld())) {
		cancel();
	}
}

# prevent mobspawner changes with spawner eggs
bind(player_interact, null, array('block': 52, 'item': 383), @event) {
	if(_is_survival_world(pworld())) {
		cancel();
	}
}

# DISPENSER PARKING
bind(vehicle_collide, null, array('type': 'MINECART', 'collisiontype': 'BLOCK', 'hittype': 23), @event) {
	if(is_block_powered(@event['block'])) {
		die();
	}
	for(@i = 0, @i < get_inventory_size(@event['block']), @i++) {
		if(is_null(get_inventory_item(@event['block'], @i))) {
			set_inventory_item(@event['block'], @i, array('type': 328, 'qty': 1));
			entity_remove(@event['id']);
			die();
		}
	}
	if(!_is_survival_world(@event['block']['world'])) {
		entity_remove(@event['id']);
	}
}

# Let one player in a world make the sun rise
bind(player_enter_bed, null, null, @event) {
    if(get_world_time() > 13700 && get_world_time() < 22300) {
		set_world_time(22300);
		msg(color('aqua').'You summoned the sun.');
    } else if(get_world_time() < 13700 && get_world_time() > 11300) {
		@time = get_world_time() - 11300;
		@time = 700 - @time;
		if(@time < 0) {
			@time = @time + 24000;
		}
		set_world_time(@time);
		msg(color('aqua').'You summoned the sun.');
    }
	if(has_storm()) {
		storm(false);
		msg(color('aqua').'You calmed the storm.');
	}
}

bind(player_interact, null, array('block': 26, 'button': 'right'), @event) {
	set_pbed_location(_relative(@event['location'], 'down'), false);
	msg(color('aqua').'Your spawn location has been set to this bed.');
}

# Dispenser handling
# Infinite dispensers on creative/game worlds
# Special behavior for other items (eg. place armor stands)
bind(block_dispense, null, array('type': 'DISPENSER'), @event) {
	if(!_is_survival_world(@event['location']['world'])) {
		if(!array_contains(sk_region_check_flag(@event['location'], 'blocked-cmds'), '/finitedispensers')) {
			try {
				@inv = get_inventory(@event['location']);
			} catch(CastException @ex) {
				die();
			}
			foreach(@i: @item in @inv) {
				if(@item && max_stack_size(@item) > @item['qty'] && @item['name'] != 'MONSTER_EGG') {
					@item['qty'] = max_stack_size(@item);
			queue_push(closure(){
						try {
							set_inventory_item(@event['location'], @i, @item);
						} catch(CastException @ex) {
							console('Could not refill dispenser at '. @event['location']);
						}
			});
					break();
		}
			}
		}
	} else if(@event['item']['type'] == 416) { # armor stand
		try {
			@inv = get_inventory(@event['location']);
		} catch(CastException @ex) {
			die();
		}
		cancel();
		@loc = @event['location'][];
		switch(split(':', get_block_at(@loc))[1]) {
			case '8':
				@loc['y'] -= 1;
			case '9':
				@loc['y'] += 1;
			case '10':
				@loc['z'] -= 1;
				@loc['yaw'] = 180;
			case '11':
				@loc['z'] += 1;
			case '12':
				@loc['x'] -= 1;
				@loc['yaw'] = 90;
			case '13':
				@loc['x'] += 1;
				@loc['yaw'] = 270;
		}
		@loc['x'] += 0.5;
		@loc['z'] += 0.5;
		spawn_entity('ARMOR_STAND', 1, @loc);
		set_timeout(50, closure(){
			set_inventory(@event['location'], @inv);
		});
	}
}

# Limit the number of mobs that can be built up from a mob spawner
bind(creature_spawn, null, array('reason': '/(NETHER_PORTAL|SPAWNER)/'), @event) {
	if(array_size(entities_in_radius(@event['location'], 48, @event['type'])) > 150) {
		cancel();
	}
}

# Limit breeding in high entity areas
bind(creature_spawn, null, array('reason': 'BREEDING'), @event) {
	if(@event['type'] !== 'HORSE'
	&& array_size(entities_in_radius(@event['location'], 64)) > 300) {
		cancel();
		play_effect(@event['location'], 'SMOKE', array('id': 4));
		foreach(@p in players_in_radius(@event['location'], 16)) {
			tmsg(@p, color('gold').'Breeding failed due to overcrowding.');
		}
	}
}

# Anti-xray helper
bind(block_break, null, array('type': 56), @event) {
	if(!_is_survival_world(pworld())) {
		die();
	}
	queue_push(closure(){
		@report = true;
		for(@x = @event['location']['x'] - 1, @x <= @event['location']['x'] + 1, @x++) {
			for(@y = @event['location']['y'] - 1, @y <= @event['location']['y'] + 1, @y++) {
				for(@z = @event['location']['z'] - 1, @z <= @event['location']['z'] + 1, @z++) {
					if(get_block_at(@x, @y, @z) === '56:0') {
						@report = false;
					}
				}
			}
		}

		if(@report) {
			@msg = color('c').'[!] '._colorname().player().color('r').' found diamonds';
			broadcast(@msg, 'group.moderator');
			console(@msg);
		}
	});
}

# leash villagers
bind(player_interact_entity, null, array('clicked': 'VILLAGER'), @event) {
	@item = pinv(player(), null);
	if(@item && @item['type'] == 420
	&& get_player_from_entity_id(get_leashholder(@event['id'])) != player()) {
		cancel();
		set_leashholder(@event['id'], puuid());
		@item['qty'] = @item['qty'] - 1;
		set_pinv(array(null: @item));
	}
}

# painting cycler
bind(player_interact_entity, null, array('clicked': 'PAINTING'), @event) {
	if(sk_can_build(entity_loc(@event['id']))) {
		@paintings = get_value('paintings');
		if(is_null(@paintings)) {
			@paintings = reflect_pull('enum', 'Art');
			# this can take over 20ms, so let's save this for later
			store_value('paintings', @paintings);
		}
		@current = entity_spec(@event['id'])['type'];
		@index = array_index(@paintings, @current);
		@tries = 0;
		do {
			@next = @paintings[(@index = (@index + 1) % array_size(@paintings))];
			set_entity_spec(@event['id'], array('type': @next));
			# if successful, the entity id/uuid will change
			# but just in case, only try 20 times (enough to cycle from the last 1x1 back to the first 1x1)
		} while(entity_exists(@event['id']) && @tries++ < 20);
		if(extension_exists('CHNaughty')) {
			action_msg(@next);
		}
	}
}

# Block creeper damage on the surface.
bind(entity_explode, null, array('type': 'CREEPER'), @event) {
	if(@event['location']['y'] > 62
	&& array_contains(array('world', 'world3', 'world4', 'omega'), @event['location']['world'])) {
		cancel();
		play_effect(@event['location'], 'EXPLOSION_HUGE');
	}
}

# prevent egg-spawned named mobs from despawning
bind(creature_spawn, null, array('reason': 'SPAWNER_EGG'), @event) {
	set_timeout(50, closure(){
		try(
			if(get_mob_name(@event['id'])) {
				set_entity_persistence(@event['id'], true);
			}
		);
	});
}

# block skeleton trap horses in regions
bind(creature_spawn, null, array('reason': 'LIGHTNING', 'type': 'HORSE'), @event) {
	if(@event['location']['world'] != 'outworld') {
		cancel();
	}
}

# prevent enderpearls from damaging item frames and paintings
bind(entity_damage, null, array('type': 'ITEM_FRAME', 'cause': 'PROJECTILE'), @event) {
	if(entity_type(@event['damager']) === 'ENDER_PEARL') {
		cancel();
	}
}

bind(note_play, null, null, @event) {
	cancel();
	@sound = 'NOTE_'.@event['instrument'];
	switch(split(':', get_block_at(_relative(@event['location'], 'down')))[0]) {
		case '79':
		case '174':
			@sound = 'orb_pickup';
		case '145':
			@sound = 'anvil_land';
		case '159':
		case '172':
			@sound = 'note_pling';
	}
	play_sound(@event['location'], array(
		'sound': @sound,
		'pitch': _get_pitch(@event['tone'], @event['octave']),
		'volume': if(is_block_powered(@event['location']), 9, 1)
	));
	@event['location']['x'] += 0.5;
	@event['location']['z'] += 0.5;
	play_effect(_relative(@event['location'], 'up'), 'note');
}

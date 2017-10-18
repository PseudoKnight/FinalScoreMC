set_cron('*/5 * * * *', closure(){
	foreach(@world in get_worlds()) {
		queue_push(closure(){
			save_world(@world);
		});
	}
	queue_push(closure(){
		save_players();
		@currently = '';
		@activitiesArray = import('activities');
		if(@activitiesArray) {
			@activities = array_implode(array_normalize(@activitiesArray), ', ');
		}
		@allocMem = get_server_info(15);
		@freeMem = get_server_info(16);
		console('---[ SAVED ]---[ TPS: '.round(tps()[0], 1).' ]'
			.'---[ MEM: '.floor((@allocMem - @freeMem) / 1000000).' / '.floor(@allocMem / 1000000).' / 2863 MB ]'
			.'---[ PLAYERS: '.array_size(all_players()).' ]'
			.'---'.if(@currently, '[ Activities: '.@currently.' ]---'), false);
	});
})

bind(server_ping, null, null, @event) {
	@activities = import('activities');
	@currently = '';
	if(@activities) {
		@currently = array_implode(array_normalize(@activities), ', ');
	}
	@motd = colorize('&6&l\u1260&d&l\u1260&b&l\u1260&4&l\u1260 &6&lFINALSCORE&e&lMC \u00AB &f\u25AA \u25AA \u25AA');
	modify_event('motd', @motd.if(@currently, colorize('\n&aActivities&f: ').@currently));
}

bind(player_command, null, null, @event) {
	try {
		if(@event['command'] != '/we cui' && @event['command'][1] !== '/') {
			console(@event['player'].' ran: '.@event['command'], false);
		}
	} catch(RangeException @ex) {
		call_alias('/help');
	}
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
						pkick(player(), 'You died while AFK @ '.@loc);
					} else {
						action_msg(@time[0]);
					}
				}
			}
		});
		
		if(array_index_exists(@event['cause'], 'damager')) {
			@damager = @event['cause']['damager'];
			if(@event['cause']['cause'] == 'PROJECTILE') {
				@damager = @event['cause']['shooter'];
			}
			if(length(@damager) > 16 && !get_mob_name(@damager)) {
				@names = get_value('mobnames');
				if(!@names) {
					http_request('http://www.wordgenerator.net/application/p.php?type=1&id=fake_words', array(
						'method': 'GET',
						'success': closure(@response){
							if(!@response['error']) {
								@names = split(',', @response['body']);
								try {
									set_mob_name(@damager, @names[0]);
									set_entity_persistence(@damager, true);
									array_remove(@names, 0);
									store_value('mobnames', @names);
								} catch(BadEntityException @ex) {
									// ignore
								}
							}
						}
					));
				} else {
					try {
						set_mob_name(@damager, @names[0]);
						set_entity_persistence(@damager, true);
						array_remove(@names, 0);
						store_value('mobnames', @names);
					} catch(BadEntityException @ex) {
						// ignore
					}
				}
			}
		}
	} else {
		modify_event('death_message', null);
	}
}

/*
	Blocks spawning of the wither
*/
bind(block_place, null, array('type': 144), @event) {
	if(!has_permission('build.wither')) {
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

# Block lighters
bind(player_interact, null, array('item': 259, 'button': 'right'), @event) {
	if(has_permission('item.lighter')
	|| !array_index_exists(@event, 'location')) {
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
			run_cmd('/'.to_lower(trim(@type[1])).' '.to_lower(trim(@line[2])).' '.to_lower(trim(@line[3])));
		}
	}
}

# prevent enderdragon egg teleportation
bind(player_interact, null, array('block': 122), @event) {
	@world = pworld();
	if(@world == 'dev' || @world == 'custom') {
		cancel();
	}
}

# prevent mobspawner changes with spawner eggs
bind(player_interact, null, array('block': 52, 'item': 383), @event) {
	if(_is_survival_world(pworld())) {
		cancel();
	}
}

# Let one player in a world make the sun rise
bind(player_enter_bed, null, null, @event) {
	if(!_is_survival_world(pworld())) {
		die();
	}
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
	if(@event['location']['world'] == 'shard') {
		cancel();
	} else {
		set_pbed_location(_relative(@event['location'], 'down'), false);
		msg(color('aqua').'Your spawn location has been set to this bed.');
	}
}

# Dispenser handling
# Infinite dispensers on creative/game worlds
# Special behavior for other items (eg. place armor stands)
bind(block_dispense, null, array('type': 'DISPENSER'), @event) {
	if(@event['item'] && array_contains(array(325, 326, 327), @event['item']['type'])) {
		// Always ignore buckets
	} else if(!_is_survival_world(@event['location']['world'])) {
		if(!array_contains(sk_region_check_flag(@event['location'], 'blocked-cmds'), '/finitedispensers')) {
			try {
				@inv = get_inventory(@event['location']);
			} catch(CastException @ex) {
				die();
			}
			foreach(@i: @item in @inv) {
				if(@item && @item['qty'] < 64) {
					@item['qty'] = 64;
					queue_push(closure(){
						try {
							set_inventory_item(@event['location'], @i, @item);
						} catch(CastException @ex) {
							console('Could not refill dispenser at '. @event['location'], false);
						}
					});
					break();
				}
			}
		}
	}
    if(@event['item'] && @event['item']['type'] == 416) { # armor stand
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

# Limit breeding in high entity areas
bind(creature_spawn, null, array('reason': 'BREEDING'), @event) {
	if(!array_contains(array('DONKEY', 'HORSE', 'MULE'), @event['type'])
	&& array_size(entities_in_radius(@event['location'], 64)) > 300) {
		cancel();
		play_effect(@event['location'], 'SMOKE', array('id': 4));
		foreach(@p in players_in_radius(@event['location'], 16)) {
			tmsg(@p, color('gold').'Breeding failed due to overcrowding.');
		}
	}
}

bind(creature_spawn, null, array('reason': 'EGG'), @event) {
	if(array_size(entities_in_radius(@event['location'], 8)) > 200) {
		cancel();
		play_effect(@event['location'], 'SMOKE', array('id': 4));
		foreach(@p in players_in_radius(@event['location'], 16)) {
			tmsg(@p, color('gold').'Chicken failed to hatch due to overcrowding.');
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
			console(@msg, false);
		}
	});
}

# painting cycler
bind(player_interact_entity, null, array('clicked': 'PAINTING','hand':'main_hand'), @event) {
	if(pmode() != 'ADVENTURE' && pworld() != 'shard' && sk_can_build(entity_loc(@event['id']))) {
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
		try {
			if(get_mob_name(@event['id'])) {
				set_entity_persistence(@event['id'], true);
			}
		} catch(BadEntityException @ex) {
			// spawn was cancelled
		}
	});
}

# block skeleton trap horses in regions
bind(creature_spawn, null, array('reason': 'LIGHTNING', 'type': 'SKELETON_HORSE'), @event) {
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

// Custom noteblock sounds
bind(note_play, null, null, @event) {
	cancel();
	@sound = 'NOTE_'.@event['instrument'];
	switch(split(':', get_block_at(_relative(@event['location'], 'down')))[0]) {
		case '79':
		case '174':
			@sound = 'ORB_PICKUP';
		case '145':
			@sound = 'ANVIL_LAND';
		case '159':
		case '172':
			@sound = 'NOTE_PLING';
		case '165':
			@sound = 'CHICKEN_EGG_POP';
		case '173':
			@sound = 'FIREWORK_BLAST';
		case '169':
			@sound = 'BLOCK_NOTE_CHIME';
		case '35':
			@sound = 'BLOCK_NOTE_GUITAR';
		case '82':
			@sound = 'BLOCK_NOTE_FLUTE';
		case '41':
			@sound = 'BLOCK_NOTE_BELL';
		case '216':
			@sound = 'BLOCK_NOTE_XYLOPHONE';
	}
	play_sound(@event['location'], array(
		'sound': @sound,
		'category': 'RECORDS',
		'pitch': _get_pitch(@event['tone'], @event['octave']),
		'volume': if(is_block_powered(@event['location']), 8, 1)
	));
	@event['location']['x'] += 0.5;
	@event['location']['z'] += 0.5;
	play_effect(_relative(@event['location'], 'up'), 'note');
}

// Improve bow launching
bind(entity_damage_player, null, array('damager': 'ARROW'), @event) {
	if(player() == @event['data'] && !entity_grounded(puuid()) && !get_entity_gliding(puuid())) {
		@item = pinv(player(), 102);
		if(@item && @item['name'] == 'ELYTRA') {
			set_entity_gliding(puuid(), true);
			play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'category': 'PLAYERS', 'pitch': 1.3, 'volume': 0.4));
		}
	}
}

// Block firework damage in Park
bind(entity_damage, null, array('cause': 'ENTITY_EXPLOSION', 'world': 'custom'), @event) {
	if(entity_type(@event['damager']) == 'FIREWORK') {
		cancel();
	}
}

// Always drop full enderdragon experience
bind(entity_death, null, array('type': 'ENDER_DRAGON'), @event) {
	if(@event['xp'] < 12000) {
		modify_event('xp', 12000);
		@loc = get_highest_block_at(0, 0, @event['location']['world']);
		@loc['y'] += 1;
		set_block_at(@loc, data_values('enderdragon_egg'));
	}
}

// Block ghast fireball damage to all but natural nether blocks
bind(entity_explode, null, array('type': 'FIREBALL'), @event) {
	@world = @event['location']['world'];
	if(world_info(@world)['environment'] == 'NETHER' && @world != 'outworld_nether') {
		@blocks = @event['blocks'];
		@breakables = array('87:0', '88:0', '13:0', '213:0', '89:0', '153:0');
		@modify = false;
		foreach(@index: @block in @blocks) {
			if(!array_contains(@breakables, get_block_at(@block))) {
				array_remove(@blocks, @index);
				@modify = true;
			}
		}
		if(@modify) {
			modify_event('blocks', @blocks);
		}
	}
}

// Hand instruments
bind(item_swap, null, null, @event,
	@instruments = array(
		'IRON_NUGGET': array('note': 'flute', 'name': 'Ocarina'),
		'GOLD_NUGGET': array('note': 'bell', 'name': 'Bell'),
		'STRING': array('note': 'guitar', 'name': 'Lute'),
		'BONE': array('note': 'xylophone', 'name': 'Bones'),
	)
) {
	@offhand = @event['off_hand'];
	if(@offhand) {
		@material = @offhand['name'];
		if(array_index_exists(@instruments, @material)) {
			@instrument = @instruments[@offhand['name']];
			action_msg('Playing '.@instrument['name'].'...');
			if(has_bind(player().'instrument')) {
				unbind(player().'instrument');
			}
			bind(item_held, array('id': player().'instrument'), null, @event,
				@material,
				@player = player(),
				@sound = 'block.note.'.@instrument['note'],
				@notes = array(0.62, 0.7, 0.8, 0.95, 1.05, 1.25, 1.4, 1.59),
			) {
				@num = @event['to'];
				if(@player == player() && @num != 8) {
					@item = pinv(player(), -106);
					if(@item && @item['name'] == @material) {
						cancel();
						play_named_sound(ploc(), array('sound': @sound, 'pitch': @notes[@num], 'category': 'VOICE'));
					} else {
						unbind();
					}
				}
			}
			set_timeout(50, closure(try(set_pheld_slot(8))));
		}
	}
}

// Survival PVP
bind(entity_damage_player, null, null, @event) {
	if(!is_array(@event['data']) # is not dispenser
	&& ponline(@event['data']) # is player
	&& @event['data'] != @event['player'] # is not self-inflicted
	&& _is_survival_world(@event['location']['world'])) {
		@vehicle = get_entity_vehicle(puuid(@event['player']));
		@weapon = pinfo(@event['data'], 6);
		if(@vehicle && @weapon == '280:0') { # stick is lance
			modify_event('amount', 0);
			set_entity_rider(@vehicle, null);
		} else {
			cancel();
		}
	}
}

// Prevents chickens in chicken jockeys from spawning when mob-spawning is disabled
bind(creature_spawn, null, array('type': 'CHICKEN', 'reason': 'MOUNT'), @event) {
    @loc = @event['location'];
	if(_is_survival_world(@loc['world']) && array_contains(sk_region_check_flag(@loc, 'deny-spawn'), 'zombie')) {
		cancel();
	}
}
 

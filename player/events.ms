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
			if(!ponline(player()) || phealth() > 0) {
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

# spawner eggs
bind(player_interact, null, array('item': 383, 'button': 'right'), @event) {
	if(_is_survival_world(pworld())) {
		if(@event['block'] == '52') {
			cancel();
		}
	} else if(array_index_exists(@event, 'location') && sk_can_build(@event['location'])) {
		// this ignores mob spawning flags creative/game worlds
		cancel();
		@item = null;
		if(@event['hand'] == 'main_hand') {
			@item = pinv(player(), null);
		} else {
			@item = pinv(player(), -106);
		}
		if(@item['meta']['spawntype']) {
			@loc = _relative(@event['location'], @event['facing']);
			@loc['x'] += 0.5;
			@loc['z'] += 0.5;
			@entity = spawn_entity(@item['meta']['spawntype'], 1, @loc)[0];
			set_entity_persistence(@entity, true);
		}
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
			@msg = color('c').'[!] '.display_name().color('r').' found diamonds';
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
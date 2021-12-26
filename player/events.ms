bind('player_command', null, null, @event) {
	try {
		if(@event['command'][1] !== '/') {
			console(@event['player'].' ran: '.@event['command'], false);
		}
	} catch(RangeException @ex) {
		call_alias('/help');
	}
}

bind('player_death', null, null, @event) {
	if(_is_survival_world(@event['location']['world'])) {
		@loc = @event['location'];
		@stringLoc = floor(@loc['x']).','.floor(@loc['y']).','.floor(@loc['z']).' '._worldname(@loc['world']);

		// Log to console
		@log = @event['player'].' died @ '.@stringLoc.': ';
		_minify_inv(@event['drops']);
		@log .= json_encode(@event['drops']);
		console(@log, false);

		// Broadcast to players
		msg(color('yellow').'You died @ '.@stringLoc);
		foreach(@player in all_players()) {
			if(@player != player() && has_permission(@player, 'group.regular')) {
				tmsg(@player, color('gray').@event['player'].' died @ '.@stringLoc);
			}
		}

		// Discord
		if(function_exists('discord_broadcast')) {
			discord_broadcast('minecraft_chat', '*'.@event['death_message'].' @ '.@stringLoc.'*');
		}

		// Check if the player hasn't respawned in 60 seconds. 
		// This way we can prevent their items from despawning if they're AFK.
		@time = array(60);
		set_interval(1000, closure(){
			if(!ponline(player()) || phealth() > 0) {
				clear_task();
			} else {
				@time[0] -= 1;
				if(@time[0] < 30) {
					if(@time[0] == 0) {
						clear_task();
						pkick(player(), 'You died while AFK @ '.@stringLoc);
					} else {
						action_msg(@time[0]);
					}
				}
			}
		});

		// Extend death drop despawn time for another 5 minutes
		// First tag drops over the next tick
		@bind = bind('item_spawn', null, null, @event) {
			add_scoreboard_tag(@event['id'], 'deathdrop');
		}
		set_timeout(50, closure(unbind(@bind)));

		// Finally cancel despawns for those item entities once (sets their age to 0)
		if(!has_bind('deathdrops')) {
			bind('item_despawn', array('id': 'deathdrops'), null, @event) {
				if(array_contains(get_scoreboard_tags(@event['id']), 'deathdrop')) {
					remove_scoreboard_tag(@event['id'], 'deathdrop');
					cancel();
				}
			}
		}

		// Remove 100xp cap from dropped experience.
		// Why does this even exist?
		modify_event('xp', plevel() * 7);

		/*
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
							try {
								if(!@response['error']) {
									@names = split(',', @response['body']);
									set_mob_name(@damager, @names[0]);
									set_entity_persistence(@damager, true);
									array_remove(@names, 0);
									store_value('mobnames', @names);
								}
							} catch(Exception @ex) {
								// ignore
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
		*/
	} else {
		modify_event('death_message', null);
	}
}

/*
	Logs spawning of a wither
*/
bind('block_place', null, array(block: 'WITHER_SKELETON_SKULL'), @event) {
	@loc = @event['location'];
	foreach(@dir in array('north', 'south', 'east', 'west', 'up', 'down')) {
		@block = get_block(location_shift(@loc, @dir));
		if(@block == 'SOUL_SAND' || @block == 'SOUL_SOIL') {
			@player = player();
			@stringLoc = floor(@loc['x']).','.floor(@loc['y']).','.floor(@loc['z']).' '._worldname(@loc['world']);
			console("@player spawning a wither at @stringLoc!", false);
			break();
		}
	}
}

# Block lighters
bind('player_interact', null, array('itemname': 'FLINT_AND_STEEL', 'button': 'right'), @event) {
	if(has_permission('item.lighter')
	|| !array_index_exists(@event, 'location')) {
		die();
	}
	@loc = @event['location'];
	if(@event['block'] === 'TNT') {
		die();
	} else if(@event['block'] === 'OBSIDIAN' && @event['facing'] === 'up') {
		queue_push(closure(){
			if(get_block(location_shift(@loc, 'up')) !== 'NETHER_PORTAL') {
				set_block(location_shift(@loc, 'up'), 'AIR');
			}
		});
	} else {
		if(!sk_regions_at(location_shift(@loc, 'up')) || !sk_can_build(location_shift(@loc, 'up'))) {
			cancel();
			msg('Use of flint and steel is restricted here, except on nether portals and TNT.');
		}
	}
}

# Button commands
bind('player_interact', null, array('block': 'STONE_BUTTON', 'button': 'right'), @event) {
	@sign = location_shift(@event['location'], 'up');
	if(is_sign_at(@sign)) {
		@line = get_sign_text(@sign);
		if(@type = reg_match('\u00A7[0-9a-f]{1}\\[(.+)\\]', @line[1])) {
			run_cmd('/'.to_lower(trim(@type[1])).' '.to_lower(trim(@line[2])).' '.to_lower(trim(@line[3])));
		}
	}
}

# prevent enderdragon egg teleportation
bind('player_interact', null, array('block': 'DRAGON_EGG'), @event) {
	if(!_is_survival_world(@event['world']) && (@event['button'] == 'right' || pmode() != 'CREATIVE')) {
		cancel();
	}
}

# spawner eggs
bind('player_interact', null, array('button': 'right'), @event) {
	@item = @event['item'];
	if(@item && string_ends_with(@item['name'], '_SPAWN_EGG')) {
		if(_is_survival_world(pworld())) {
			if(@event['block'] == 'SPAWNER') {
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
			@type = reg_match('(.*)_SPAWN_EGG', @item['name'])[1];
			if(@type == 'MOOSHROOM') {
				@type = 'MUSHROOM_COW';
			}
			@loc = location_shift(@event['location'], @event['facing']);
			@loc['x'] += 0.5;
			@loc['z'] += 0.5;
			@entity = spawn_entity(@type, 1, @loc)[0];
			set_entity_persistence(@entity, true);
		}
	}
}

# Let one player in a world make the sun rise
bind('player_enter_bed', null, null, @event) {
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

# Anti-xray helper
bind('block_break', null, array('block': 'DIAMOND_ORE'), @event) {
	if(!_is_survival_world(pworld())) {
		die();
	}
	queue_push(closure(){
		@report = true;
		for(@x = @event['location']['x'] - 1, @x <= @event['location']['x'] + 1, @x++) {
			for(@y = @event['location']['y'] - 1, @y <= @event['location']['y'] + 1, @y++) {
				for(@z = @event['location']['z'] - 1, @z <= @event['location']['z'] + 1, @z++) {
					if(get_block(array(@x, @y, @z, pworld())) === 'DIAMOND_ORE') {
						@report = false;
					}
				}
			}
		}

		if(@report) {
			@msg = color('c').'[!] '.display_name().color('r').' found diamonds';
			broadcast(@msg, 'group.moderator');
		}
	});
}

# painting cycler
bind('player_interact_entity', null, array('clicked': 'PAINTING','hand': 'main_hand'), @event) {
	if(pmode() != 'ADVENTURE' && sk_can_build(entity_loc(@event['id']))) {
		@paintings = reflect_pull('enum', 'Art');
		@current = entity_spec(@event['id'])['type'];
		@index = array_index(@paintings, @current);
		@tries = 0;
		@next = null;
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

// Hand instruments
bind('item_swap', null, null, @event,
	@instruments = array(
		'IRON_NUGGET': array('note': 'flute', 'name': 'Ocarina'),
		'GOLD_NUGGET': array('note': 'bell', 'name': 'Bell'),
		'STRING': array('note': 'guitar', 'name': 'Lute'),
		'BONE': array('note': 'xylophone', 'name': 'Bones'),
		'IRON_INGOT': array('note': 'iron_xylophone', 'name': 'Iron Xylophone'),
		'BAMBOO': array('note': 'didgeridoo', 'name': 'Didgeridoo'),
	)
) {
	@offhand = @event['off_hand'];
	if(@offhand) {
		@material = @offhand['name'];
		if(array_index_exists(@instruments, @material)) {
			@instrument = @instruments[@material];
			action_msg('Playing '.@instrument['name'].'...');
			if(has_bind(player().'instrument')) {
				unbind(player().'instrument');
			}
			bind('item_held', array('id': player().'instrument'), null, @event,
				@material,
				@player = player(),
				@sound = 'block.note_block.'.@instrument['note'],
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
			set_timeout(1, closure(try(set_pheld_slot(8))));
		}
	}
}

// Survival PVP
bind('entity_damage_player', null, null, @event) {
	if(!is_array(@event['data']) # is not dispenser
	&& ponline(@event['data']) # is player
	&& @event['data'] != @event['player'] # is not self-inflicted
	&& _is_survival_world(@event['location']['world'])) {
		@vehicle = get_entity_vehicle(puuid(@event['player']));
		@weapon = pinfo(@event['data'], 6);
		if(@vehicle && @weapon == 'STICK') { # stick is lance
			modify_event('amount', 0);
			set_entity_rider(@vehicle, null);
		} else {
			cancel();
		}
	}
}

# Elytra skipping
bind('entity_toggle_glide', null, array('type': 'PLAYER'), @event) {
	if(!@event['gliding'] && _is_survival_world(ploc()['world'])) {
		@item = pinv(player(), null);
		if(@item && @item['name'] == 'SLIME_BLOCK') {
			cancel();
			@skipping = import('skipping');
			if(!@skipping) {
				@skipping = associative_array();
				export('skipping', @skipping);
			}
			if(!array_index_exists(@skipping, player()) || @skipping[player()] + 500 < time()) {
				@skipping[player()] = time();
				@loc = location_shift(ploc(), 'up');
				play_sound(@loc, array('sound': 'ENTITY_SLIME_SQUISH', 'pitch': 0.8, 'volume': 0.5));
				spawn_particle(@loc, array('particle': 'SLIME', 'count': 8));
			} else if(array_index_exists(@skipping, player()) && @skipping[player()] + 250 < time()) {
				cancel(false);
			}
		}
	}
}

# Minecart speed control (can cause derailment and other issues after around 5/ms)
bind('vehicle_enter', null, array('vehicletype': 'MINECART', 'passengertype': 'PLAYER'), @event) {
	if(_is_survival_world(pworld()) && !has_bind(player().'vehiclecontrol')) {
		bind('player_interact', array('id': player().'vehiclecontrol'), array('hand': 'main_hand', 'player': player()), @event) {
			@vehicle = get_entity_vehicle(puuid());
			if(@vehicle && entity_type(@vehicle) == 'MINECART') {
				@speed = get_entity_max_speed(@vehicle) * 20;
				if(@event['button'] == 'left') {
					@speed -= 1.0;
				} else {
					@speed += 1.0;
				}
				@speed = clamp(@speed, 0, 40);
				action_msg(integer(@speed).'m/s');
				set_entity_max_speed(@vehicle, @speed / 20);
			} else {
				unbind();
			}
		}
	}
}

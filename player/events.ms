bind('player_death', null, null, @event) {
	if(_is_survival_world(@event['location']['world'])) {
		@loc = @event['location'];
		@x = floor(@loc['x']);
		@y = floor(@loc['y']);
		@z = floor(@loc['z']);
		@world = @loc['world'];

		@pdata = _pdata(player());
		@pdata['death'] = array(@x, @y, @z, @world);

		@stringLoc = "@x,@y,@z "._world_name(@world);

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

		// Check if the player has not respawned in 60 seconds. 
		// This way we can prevent their items from despawning if they are AFK.
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
					console('Reset death drop despawn: '.@event['item']['name']);
					remove_scoreboard_tag(@event['id'], 'deathdrop');
					cancel();
				}
			}
		}

		// Remove 100xp cap from dropped experience.
		// Why does this even exist?
		modify_event('xp', plevel() * 7);

		if(array_index_exists(@event['cause'], 'damager')) {
			@damager = @event['cause']['damager'];
			if(@event['cause']['cause'] == 'PROJECTILE') {
				@damager = @event['cause']['shooter'];
			}
			if(length(@damager) > 16 && !get_mob_name(@damager)) {
				scriptas('~console', // avoid exception spam to player if this breaks
					@entityType = _to_upper_camel_case(entity_type(@damager));
					@setNames = closure(@names) {
						try {
							if(entity_type(@damager) != 'WARDEN') {
								set_mob_name(@damager, array_remove(@names, 0).' the '.@entityType);
								set_entity_persistence(@damager, true);
								store_value('mobnames', @names);
							}
						} catch(BadEntityException @ex) {
							// ignore
						}
					}
					@names = get_value('mobnames');
					if(@names && @names[0]) {
						@setNames(@names);
					} else {
						http_request('https://www.wordgenerator.net/application/p.php?type=1&id=fake_words', array(
							'method': 'GET',
							'success': closure(@response){
								if(!@response['error']) {
									@names = split(',', @response['body']);
									@setNames(@names);
								}
							}
						));
					}
				);
			}
		}
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
			@stringLoc = floor(@loc['x']).','.floor(@loc['y']).','.floor(@loc['z']).' '._world_name(@loc['world']);
			console("@player spawning a wither at @stringLoc!", false);
			break();
		}
	}
}

# Add barriers to dangerous flint&steel use
bind('player_interact', null, array(itemname: 'FLINT_AND_STEEL', button: 'right'), @event) {
	@block = @event['block']
	if(!has_permission('item.lighter')
	&& @block
	&& @block != 'TNT'
	&& @block != 'CAMPFIRE'
	&& @block != 'SOUL_CAMPFIRE'
	&& @block != 'CANDLE_CAKE'
	&& !string_ends_with(@block, 'CANDLE')) {
		if(@block == 'OBSIDIAN' && @event['facing'] == 'up') {
			queue_push(closure(){
				if(get_block(location_shift(@event['location'], 'up')) != 'NETHER_PORTAL') {
					set_block(location_shift(@event['location'], 'up'), 'AIR');
				}
			});
		} else if(!sk_regions_at(location_shift(@event['location'], @event['facing']))) {
			cancel();
			msg('Flint and steel is limited here to nether portals, TNT, campfires, and candles.');
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
		} else if(array_index_exists(@event, 'location') 
		&& sk_can_build(@event['location'])
		&& @event['block'] != 'SPAWNER') {
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
			} else if(@type == 'SNOW_GOLEM') {
				@type = 'SNOWMAN';
			} else if(@type == 'ENDER_DRAGON') {
				die(); // potentially too destructive
			}
			@loc = location_shift(@event['location'], @event['facing']);
			@loc['x'] += 0.5;
			@loc['z'] += 0.5;
			if(array_size(entities_in_radius(@loc, 64)) > 250) {
				spawn_particle(@loc, 'SMOKE_NORMAL');
				die();
			}
			@entity = spawn_entity(@type, 1, @loc)[0];
			set_entity_persistence(@entity, true);
			if(pmode() != 'CREATIVE') {
				@item['qty']--;
				set_pinv(player(), null, @item);
			}
		}
	}
}

# Let one player in a world make the sun rise.
# Set player's home if unset for this world.
bind('player_enter_bed', null, null, @event) {
	if(!_is_survival_world(pworld())) {
		die();
	}
	if(get_world_time() > 13700 && get_world_time() < 22300) {
		if(_world_time_travel(pworld(), 22300, 90)) {
			msg(color('aqua').'You summoned the sun.');
		}
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

	if(has_permission('command.sethome')) {
		@pdata = _pdata(player());
		if(!array_index_exists(@pdata, 'homes')) {
			@pdata['homes'] = associative_array();
		}
		if(!array_index_exists(@pdata['homes'], pworld())) {
			@loc = ploc();
			@pdata['homes'][pworld()] = array(
				floor(@loc['x']) + 0.5,
				@loc['y'],
				floor(@loc['z']) + 0.5,
				pworld(),
				round(@loc['yaw'], 2),
				round(@loc['pitch'], 2),
			);
			_store_pdata(player(), @pdata);
			msg(color('green').'Set your '.color('bold').'/home'.color('green').' teleport location for this world.');
			msg(color('green').'You can use '.color('bold').'/sethome'.color('green').' to change it.');
		}
	}
}

# Anti-xray helper
bind('block_break', null, array(block: 'DIAMOND_ORE'), @event) {
	if(!_is_survival_world(pworld())) {
		die();
	}
	@loc = @event['location'];
	set_timeout(1, closure(){ // right after event finished, so current block is gone
		@report = true;
		for(@x = @loc['x'] - 1, @x <= @loc['x'] + 1, @x++) {
			for(@y = @loc['y'] - 1, @y <= @loc['y'] + 1, @y++) {
				for(@z = @loc['z'] - 1, @z <= @loc['z'] + 1, @z++) {
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
bind('player_interact_entity', null, array(clicked: 'PAINTING', hand: 'main_hand'), @event) {
	if(pmode() != 'ADVENTURE' && sk_can_build(entity_loc(@event['id']))) {
		@paintings = reflect_pull('enum', 'Art');
		@current = entity_spec(@event['id'])['type'];
		@index = array_index(@paintings, @current);
		@tries = 0;
		@next = null;
		do {
			@index = (@index + 1) % array_size(@paintings);
			@next = @paintings[@index];
			set_entity_spec(@event['id'], array(type: @next));
			# but just in case, only try 20 times (enough to cycle from the last 1x1 back to the first 1x1)
		} while(entity_spec(@event['id'])['type'] != @next && ++@tries < 20)
		if(extension_exists('CHNaughty')) {
			action_msg(@next);
		}
	}
}

// Hand instruments
@instruments = array(
	IRON_NUGGET: 'block.note_block.flute',
	GOLD_NUGGET:'block.note_block.bell',
	BONE: 'block.note_block.xylophone',
	IRON_INGOT: 'block.note_block.iron_xylophone',
	PRISMARINE_CRYSTALS: 'block.note_block.chime',
);

bind('player_interact', null, null, @event, @instruments) {
	@item = @event['item'];
	if(@item && !@item['meta']) {
		@material = @item['name'];
		if(array_index_exists(@instruments, @material)) {
			@loc = location_shift(ploc(), 'up', 3);
			if(@event['button'] == 'left') {
				if(@event['block']) {
					play_named_sound(@loc, array(sound: 'block.note_block.snare', category: 'VOICE'));
				}
			} else {
				@note = floor((-@loc['pitch'] + 90) / 7.5);
				if(@event['hand'] == 'off_hand') {
					@note += if(@note < 21, 4, -5);
				}
				@pitch = 2 ** ((@note - 12) / 12);
				play_named_sound(@loc, array(sound: @instruments[@material], pitch: @pitch, category: 'VOICE'));
				@loc['x'] += rand() * 1.4 - 0.7;
				@loc['z'] += rand() * 1.4 - 0.7;
				spawn_particle(@loc, array(particle: 'NOTE', speed: 4.0, xoffset: abs(@loc['pitch'] - 90) / 180));
			}
		}
	}
}

bind('player_toggle_sneak', null, array(sneaking: true), @event, @instruments) {
	@mainhand = pinv(player(), null);
	@offhand = pinv(player(), -106);
	if(@mainhand && !@mainhand['meta'] && array_index_exists(@instruments, @mainhand['name'])) {
		play_named_sound(ploc(), array(sound: 'block.note_block.basedrum', category: 'VOICE'));
	} else if(@offhand && !@offhand['meta'] && array_index_exists(@instruments, @offhand['name'])) {
		play_named_sound(ploc(), array(sound: 'block.note_block.basedrum', category: 'VOICE'));
	}
}

// Survival PVP
bind('entity_damage_player', null, null, @event) {
	if(!is_array(@event['data']) # is not dispenser
	&& _is_survival_world(@event['location']['world'])) {
		if(@event['damager'] == 'WOLF') {
			if(get_mob_owner(@event['id'])) { # tamed wolves count as pvp
				cancel();
			}
		} else if(ponline(@event['data']) && @event['data'] != @event['player']) { # not self-inflicted
			@vehicle = get_entity_vehicle(puuid(@event['player']));
			@weapon = pinfo(@event['data'], 6);
			if(@vehicle && @weapon == 'STICK') { # stick is lance for jousting
				modify_event('amount', 0);
				set_entity_rider(@vehicle, null);
			} else {
				title(@event['data'], '', color('red').round(@event['amount'], 1), 0, 40, 20);
				cancel();
			}
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
bind('vehicle_enter', null, array(vehicletype: 'MINECART', passengertype: 'PLAYER'), @event) {
	if(_is_survival_world(pworld()) && !has_bind(player().'vehiclecontrol')) {
		@moveBind = bind('vehicle_move', null, array(vehicletype: 'MINECART', passengertype: 'PLAYER', threshold: 0), @event, @player = @event['player']) {
			if(@player == @event['player']) {
				@maxSpeed = get_entity_max_speed(@event['id']);
				if(@maxSpeed > 0.4) {
					@blockData = get_blockdata(@event['to']);
					@block = @blockData['block'];
					if((@block != 'rail' && @block != 'powered_rail')
					|| (@blockData['shape'] != 'east_west' && @blockData['shape'] != 'north_south')) {
						action_msg(@event['passenger'], 'Max Speed: 8 m/s (default speed)');
						set_entity_max_speed(@event['id'], 0.4);
					} else if(@maxSpeed == 1.5) {
						@to = @event['to'];
						@yaw = @to['yaw'] + 90;
						@left = array(
							@to['x'] + cos(to_radians(@yaw)) * 0.32,
							@to['y'],
							@to['z'] + sin(to_radians(@yaw)) * 0.32,
							@to['world']
						);
						@yaw -= 180;
						@right = array(
							@to['x'] + cos(to_radians(@yaw)) * 0.32,
							@to['y'],
							@to['z'] + sin(to_radians(@yaw)) * 0.32,
							@to['world']
						);
						spawn_particle(@left, array(particle: 'FLAME'));
						spawn_particle(@left, array(particle: 'SMOKE_NORMAL'));
						spawn_particle(@right, array(particle: 'FLAME'));
						spawn_particle(@right, array(particle: 'SMOKE_NORMAL'));
					}
				}
			}
		}
		bind('player_interact', array(id: player().'vehiclecontrol'), array(hand: 'main_hand', player: player()), @event, @moveBind) {
			@vehicle = get_entity_vehicle(puuid());
			if(@vehicle && entity_type(@vehicle) == 'MINECART') {
				@speed = get_entity_max_speed(@vehicle) * 20;
				if(@event['button'] == 'left') {
					@speed -= 1.0;
				} else {
					@speed += 1.0;
				}
				@speed = min(max(@speed, 0), 30);
				@speedOutput = 'Max Speed: '.integer(@speed).' m/s';
				if(@speed > 8) {
					@speedOutput .= ' (derailing possible)';
					if(@speed == 30) {
						@speedOutput = color('red').'Max Speed: 39.'.color('k').'34'.color('red')
								.' m/s (where we\'re going, we don\'t need rails)';
					} else if(@speed > 19) {
						@speedOutput = color('red').@speedOutput;
					} else if(@speed > 14) {
						@speedOutput = color('gold').@speedOutput;
					} else {
						@speedOutput = color('yellow').@speedOutput;
					}
				} else if(@speed == 0) {
					set_entity_silent(@vehicle, true);
					@speedOutput = color('red').'Stopped.';
				} else if(@speed < 8) {
					@speedOutput = color('aqua').@speedOutput;
				} else {
					@speedOutput = @speedOutput.' (default speed)';
				}
				action_msg(@speedOutput);
				set_entity_max_speed(@vehicle, @speed / 20);
			} else {
				unbind();
				unbind(@moveBind);
			}
		}
	}
}

/*
bind('region_change', null, null, @event) {
	@world = @event['to']['world'];
	if(@world == 'dev') {
		foreach(@region in @event['toRegions']) {
			if(array_contains(sk_region_owners(@region, @world)['players'], puuid())) {
				action_msg('Entered your region');
				die();
			}
		}
		foreach(@region in @event['fromRegions']) {
			if(array_contains(sk_region_owners(@region, @world)['players'], puuid())) {
				action_msg('Exited your region');
				die();
			}
		}
	}
}
 */

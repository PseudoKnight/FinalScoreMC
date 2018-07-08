proc _hoops_ball_create(@loc) {
	@game = import('hoops');
	if(!@game) {
		@game = array( // standalone
			'ball': '',
			'slime': '',
			'holder': '',
			'lastholder': '',
			'trail': false,
		);
	}
	
	@bball = spawn_entity('SLIME', 1, @loc)[0];
	set_entity_spec(@bball, array('size': 1));
	set_entity_silent(@bball, true);
	set_entity_ai(@bball, false);
	set_entity_invulnerable(@bball, true);
	
	@stand = spawn_entity('ARMOR_STAND', 1, @loc)[0];
	set_entity_spec(@stand, array('small': true, 'visible': false));
	if(function_exists('set_entity_size')) {
		set_entity_size(@stand, 1.0, 1.0);
	}
	
	set_entity_velocity(@stand, array(0, 1, 0));
	
	@game['ball'] = @stand;
	@game['slime'] = @bball;
	
	if(!array_contains(get_bars(), 'hoops')) {
		create_bar('hoops', array('percent': 0.0, 'style': 'SEGMENTED_6')); //standalone
	}
	
	@charge = array(0);
	
	@binds = array();
	@binds[] = bind('player_interact', null, null, @event, @game, @charge, @stand, @binds) {
		if(@game['holder'] == player()) {
			if(@event['button'] == 'left') {
				@trace = ray_trace(player(), 20);
				if(@trace['entities'] && entity_type(@trace['entities'][0]['uuid']) == 'PLAYER') {
					@game['holder'] = player(@trace['entities'][0]['uuid']);
					_hoops_ball_add_player(@game['holder'], @binds, @game);
					set_pinv(@game['holder'], -106, array('name': 'MAGMA_CREAM'));
					set_pinv(player(), array(0: null, -106: null));
					if(array_index_exists(@game, 'teams')) {
						try(update_bar('hoops', array('color': to_upper(@game['players'][@game['holder']]['team']))));
					}
				} else if(@charge[0] > 0) {
					set_pinv(player(), 0, null);
					@game['holder'] = '';
					@game['lastholder'] = player();
					set_entity_spec(@stand, array('gravity': true));
					set_entity_velocity(@stand, get_vector(ploc(), if(@charge[0], @charge[0] / 33, 1.5)));
					@game['trail'] = true;
					@charge[0] = 0;
					if(array_index_exists(@game, 'teams')) {
						try(update_bar('hoops', array('color': 'WHITE')));
					}
				}
			} else if(@charge[0] == 0){
				set_pinv(player(), -106, null);
				set_pinv(player(), 0, array('name': 'MAGMA_CREAM'));
				set_pheld_slot(player(), 0);
				@charge[0] = 1;
				set_interval(50, closure(){
					if(@charge[0] == 0 || !ponline(player())) {
						clear_task();
					} else {
						@charge[0] += 3;
						if(@charge[0] > 100) {
							@charge[0] = 0;
						}
						try(update_bar('hoops', double(@charge[0] / 100)));
					}
				});
			}
		}
	}
	@binds[] = bind('player_interact_entity', null, array('hand': 'main_hand'), @event, @game, @bball, @charge, @stand, @binds) {
		if(@game['holder'] != player()
		&& entity_exists(@stand)
		&& (@event['clicked'] == 'ARMOR_STAND' && @event['id'] == @stand || @event['clicked'] == 'SLIME' && @event['id'] == @bball)) {
			cancel();
			play_sound(ploc(), array('sound': 'ENTITY_IRONGOLEM_STEP', 'pitch': 2.0));
			if(!@game['holder']) {
				set_entity_spec(@stand, array('gravity': false));
			} else {
				set_pinv(@game['holder'], array(-106: null, 0: null));
				play_sound(ploc(), array('sound': 'ENTITY_GHAST_SHOOT', 'pitch': 2.0));
				@game['trail'] = false;
			}
			@game['holder'] = player();
			_hoops_ball_add_player(player(), @binds, @game);
			set_pinv(player(), -106, array('name': 'MAGMA_CREAM'));
			update_bar('hoops', 0.0);
			if(array_index_exists(@game, 'teams')) {
				try(update_bar('hoops', array('color': to_upper(@game['players'][@game['holder']]['team']))));
			}
			@charge[0] = -1;
			set_timeout(250, closure(){
				@charge[0] = 0;
			});
		}
	}
	
	@verticalBounciness = 0.65;
	@bounciness = 0.6;
	@friction = 1.11;
	@rollingFriction = 1.54;
	@gravity = -0.0784000015258789;
	@velocity = array('x': 0, 'y': 0, 'z': 0);
	set_interval(50, closure(){
		try {
			if(@game['holder']) {
				set_entity_loc(@stand, location_shift(ploc(@game['holder']), 'up', 3.3));
			}
			@v = entity_velocity(@stand);
			@loc = entity_loc(@stand);
			if(get_entity_invulnerable(@bball)) {
				@end = false;
				if(@v['y'] < 0 && _hoops_ball_in_hoop(@loc)) {
					@end = true;
					play_sound(@loc, array('sound': 'ENTITY_LLAMA_SPIT', 'volume': 3));
					play_sound(@loc, array('sound': 'ENTITY_GHAST_SHOOT', 'pitch': 0.5, 'volume': 3));
					play_sound(@loc, array('sound': 'ENTITY_ILLUSION_ILLAGER_PREPARE_BLINDNESS', 'volume': 3));
					@cloud = spawn_entity('AREA_EFFECT_CLOUD', 1, @loc)[0];
					set_entity_spec(@cloud, array('particle': 'LAVA', 'radius': 0.1, 'duration': 100));
					if(array_index_exists(@game, 'teams')) {
						@y = 1;
						@block = '';
						do {
							@block = get_block_at(location_shift(@loc, 'down', @y++));
						} while(@block == '0:0');
						if(@block == '251:11') {
							@game['teams']['red']['score']++;
						} else if(@block == '251:14') {
							@game['teams']['blue']['score']++;
						} else {
							console('Detected '.@block.' when expecting red or blue concrete.');
						}
						_hoops_cheer();
					}
				} else if(!array_contains(sk_regions_at(@loc), 'hoops')) {
					@end = true;
					make_effect(@loc, 'ENDER_SIGNAL');
					play_sound(@loc, array('sound': 'ENTITY_ZOMBIE_VILLAGER_CONVERTED', 'pitch': 1.8, 'volume': 3));
					if(array_index_exists(@game, 'teams')) {
						@holder = @game['holder'] ||| @game['lastholder'];
						@team = if(@game['players'][@holder]['team'] == 'red', 'blue', 'red');
						@game['possession'] = @team;
						@location = @loc[];
						@location['x'] = clamp(@location['x'], @game['coords'][1][0], @game['coords'][0][0]) + 0.5;
						@location['y'] = @game['coords'][1][1];
						@location['z'] = clamp(@location['z'], @game['coords'][1][2], @game['coords'][0][2]) + 0.5;
						@game['possessionLoc'] = @location;
						@game['lastholder'] = '';
						_hoops_boo();
					}
				}
				if(@end || !array_contains(get_bars(), 'hoops')) {
					set_entity_invulnerable(@bball, false);
					set_mob_effect(@bball, 11, 2, 10, true, false);
					set_mob_effect(@bball, 20, 1, 10, true, false);
					set_timeout(4000, closure(){
						try(entity_remove(@stand));
					});
					@binds[] = bind('entity_death', null, array('id': @bball), @event, @binds) {
						modify_event('drops', array());
						modify_event('xp', 0);
					}
				}
				play_entity_effect(@bball, 'HURT');
			}
			set_entity_loc(@bball, @loc);
			
			@bounce = false;
			
			if(@v['x'] == 0.0) {
				if(abs(@velocity['x']) > 0.01) {
					@v['x'] = 0 - @velocity['x'] * @bounciness;
					@bounce = true;
				}
			}
			if(@v['z'] == 0.0) {
				if(abs(@velocity['z']) > 0.01) {
					@v['z'] = 0 - @velocity['z'] * @bounciness;
					@bounce = true;
				}
			}
			
			if(@v['magnitude'] < 0.875 && @v['magnitude'] > 0) {
				if(@v['y'] == @gravity && @velocity['y'] > @gravity * 2) {
					@v['x'] = (@v['x'] / @v['magnitude']) * (@rollingFriction * @v['magnitude']);
					@v['z'] = (@v['z'] / @v['magnitude']) * (@rollingFriction * @v['magnitude']);
				} else {
					if(@v['y'] == @gravity && @velocity['y'] < @gravity * 3) {
						@v['y'] = 0 - @velocity['y'] * @verticalBounciness;
						@bounce = true;
						@game['trail'] = false;
					} else {
						@v['x'] = (@v['x'] / @v['magnitude']) * (@friction * @v['magnitude']);
						@v['z'] = (@v['z'] / @v['magnitude']) * (@friction * @v['magnitude']);
					}
				}
			}
			
			if(@bounce) {
				play_sound(@loc, array('sound': 'ENTITY_IRONGOLEM_STEP', 'pitch': 2.0));
			} else if(@game['trail']) {
				if(!queue_running('balltrail')) {
					queue_delay(350, 'balltrail');
				}
				if(!array_index_exists(@game, 'teams')) {
					queue_push(closure(){
						play_effect(location_shift(@loc, 'up', 0.5), 'FLAME', array('speed': 0.0));
					}, 'balltrail');
				} else if(@game['state'] < 3 && @game['lastholder']) {
					@effect = null;
					if(@game['players'][@game['lastholder']]['team'] == 'blue') {
						@effect = array('particleCount': 0, 'speed': 1.0, 'offsetX': 0.01, 'offsetY': 0.0, 'offsetZ': 1.0, 'distance': 32);
					} else {
						@effect = array('particleCount': 0, 'distance': 32);
					}
					queue_push(closure(){
						play_effect(location_shift(@loc, 'up', 0.5), 'COLOURED_DUST', @effect);
					}, 'balltrail');
				}
			}

			@velocity['x'] = @v['x'];
			@velocity['y'] = @v['y'];
			@velocity['z'] = @v['z'];
			set_entity_velocity(@stand, @v);
			
			if(array_index_exists(@game, 'teams')) {
				foreach(@v in array_rand(@game['villagers'], 4, false)) {
					@l = entity_loc(@v);
					@l['yaw'] = get_yaw(@l, @loc);
					@l['pitch'] = get_pitch(@l, @loc) + 10;
					set_entity_loc(@v, @l);
				}
			}
			
		} catch(BadEntityException @ex) {
			if(!array_index_exists(@game, 'state')) {
				foreach(@player in get_bar_players('hoops')) {
					set_pmode(@player, 'ADVENTURE');
					set_peffect(@player, 8, 0, 0, true, false);
				}
				remove_bar('hoops'); // standalone
			}
			foreach(@bind in @binds) {
				unbind(@bind);
			}
			try(entity_remove(@stand));
			@game['ball'] = '';
			@game['slime'] = '';
			clear_task();
		}
	});
}

proc _hoops_ball_add_player(@player, @binds, @game) {
	if(!array_index_exists(@game, 'players') && !array_contains(get_bar_players('hoops'), @player)) {
		bar_add_player('hoops', @player);
		set_pmode(@player, 'SURVIVAL');
		set_phunger(@player, 20);
		set_peffect(@player, 8, 0, 9999, true, false);
	}
}

proc _hoops_ball_in_hoop(@location) {
	@center = get_block_at(@location);
	if(@center == '132:0') {
		// nothing but net
		return(true);
	}
	if(@center == '101:0') {
		// found the rim, now find the net
		for(@x = -1, @x <= 1, @x++) {
			for(@z = -1, @z <= 1, @z++) {
				@loc = @location[];
				@loc['x'] += @x;
				@loc['z'] += @z;
				if(get_block_at(@loc) == '132:0') {
					// check if it's within a meter of the center of the net in both directions
					if(abs(floor(@loc['x']) + 0.5 - @location['x']) < 1
					&& abs(floor(@loc['z']) + 0.5 - @location['z']) < 1) {
						return(true);
					}
					break(2);
				}
			}
		}
		play_sound(@location, array('sound': 'ARROW_HIT', 'pitch': 1.4, 'volume': 3));
	}
	return(false);
}

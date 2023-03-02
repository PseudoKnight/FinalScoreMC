proc _hoops_ball_create(@loc) {
	@game = import('hoops');

	@bball = spawn_entity('SLIME', 1, @loc, closure(@entity) {
		set_entity_spec(@entity, array('size': 1));
		set_entity_silent(@entity, true);
		set_entity_ai(@entity, false);
		set_mob_effect(@entity, 'resistance', 4, 9999, true, false);
	})[0];

	@stand = spawn_entity('ARMOR_STAND', 1, @loc, closure(@entity) {
		set_entity_spec(@entity, array('small': true, 'visible': false));
		if(function_exists('set_entity_size')) {
			set_entity_size(@entity, 0.44, 0.44);
		}
		set_entity_velocity(@entity, array(0, 1, 0));
	})[0];

	@game['ball'] = @stand;
	@game['slime'] = @bball;

	if(!array_contains(get_bars(), 'hoops')) {
		create_bar('hoops', array('percent': 0.0, 'style': 'SEGMENTED_6'));
	}

	_add_activity('hoops', 'Hoops');

	@charge = array(0);
	@ending = array(false);

	@binds = array();
	@binds[] = bind('player_interact', null, null, @event, @game, @charge, @stand, @binds) {
		if(@game['holder'] == player()) {
			if(@event['button'] == 'left') {
				@trace = ray_trace(player(), 20, 0.5);
				if(@trace['entities'] && entity_type(@trace['entities'][0]['uuid']) == 'PLAYER') {
					@holder = player(@trace['entities'][0]['uuid']);
					@game['holder'] = @holder;
					set_pinv(@holder, -106, array('name': 'MAGMA_CREAM'));
					set_pinv(player(), array(0: null, -106: null));
					try(update_bar('hoops', array('color': to_upper(@game['players'][@holder]['team']))))
				} else {
					set_pinv(player(), array(0: null, -106: null));
					@game['holder'] = '';
					@game['lastholder'] = player();
					set_entity_spec(@stand, array('gravity': true));
					set_entity_velocity(@stand, get_vector(ploc(), if(@charge[0] > 0, @charge[0] / 40, if(!array_index_exists(@event, 'location') && ploc()['pitch'] > -10, 1.5, 0.2))));
					@game['trail'] = true;
					@charge[0] = 0;
					try(set_entity_glowing(@game['slime'], false))
					@game['shootLoc'] = ploc();
					try(update_bar('hoops', array('color': 'WHITE')))
				}
			} else if(@charge[0] == 0){
				set_pinv(player(), -106, null);
				set_pinv(player(), 0, array('name': 'MAGMA_CREAM'));
				set_pheld_slot(player(), 0);
				@charge[0] = 1;
				try(set_entity_glowing(@game['slime'], true))
				set_interval(50, closure(){
					if(@game['holder'] != player()) {
						clear_task();
					} else if(@charge[0] == 0 || !ponline(player())) {
						@game['holder'] = '';
						@game['lastholder'] = player();
						try {
							set_entity_spec(@stand, array('gravity': true));
							set_entity_velocity(@stand, array(rand() * 0.2, rand() * 0.2, rand() * 0.2));
							set_entity_glowing(@game['slime'], false);
						} catch(BadEntityException @ex) {
							clear_task();
						}
						try(update_bar('hoops', 0.0))
						if(ponline(player())) {
							set_pinv(player(), array(0: null, -106: null));
						}
						@charge[0] = 0;
					} else {
						@charge[0] += 3;
						if(@charge[0] > 100) {
							@charge[0] = 0;
							try(set_entity_glowing(@game['slime'], false))
						}
						try(update_bar('hoops', double(@charge[0] / 100)))
					}
				});
			}
		}
	}
	@binds[] = bind('player_interact_at_entity', null, array('hand': 'main_hand'), @event, @game, @bball, @charge, @stand, @binds) {
		if(@game['holder'] != player()
		&& array_index_exists(@game['players'], player())
		&& entity_exists(@stand)
		&& (@event['clicked'] == 'ARMOR_STAND' && @event['id'] == @stand || @event['clicked'] == 'SLIME' && @event['id'] == @bball)
		&& @charge[0] == 0) {
			cancel();
			play_sound(ploc(), array('sound': 'ENTITY_IRON_GOLEM_STEP', 'pitch': 2.0));
			if(!@game['holder']) {
				set_entity_spec(@stand, array('gravity': false));
			} else {
				set_pinv(@game['holder'], array(-106: null, 0: null));
				play_sound(ploc(), array('sound': 'ENTITY_GHAST_SHOOT', 'pitch': 2.0));
				@game['trail'] = false;
			}
			@holder = player();
			@game['holder'] = @holder;
			set_pinv(@holder, -106, array('name': 'MAGMA_CREAM'));
			update_bar('hoops', 0.0);
			try(update_bar('hoops', array('color': to_upper(@game['players'][@holder]['team']))))
			@charge[0] = -1;
			set_timeout(250, closure(){
				@charge[0] = 0;
			});
		}
	}
	@binds[] = bind('entity_damage', null, array('id': @bball), @event, @game, @stand, @charge) {
		if(!array_index_exists(@event, 'damager') || @game['holder'] == @event['damager']) {
			die();
		}
		if(@game['holder']) {
			set_pinv(@game['holder'], array(0: null, -106: null));
		}
		@game['lastholder'] = @event['damager'];
		@game['holder'] = '';
		set_entity_spec(@stand, array('gravity': true));
		set_entity_velocity(@stand, get_vector(ploc(@event['damager']), 0.6));
		@charge[0] = 0;
		try(set_entity_glowing(@game['slime'], false))
	}

	@verticalBounciness = 0.7;
	@bounciness = 0.6;
	@dragModifier = 1.115;
	@frictionModifier = 1.54; // higher makes the ball roll faster/longer
	@gravity = -0.0784000015258789;
	@velocity = array('x': 0, 'y': 0, 'z': 0);
	set_interval(50, closure(){
		try {
			@v = entity_velocity(@stand);
			@loc = entity_loc(@stand);
			if(@game['holder']) {
				@ploc = ploc(@game['holder']);
				if(@ploc['world'] == @loc['world']) {
					@loc = location_shift(@ploc, 'up', 3.6);  // max shooting angle: 67.7 degrees
					set_entity_loc(@stand, @loc);
				} else {
					@game['holder'] = null;
				}
			}

			if(!@ending[0]) {
				@end = false;
				if(_hoops_ball_in_hoop(@loc)) {
					if(@game['holder'] || @v['y'] > @gravity) {
						@end = true;
						play_sound(@loc, array('sound': 'ENTITY_ZOMBIE_VILLAGER_CONVERTED', 'pitch': 1.8, 'volume': 3));
						@game['holder'] = '';
						@game['lastholder'] = '';
					} else {
						@end = true;
						play_sound(@loc, array('sound': 'ENTITY_LLAMA_SPIT', 'volume': 3));
						play_sound(@loc, array('sound': 'ENTITY_GHAST_SHOOT', 'pitch': 0.5, 'volume': 3));
						play_sound(@loc, array('sound': 'ENTITY_ILLUSIONER_PREPARE_BLINDNESS', 'volume': 3));
						@cloud = spawn_entity('AREA_EFFECT_CLOUD', 1, @loc)[0];
						set_entity_spec(@cloud, array('particle': 'LAVA', 'radius': 0.1, 'duration': 100));
						@y = 1;
						@block = '';
						do {
							@block = get_block(location_shift(@loc, 'down', @y++));
						} while(@block == 'AIR');
						@points = if(distance(@loc, @game['shootLoc']) > 15 || get_block(@game['shootLoc']) == 'BIRCH_PLANKS', 3, 2);
						@lastHolder = @game['lastholder'];
						@game['players'][@lastHolder]['score'] += @points;
						if(@block == 'RED_CONCRETE') {
							@game['teams']['blue']['score'] += @points;
						} else if(@block == 'BLUE_CONCRETE') {
							@game['teams']['red']['score'] += @points;
						} else {
							console('Detected '.@block.' when expecting red or blue concrete.');
						}
						_hoops_cheer();
					}
				} else if(!array_contains(sk_regions_at(@loc), 'hoops')) {
					make_effect(@loc, 'ENDER_SIGNAL');
					play_sound(@loc, array('sound': 'ENTITY_ZOMBIE_VILLAGER_CONVERTED', 'pitch': 1.8, 'volume': 3));
					try(update_bar('hoops', 0.0))
					if(array_size(@game['players']) == 1 && !@game['holder']) {
						@holder = array_keys(@game['players'])[0];
						@game['lastholder'] = '';
						@game['holder'] = @holder;
						set_entity_spec(@stand, array('gravity': false));
						set_pinv(@holder, -106, array('name': 'MAGMA_CREAM'));
						update_bar('hoops', array('color': to_upper(@game['players'][@holder]['team'])));
					} else if(array_size(@game['players']) >= 2) {
						@end = true;
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
					} else {
						@end = true;
					}
				}
				if(@end || !array_contains(get_bars(), 'hoops')) {
					@ending[0] = true;
					set_mob_effect(@bball, 'resistance', 0, 0, true, false);
					set_mob_effect(@bball, 'resistance', 2, 10, true, false);
					set_mob_effect(@bball, 'wither', 1, 10, true, false);
					set_timeout(4000, closure(){
						try(entity_remove(@stand))
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

			if(@v['magnitude'] < 0.9 && @v['magnitude'] > 0) {
				if(@v['y'] == @gravity && @velocity['y'] > @gravity * 3.2) {
					@v['x'] = (@v['x'] / @v['magnitude']) * (@frictionModifier * @v['magnitude']);
					@v['z'] = (@v['z'] / @v['magnitude']) * (@frictionModifier * @v['magnitude']);
				} else {
					if(@v['y'] == @gravity && @velocity['y'] < @gravity * 3.2) {
						@v['y'] = 0 - @velocity['y'] * @verticalBounciness;
						@bounce = true;
						@game['trail'] = false;
					}
					@v['x'] = (@v['x'] / @v['magnitude']) * (@dragModifier * @v['magnitude']);
					@v['z'] = (@v['z'] / @v['magnitude']) * (@dragModifier * @v['magnitude']);
				}
			}

			if(@bounce) {
				play_sound(@loc, array('sound': 'ENTITY_IRON_GOLEM_STEP', 'pitch': 2.0));
			} else if(@game['trail']) {
				if(!queue_running('balltrail')) {
					queue_delay(350, 'balltrail');
				}
				if(@game['state'] < 3 && @game['lastholder']) {
					@lastHolder = @game['lastholder'];
					if(array_index_exists(@game['players'], @lastHolder)) {
						@effect = array('particle': 'REDSTONE', 'color': @game['players'][@lastHolder]['team']);
						queue_push(closure(){
							spawn_particle(location_shift(@loc, 'up', 0.5), @effect);
						}, 'balltrail');
					}
				}
			}

			@velocity['x'] = @v['x'];
			@velocity['y'] = @v['y'];
			@velocity['z'] = @v['z'];
			set_entity_velocity(@stand, @v);

			foreach(@index: @v in array_rand(@game['villagers'], min(4, array_size(@game['villagers'])), false)) {
				try {
					@l = entity_loc(@v);
					@l['yaw'] = get_yaw(@l, @loc);
					@l['pitch'] = get_pitch(@l, @loc) + 10;
					set_entity_loc(@v, @l);
				} catch(BadEntityException @ex) {
					array_remove_values(@game['villagers'], @v);
				}
			}

		} catch(BadEntityException @ex) {
			foreach(@bind in @binds) {
				unbind(@bind);
			}
			try(entity_remove(@stand))
			@game['ball'] = '';
			@game['slime'] = '';
			_remove_activity('hoops');
			clear_task();
		}
	});
}

proc _hoops_ball_in_hoop(@location) {
	@center = get_block(@location);
	if(@center == 'TRIPWIRE') {
		// nothing but net
		return(true);
	}
	if(@center == 'IRON_BARS') {
		// found the rim, now find the net
		for(@x = -1, @x <= 1, @x++) {
			for(@z = -1, @z <= 1, @z++) {
				@loc = @location[];
				@loc['x'] += @x;
				@loc['z'] += @z;
				if(get_block(@loc) == 'TRIPWIRE') {
					// check if it is within a meter of the center of the net in both directions
					if(abs(floor(@loc['x']) + 0.5 - @location['x']) < 1
					&& abs(floor(@loc['z']) + 0.5 - @location['z']) < 1) {
						return(true);
					}
					break(2);
				}
			}
		}
		play_sound(@location, array('sound': 'ENTITY_ARROW_HIT', 'pitch': 1.4, 'volume': 3));
	}
	return(false);
}

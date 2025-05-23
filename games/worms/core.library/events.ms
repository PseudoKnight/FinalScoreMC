proc _worms_bind_events(@game) {
	bind('player_interact', array('id': 'wormsattack'.@game['region']), array('button': 'right', 'hand': 'main_hand'), @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			if(psneaking()) { // temporary game ender
				_worms_end(@game);
			} else {
				_worms_shoot_projectile(player(), @game);
			}
		}
	}
	
	bind('player_move', array('id': 'wormsmove'.@game['region']), array('threshold': 0), @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			@newLoc = location_shift(@event['to'], 'down', 15);
			if(@newLoc['world'] != @game['world']
			|| @newLoc['x'] > @game['x']['highest']
			|| @newLoc['x'] < @game['x']['lowest']
			|| @newLoc['z'] > @game['z']['highest']
			|| @newLoc['z'] < @game['z']['lowest']) {
				set_timeout(0, closure(_worms_kill(player(), @game)));
			} else {
				@yaw = get_yaw(@event['from'], @event['to']);
				if(@yaw == 'NaN') {
					@yaw = entity_loc(@game['players'][player()]['segments'][0])['yaw'];
				}
				@newLoc['yaw'] = @yaw;
				@newLoc['pitch'] = 0.0001;
				
				@trace = ray_trace(player(), @newLoc, 0.5, 0.4);
				foreach(@e in @trace['entities']) {
					@uuid = @e['uuid'];
					if(entity_type(@uuid) == 'ARMOR_STAND' && !array_contains(@game['players'][player()]['segments'], @uuid)) {
						@item = get_mob_equipment(@e['uuid'])['helmet'];
						@small = entity_spec(@uuid)['small'];
						if(!@small && @item && string_ends_with(@item['name'], '_CONCRETE')) {
							@found = false;
							foreach(@p: @worm in @game['players']) {
								@index = array_index(@worm['segments'], @uuid);
								if(!is_null(@index)) {
									array_remove(@worm['segments'], @index);
									@found = true;
									if(array_size(@worm['segments']) == 0) {
										_worms_kill(@p, @game);
									}
									break();
								}
							}
							if(!@found) {
								array_remove_values(@game['segments'], @uuid);
							}
							_worms_add_segments(player(), @uuid, @game);
							set_entity_spec(@uuid, array('visible': true));
							play_sound(@e['location'], array('sound': 'ENTITY_GENERIC_EAT', 'volume': 2));
						}
					}
				}
				
				if(array_index_exists(@game['players'], player())) {
					if(@trace['hitblock']) {
						@block = get_block(@newLoc);
						if(@block != 'AIR') {
							@match = reg_match('(.+)_CONCRETE', @block);
							if(@match) {
								set_block(@newLoc, 'AIR');
								set_block(location_shift(@newLoc, 'up'), 'AIR');
								set_block(location_shift(@newLoc, 'up', 2), 'AIR');
								@segments = _worms_create_segments(location_shift(ploc(), 'down', 15), 1, @match[1], @game);
								_worms_add_segments(player(), @segments, @game);
								play_sound(@trace['location'], array('sound': 'ENTITY_GENERIC_EAT', 'volume': 2));
							}
						}
					}
					
					if(array_index_exists(@game['players'], player())) {
						foreach(@i: @segment in @game['players'][player()]['segments']) {
							@loc = entity_loc(@segment);
							set_entity_loc(@segment, @newLoc);
							@newLoc = location_shift(@loc, 'down', 0.001);
						}
					}
				}
			}
		}
	}
}

proc _worms_unbind_events(@game) {
	unbind('wormsattack'.@game['region']);
	unbind('wormsmove'.@game['region']);
}

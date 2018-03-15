proc _worms_bind_events(@game) {
	bind(player_interact, array('id': 'wormsattack'.@game['region']), array('button': 'right', 'hand': 'main_hand'), @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			if(psneaking()) { // temporary game ender
				_worms_end(@game);
			} else {
				_worms_shoot_projectile(player(), @game);
			}
		}
	}
	
	bind(player_move, array('id': 'wormsmove'.@game['region']), array('threshold': 0), @event, @game) {
		if(array_index_exists(@game['players'], player())) {
			@newLoc = location_shift(@event['to'], 'down', @game['height']);
			if(@newLoc['world'] != @game['world']
			|| @newLoc['x'] > @game['x']['highest']
			|| @newLoc['x'] < @game['x']['lowest']
			|| @newLoc['z'] > @game['z']['highest']
			|| @newLoc['z'] < @game['z']['lowest']) {
				_worms_remove_player(player(), @game);
			} else {
				@yaw = get_yaw(@event['from'], @event['to']);
				if(@yaw == 'NaN') {
					@yaw = entity_loc(@game['players'][player()]['segments'][0])['yaw'];
				}
				@newLoc['yaw'] = @yaw;
				@newLoc['pitch'] = 0.0;
				
				@trace = ray_trace(@newLoc, 0.8);
				foreach(@e in @trace['entities']) {
					@uuid = @e['uuid'];
					if(entity_type(@uuid) == 'ARMOR_STAND' && !array_contains(@game['players'][player()]['segments'], @uuid)) {
						@item = get_mob_equipment(@e['uuid'])['helmet'];
						if(@item && @item['name'] == 'CONCRETE') {
							@found = false;
							foreach(@p: @worm in @game['players']) {
								@index = array_index(@worm['segments'], @uuid);
								if(!is_null(@index)) {
									array_remove(@worm['segments'], @index);
									@found = true;
									if(array_size(@worm['segments']) == 0) {
										_worms_remove_player(@p, @game);
									}
									break();
								}
							}
							if(!@found) {
								array_remove_values(@game['segments'], @uuid);
							}
							@game['players'][player()]['segments'][] = @uuid;
							set_pscore('segments', player(), array_size(@game['players'][player()]['segments']), 'worms');
							set_entity_spec(@uuid, array('small': false));
							play_sound(@e['location'], array('sound': 'EAT', 'volume': 2));
						}
					}
				}
				
				if(@trace['hitblock']) {
					@block = get_block_at(@newLoc);
					if(@block == '251:14') {
						set_block_at(@newLoc, '0:0');
						set_block_at(location_shift(@newLoc, 'up'), '0:0');
						set_block_at(location_shift(@newLoc, 'up', 2), '0:0');
						_worms_create_segments(player(), 1, @game, 14);
						play_sound(@trace['location'], array('sound': 'EAT', 'volume': 2));
					}
				}
				
				foreach(@i: @segment in @game['players'][player()]['segments']) {
					@loc = entity_loc(@segment);
					set_entity_loc(@segment, @newLoc);
					@newLoc = location_shift(@loc, 'down', 0.001);
				}
			}
		}
	}
}

proc _worms_unbind_events(@game) {
	unbind('wormsattack'.@game['region']);
	unbind('wormsmove'.@game['region']);
}

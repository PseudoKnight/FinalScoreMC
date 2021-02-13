switch(@action) {
case 'load':
	bind('player_interact', array('id': @player.'lightning'), array('itemname': 'BLAZE_ROD', 'button': 'right', 'player': @player), @e, @pvp) {
		if(pinfo(player(), 6) != @e['item']['name']) {
			die();
		}
		@trace = ray_trace(player(), 96);
		@loc = @trace['location'];
		if(@trace['entities']) {
			@loc = @trace['entities'][0]['location'];
		}
		@bind = bind('entity_damage', null, array('type': 'PLAYER', 'cause': 'LIGHTNING'), @e,
				@damager = player(), @pvp) {

			if(!array_index_exists(@pvp['players'], @e['player']), die());
			modify_event('amount', 3.7);
			set_timeout(1, closure(){
				@entity = import(@damager.'lightning');
				if(@e['damager'] == import(@damager.'lightning')) {
					_stats_damage(@damager, @e['player'], 3.7, @pvp);
				}
			});
		}
		spawn_particle(@loc, array('particle': 'CRIT', 'count': 10));
		@lightning = lightning(@loc);
		export(player().'lightning', @lightning);
		@slot = pheld_slot();
		@item = pinv(player(), null);
		set_pinv(player(), null, array('name': 'STICK'));
		set_pcooldown('STICK', 8000 / 50);
		queue_clear(player().'lightning');
		queue_delay(1000, player().'lightning');
		queue_push(closure(){
			unbind(@bind);
			export(player().'lightning', null);
		}, player().'lightning');
		queue_delay(7000, player().'lightning');
		queue_push(closure(){
			if(!ponline(@e['player'])) {
				return();
			}
			@newitem = pinv(player(), @slot)
			if(!is_null(@newitem) && @newitem['name'] == 'STICK') {
				set_pinv(player(), @slot, @item);
				play_sound(ploc(), array('sound': 'BLOCK_FIRE_EXTINGUISH', 'volume': 4))
			}
		}, player().'lightning')
	}

	bind('player_interact', array('id': @player.'woosh'), array('itemname': 'FEATHER', 'button': 'right', 'player': @player), @e, @pvp) {
		if(pinfo(player(), 6) != @e['item']['name']) {
			die();
		}
		@loc1 = location_shift(ploc(), 'up');
		@excludeEntities = array('COMPLEX_PART', 'ITEM_FRAME', 'PAINTING', 'UNKNOWN');
		foreach(@entity in entities_in_radius(@loc1, 10)) {
			@force = 1.4;
			@type = entity_type(@entity);
			if(@type == 'PLAYER') {
				@player = player(@entity);
				if(@player == player() || pmode(@player) == 'SPECTATOR') {
					continue();
				}
				if(entity_grounded(@entity) && psneaking(@player)) {
					@force *= 0.5;
				}
				if(array_index_exists(@pvp, 'teams') && @pvp['players'][player()]['team'] == @pvp['players'][@player]['team']) {
					@force *= 0.5;
				}
			} else if(@type == 'ARMOR_STAND') {
				if(entity_spec(@entity)['visible']) {
					continue();
				}
			} else if(array_contains(@excludeEntities, @type)) {
				continue();
			} else {
				@force *= 0.6;
			}
			@loc2 = entity_loc(@entity);
			@loc2['y'] += 1.0;
			@dist = distance(@loc1, @loc2);

			if(is_entity_living(@entity)) {
				damage_entity(@entity, 1.2, puuid());
			}
			
			if(!entity_can_see(puuid(), @entity)) {
				@force *= 0.5;
			}

			# if we use a queue, velocity works more consistently with grounded entities
			queue_push(closure(){
				try {
					set_entity_velocity(@entity, array(
						@force * ((@loc2['x'] - @loc1['x']) / @dist), # vector normalization
						clamp((@loc2['y'] - @loc1['y']) / @dist, 0.15, @force), # always bounce upwards
						@force * ((@loc2['z'] - @loc1['z']) / @dist),
					));
				} catch(BadEntityException @ex) {
					// they logged off or entity dead; feather OP
				}
			});
		}

		play_sound(@loc1, array('sound': 'ENTITY_ENDER_DRAGON_FLAP', 'pitch': 0.5));
		play_sound(@loc1, array('sound': 'ENTITY_GHAST_SHOOT', 'pitch': 0.9));
		spawn_particle(location_shift(@loc1, 'up'), array(
			'particle': 'CLOUD',
			'count': 60,
			'speed': 0.5,
		));
		_weapon_cooldown(player(), 6000, 'INK_SAC', false, 0);
	}

case 'unload':
	unbind(@player.'lightning')
	unbind(@player.'woosh')

}

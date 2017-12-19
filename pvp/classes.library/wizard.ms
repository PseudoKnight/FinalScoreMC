switch(@action) {
case 'load':
	bind(player_interact, array('id': @player.'lightning'), array('item': 369, 'button': 'right', 'player': @player), @e, @pvp) {
		if(pinfo(player(), 6) != @e['item']) {
			die();
		}
		@trace = ray_trace(player(), 96);
		@loc = @trace['location'];
		if(@trace['entities']) {
			@loc = @trace['entities'][0]['location'];
		}
		bind(entity_damage, array('id': player().'lightningdmg'), array('type': 'PLAYER', 'cause': 'LIGHTNING'), @e,
				@damager = player(), @pvp) {

			if(!array_index_exists(@pvp['players'], @e['player']), die());
			modify_event('amount', 4.0);
			set_timeout(50, closure(){
				@entity = import(@damager.'lightning');
				if(@e['damager'] == import(@damager.'lightning')) {
					_stats_damage(@damager, @e['player'], @e['amount'], @pvp);
				}
			});
		}
		play_effect(@loc, 'CRIT', array('particleCount': 10, 'radius': 96));
		@lightning = lightning(@loc);
		export(player().'lightning', @lightning);
		@slot = pheld_slot();
		@item = pinv(player(), null);
		set_pinv(player(), null, array('type': 280));
		set_pcooldown('STICK', 8000 / 50);
		queue_clear(player().'lightning');
		queue_delay(1000, player().'lightning');
		queue_push(closure(){
			unbind(player().'lightningdmg');
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
				play_sound(ploc(), array('sound': 'FIZZ', 'volume': 4))
			}
		}, player().'lightning')
	}

	bind(player_interact, array('id': @player.'woosh'), array('item': 288, 'button': 'right', 'player': @player), @e) {
		if(pinfo(player(), 6) != @e['item']) {
			die();
		}
		@loc1 = ploc();
		@excludeEntities = array('COMPLEX_PART', 'ITEM_FRAME', 'PAINTING', 'UNKNOWN');
		foreach(@entity in entities_in_radius(ploc(), 9)) {
			@force = 1.4;
			@type = entity_type(@entity);
			if(@type == 'PLAYER') {
				@player = player(@entity);
				if(@player == player() || phealth(@player) == 0) {
					continue();
				}
				if(entity_grounded(@entity) && psneaking(@player)) {
					@force *= 0.4;
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
			@dist = sqrt(((@loc2['x'] - @loc1['x']) ** 2) + ((@loc2['y'] - @loc1['y']) ** 2) + ((@loc2['z'] - @loc1['z']) ** 2));

			if(is_entity_living(@entity)) {
				damage_entity(@entity, 1, puuid());
			}
			
			if(!entity_can_see(puuid(), @entity)) {
				@force *= 0.4;
			}

			# if we use a queue, velocity works more consistently with grounded entities
			queue_push(closure(){
				try {
					set_entity_velocity(@entity, array(
						@force * ((@loc2['x'] - @loc1['x']) / @dist), # vector normalization
						clamp((@loc2['y'] - @loc1['y']) / @dist, 0.1, @force), # always bounce upwards
						@force * ((@loc2['z'] - @loc1['z']) / @dist),
					));
				} catch(BadEntityException @ex) {
					// they logged off or entity dead; feather OP
				}
			});
		}

		play_sound(@loc1, array('sound': 'ENDERDRAGON_WINGS', 'pitch': 0.5));
		play_sound(@loc1, array('sound': 'GHAST_FIREBALL', 'pitch': 0.9));
		play_effect(_relative(@loc1, 'up', 2), 'CLOUD', array(
			'particleCount': 60,
			'speed': 0.5,
		));
		_weapon_cooldown(player(), 6000, 'INK_SACK', false, 0);
	}

case 'unload':
	unbind(@player.'lightning')
	unbind(@player.'woosh')

}

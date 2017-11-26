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
			if(!is_null(@newitem) && @newitem['type'] == 280) {
				set_pinv(player(), @slot, @item);
				play_sound(ploc(), array('sound': 'FIZZ', 'volume': 4))
			}
		}, player().'lightning')
	}

	bind(player_interact, array('id': @player.'woosh'), array('item': 288, 'button': 'right', 'player': @player), @e) {
		if(pinfo(player(), 6) != @e['item']) {
			die();
		}
		@loc1 = ploc()
		foreach(@player in players_in_radius(ploc(), 8)) {
			if(@player == player() || phealth(@player) <= 0, continue())
			@loc2 = ploc(@player)
			@loc2['y'] += 2
			@dist = sqrt(((@loc2['x'] - @loc1['x']) ** 2) + ((@loc2['y'] - @loc1['y']) ** 2) + ((@loc2['z'] - @loc1['z']) ** 2))

			damage_entity(puuid(@player), 1, puuid())
			
			@force = if(entity_grounded(puuid(@player)) && psneaking(@player), 0.7, 1.4);

			# if we use a queue, velocity works more consistently with grounded entities
			queue_push(closure(){
				try {
					set_pvelocity(@player,
						@force * ((@loc2['x'] - @loc1['x']) / @dist), # vector normalization
						clamp((@loc2['y'] - @loc1['y']) / @dist, 0.1, @force), # always bounce upwards
						@force * ((@loc2['z'] - @loc1['z']) / @dist),
					);
				} catch(PlayerOfflineException @ex) {
					// they logged off, feather OP
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

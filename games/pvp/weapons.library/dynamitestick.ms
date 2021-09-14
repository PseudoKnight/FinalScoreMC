@pvp['binds'][] = bind('projectile_hit', null, array(type: 'SNOWBALL'), @event, @pvp) {
	if(get_projectile_item(@event['id'])['name'] != 'RED_CANDLE') {
		die();
	}
	cancel();

	@loc = @event['location'];
	if(!array_contains(sk_regions_at(@loc), @pvp['arena']['region'])) {
		die();
	}
	
	spawn_particle(@loc, 'EXPLOSION_LARGE');
	play_sound(@loc, associative_array(sound: 'ENTITY_GENERIC_EXPLODE', volume: 3));
	foreach(@p in players_in_radius(@loc, 7)) {
		if(pmode(@p) == 'SPECTATOR') {
			continue();
		}
		# a delayed velocity works more consistently with grounded entities
		set_timeout(1, closure(){
			@target = location_shift(ploc(@p), 'up', 2);
			@dist = distance(@loc, @target);
			if(@p == player() && @loc['y'] < @target['y']) {
				damage_entity(puuid(@p), 1, @event['shooter']);
			} else {
				damage_entity(puuid(@p), 8 / max(1, @dist - 1), @event['shooter']);
			}
			try {
				set_pvelocity(@p,
					min(2.2, (@target['x'] - @loc['x']) / (@dist ** 2)),
					min(2.2, (@target['y'] - @loc['y']) / (@dist ** 2)),
					min(2.2, (@target['z'] - @loc['z']) / (@dist ** 2))
				);
			} catch(PlayerOfflineException @ex) {
				// blew completely off server
			}
		});
	}
}

@pvp['binds'][] = bind('player_interact', null, array(itemname: 'RED_CANDLE', button: 'right'), @event, @pvp) {
	if(!array_index_exists(@pvp['players'], player()) || pcooldown('RED_CANDLE')) {
		die();
	}
	cancel();
	@item = pinv(player(), null);
	@item['qty']--;
	set_pinv(player(), null, @item);
	@snowball = shoot_projectile(player(), 'SNOWBALL');
	set_projectile_item(@snowball, array(name: 'RED_CANDLE'));
	play_sound(ploc(), array(sound: 'ENTITY_ARROW_SHOOT', pitch: 0.5));
	set_pcooldown('RED_CANDLE', 50);
	set_interval(50, closure(){
		try {
			spawn_particle(location_shift(entity_loc(@snowball), 'up', 0.5), 'FLAME');
		} catch (Exception @ex) {
			clear_task();
		}
	});
}
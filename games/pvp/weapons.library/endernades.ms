@pvp['binds'][] = bind('player_teleport', array(priority: 'highest'), array(type: 'ENDER_PEARL'), @e, @pvp) {
	if(!array_index_exists(@pvp['players'], player())) {
		die();
	}
	cancel();
	consume();
	if(!array_contains(sk_regions_at(@e['to']), @pvp['arena']['region'])) {
		die();
	}
	
	@a = @e['to'];
	spawn_particle(@a, 'EXPLOSION_LARGE');
	play_sound(@a, associative_array(sound: 'ENTITY_GENERIC_EXPLODE', volume: 3));
	foreach(@e in entities_in_radius(@a, 7)) {
		if(@e == @event['id'] || entity_type(@e) == 'PLAYER' && pmode(@e) == 'SPECTATOR') {
			continue();
		}
		# a delayed velocity works more consistently with grounded entities
		set_timeout(1, closure(){
			@b = location_shift(entity_loc(@e), 'up');
			@dist = distance(@a, @b);
			if(is_entity_living(@e)) {
				if(@e == puuid() && @a['y'] < @b['y']) {
					damage_entity(@e, 1, puuid());
				} else {
					damage_entity(@e, 8 / max(1, @dist - 1), puuid());
				}
			}
			try {
				set_entity_velocity(@e, array(
					min(2.2, (@b['x'] - @a['x']) / (@dist ** 2)),
					min(2.2, (@b['y'] - @a['y']) / (@dist ** 2)),
					min(2.2, (@b['z'] - @a['z']) / (@dist ** 2))
				));
			} catch(PlayerOfflineException @ex) {
				// blew completely off server
			}
		});
	}
}

@pvp['binds'][] = bind('player_interact', array(priority: 'highest'), array(itemname: 'ENDER_PEARL', button: 'right'), @e, @pvp) {
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @e['item']['name']) {
		die();
	}
	cancel();
	shoot_projectile(player(), 'ENDER_PEARL');
	play_sound(ploc(), array(sound: 'ENTITY_ARROW_SHOOT', pitch: 0.5));
	_weapon_cooldown(player(), 2500, 'MAGMA_CREAM', closure(){
		play_sound(ploc(), array(sound: 'ENTITY_IRON_GOLEM_ATTACK'));
	});
}

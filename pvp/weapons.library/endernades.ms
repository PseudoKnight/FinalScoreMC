array_push(@pvp['binds'], @id.'endernades')
bind(player_teleport, array('id': @id.'endernades', 'priority': 'highest'), array('type': 'ENDER_PEARL'), @e, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player())) {
		die();
	}
	cancel();
	consume();
	if(!array_contains(sk_regions_at(@e['to']), @pvp['arena']['region'])) {
		die();
	}
	
	@a = @e['to'];
	play_effect(@a, 'EXPLOSION_LARGE');
	play_sound(@a, associative_array('sound': 'EXPLODE', 'volume': 3));
	foreach(@p in players_in_radius(@a, 7)) {
		if(pmode(@p) == 'SPECTATOR') {
			continue();
		}
		# a delayed velocity works more consistently with grounded entities
		set_timeout(50, closure(){
			@b = _relative(ploc(@p), 'up', 2);
			@dist = sqrt(((@b['x'] - @a['x']) ** 2) + ((@b['y'] - @a['y']) ** 2) + ((@b['z'] - @a['z']) ** 2));
			if(@p == player() && @a['y'] < @b['y']) {
				damage_entity(puuid(@p), 1, puuid());
			} else {
				damage_entity(puuid(@p), 8 / max(1, @dist - 1), puuid());
			}
			try {
				set_pvelocity(@p,
					min(2.2, (@b['x'] - @a['x']) / (@dist ** 2)),
					min(2.2, (@b['y'] - @a['y']) / (@dist ** 2)),
					min(2.2, (@b['z'] - @a['z']) / (@dist ** 2))
				);
			} catch(PlayerOfflineException @ex) {
				// blew completely off server
			}
		});
	}
}

array_push(@pvp['binds'], @id.'endernadesreload')
bind(player_interact, array('id': @id.'endernadesreload', 'priority': 'highest'), array('item': 368, 'button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @e['item']) {
		die();
	}
	cancel()
	shoot_projectile(player(), 'ENDER_PEARL')
	play_sound(ploc(), array('sound': 'SHOOT_ARROW', 'pitch': 0.5))
	_weapon_cooldown(player(), 2500, 'MAGMA_CREAM', closure(){
		play_sound(ploc(), array('sound': 'IRONGOLEM_THROW'));
	});
}

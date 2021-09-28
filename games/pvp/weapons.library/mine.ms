@pvp['binds'][] = bind('item_drop', null, array(itemname: 'HEAVY_WEIGHTED_PRESSURE_PLATE'), @event, @pvp) {
	if(array_index_exists(@pvp['players'], player())) {
		@item = @event['item'];
		@item['meta']['display'] = player();
		modify_event('item', @item);
	}
}

@pvp['binds'][] = bind('item_spawn', null, array(itemname: 'HEAVY_WEIGHTED_PRESSURE_PLATE'), @event, @region = @pvp['arena']['region']) {
	if(!array_contains(sk_regions_at(@event['location']), @region)) {
		die();
	}
	set_timeout(2000, closure(){
		try(
			set_entity_age(@event['id'], 3600); # 2 minutes until despawn
			@loc = location_shift(entity_loc(@event['id']), 'up', 0.5);
			play_sound(@loc, array(sound: 'ITEM_FLINTANDSTEEL_USE', pitch: 0.6));
			spawn_particle(@loc, array(particle: 'SMOKE_LARGE', speed: 0.01));
		);
	});
}

@pvp['binds'][] = bind('item_pickup', null, array(itemname: 'HEAVY_WEIGHTED_PRESSURE_PLATE'), @event, @pvp) {
	if(!array_index_exists(@pvp['players'], player())) {
		die();
	}

	@damager = @event['item']['meta']['display'];
	if(@damager == player()) {
		@item = @event['item'];
		@item['meta']['display'] = 'MINE';
		modify_event('item', @item);
	} else {
		if(array_index_exists(@pvp, 'team')) {
			// check for teammates
			@team = @pvp['players'][player()]['team'];
			if(array_contains(@pvp['team'][@team]['players'], @damager)) {
				cancel();
				die();
			}
		}
		@power = @event['item']['qty'] * 7;
		modify_event('item', null);
		@loc = location_shift(ploc(), 'up');
		play_sound(@loc, array(sound: 'BLOCK_NOTE_BLOCK_BASS', pitch: 2));
		set_timeout(50, closure(){
			play_sound(@loc, array(sound: 'BLOCK_NOTE_BLOCK_BASS', pitch: 2));
			set_timeout(50, closure(){
				play_sound(@loc, array(sound: 'ENTITY_GENERIC_EXPLODE', pitch: 1.6));
				spawn_particle(@loc, array(particle: 'EXPLOSION_LARGE', count: 2));
				if(array_index_exists(@pvp['players'], @damager)
				&& sk_region_check_flag(ploc(@damager), 'PVP', @damager)) {
					try(damage_entity(puuid(), @power, puuid(@damager)));
				} else {
					damage_entity(puuid(), @power);
					_stats_damage(@damager, player(), @power, @pvp);
				}
			});
		});
	}
}

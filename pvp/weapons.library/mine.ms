array_push(@pvp['binds'], @id.'minedrop');
bind(item_drop, array('id': @id.'minedrop'), array('item': 148), @event, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()), die());

	@item = @event['item'];
	@item['meta']['display'] = player();
	modify_event('item', @item);
}

array_push(@pvp['binds'], @id.'minespawn');
bind(item_spawn, array('id': @id.'minespawn'), array('item': 148), @event, @region = @pvp['arena']['region']) {
	if(!array_contains(sk_regions_at(@event['location']), @region)) {
		die();
	}
	set_timeout(2000, closure(){
		try(
			set_entity_age(@event['id'], 3600); # 2 minutes until despawn
			@loc = _relative(entity_loc(@event['id']), 'up', 0.5);
			play_sound(@loc, array('sound': 'FIRE_IGNITE', 'pitch': 0.6));
			play_effect(@loc, 'LARGE_SMOKE', array('speed': 0.01))
		);
	});
}

array_push(@pvp['binds'], @id.'minepickup');
bind(item_pickup, array('id': @id.'minepickup'), array('item': 148), @event, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()), die());

	if(@event['item']['meta']['display'] == player()) {
		@item = @event['item'];
		@item['meta']['display'] = 'MINE';
		modify_event('item', @item);
	} else {
		@power = @event['item']['qty'] * 8;
		modify_event('item', null);
		@loc = _relative(ploc(), 'up');
		play_sound(@loc, array('sound': 'NOTE_BASS', 'pitch': 2));
		set_timeout(50, closure(){
			play_sound(@loc, array('sound': 'NOTE_BASS', 'pitch': 2));
			set_timeout(50, closure(){
				play_sound(@loc, array('sound': 'EXPLODE', 'pitch': 1.6));
				play_effect(@loc, 'EXPLOSION_LARGE', array('particleCount': 2, 'radius': 64));
				@damager = @event['item']['meta']['display'];
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

array_push(@pvp['binds'], @id.'minedrop');
bind(item_drop, array('id': @id.'minedrop'), array('item': 148), @event, @id = @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()), die());
	
	@item = @event['item'];
	@item['meta']['display'] = player();
	modify_event('item', @item);
}

array_push(@pvp['binds'], @id.'minepickup');
bind(item_pickup, array('id': @id.'minepickup'), array('item': 148), @event, @id = @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()), die());
	
	if(@event['item']['meta']['display'] == player()) {
		@item = @event['item'];
		@item['meta']['display'] = 'MINE';
		modify_event('item', @item);
	} else {
		@power = @event['qty'] * 8;
		modify_event('item', null);
		@loc = _relative(ploc(), 'up');
		play_sound(@loc, array('sound': 'NOTE_PIANO', 'pitch': 2));
		set_timeout(50, closure(){
			play_sound(@loc, array('sound': 'NOTE_PIANO', 'pitch': 2));
			set_timeout(50, closure(){
				play_sound(@loc, array('sound': 'EXPLODE', 'pitch': 1.6));
				play_effect(@loc, 'EXPLOSION_LARGE', array('particleCount': 2, 'radius': 64));
				@damager = @event['item']['meta']['display'];
				if(array_index_exists(@pvp['players'], @damager)
				&& sk_region_check_flag(ploc(@damager), 'PVP', @damager)) {
					damage_entity(puuid(), @power, puuid(@damager));
				} else {
					damage_entity(puuid(), @power);
					_stats_damage(@damager, player(), @power, @pvp);
				}
			});
		});
	}
}
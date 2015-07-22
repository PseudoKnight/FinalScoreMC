array_push(@pvp['binds'], @id.'minedrop');
bind(item_drop, array('id': @id.'minedrop'), array('item': 148), @event, @id = @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()), die());
	
	modify_event('item', array('type': 148, 'qty': 1, 'meta': array('display': player())));
}

array_push(@pvp['binds'], @id.'minepickup');
bind(item_pickup, array('id': @id.'minepickup'), array('item': 148), @event, @id = @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player()), die());
	
	if(@event['item']['meta']['display'] == player()) {
		modify_event('item', array('type': 148, 'qty': 1, 'meta': array('display': 'MINE')));
	} else {
		modify_event('item', null);
		play_sound(ploc(), array('sound': 'NOTE_PIANO', 'pitch': 2));
		set_timeout(50, closure(){
			play_sound(ploc(), array('sound': 'NOTE_PIANO', 'pitch': 2));
			set_timeout(50, closure(){
				play_sound(ploc(), array('sound': 'IRONGOLEM_DEATH'));
				play_sound(ploc(), array('sound': 'EXPLODE', 'pitch': 2));
				play_effect(ploc(), 'EXPLOSION_LARGE', array('particleCount': 2, 'radius': 64));
				damage_entity(puuid(), 7, puuid(@event['item']['meta']['display']));
			});
		});
	}
}
bind('player_interact_entity', null, array('clicked': 'BAT'), @event) {
	if(sk_can_build(entity_loc(@event['id']))) {
		set_entity_rider(puuid(), @event['id']);
		bind('player_toggle_sneak', null, array('player': player()), @event) {
			set_entity_rider(puuid(), null);
			unbind();
		}
	}
}

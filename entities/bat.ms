bind('player_interact_entity', null, array('clicked': 'BAT'), @event) {
	if(sk_can_build(entity_loc(@event['id'])) && !get_entity_vehicle(@event['id'])) {
		set_entity_rider(puuid(), @event['id']);
		set_peffect(player(), 'LEVITATION', 0, 20, true);
		@bind = bind('player_toggle_sneak', null, array('player': player()), @event) {
			set_entity_rider(puuid(), null);
			unbind();
			play_sound(ploc(), array('sound': 'ENTITY_BAT_TAKEOFF', 'volume': 0.5));
			set_peffect(player(), 'LEVITATION', 0, 0);
		}
		set_timeout(20000, closure(){
			unbind(@bind);
			if(get_entity_rider(puuid()) == @event['id']) {
				set_entity_rider(puuid(), null);
				play_sound(ploc(), array('sound': 'ENTITY_BAT_TAKEOFF', 'volume': 0.5));
				set_peffect(player(), 'LEVITATION', 0, 0);
			}
		});
	}
}

/*
	Survival PVP
	Prevent damage by default, but still indicate damage
	TODO: track damage so that people can play-fight better
*/
#export('battle', associative_array());
bind(entity_damage_player, null, null, @event) {
	if(!is_array(@event['data']) # is not dispenser
	&& ponline(@event['data']) # is player
	&& @event['data'] != @event['player'] # is not self-inflicted
	&& _is_survival_world(@event['location']['world'])) {
		@vehicle = get_entity_vehicle(puuid(@event['data']));
		@weapon = pinfo(@event['data'], 6);
		if(@vehicle && @weapon == '280:0') { # stick is lance
			modify_event('amount', 0);
			set_entity_rider(@vehicle, null);
		} else {
			cancel();
		}
	}
	/*
		@damaged = @event['player'];
		@damager = @event['data'];
		@battle = import('battle');
		if(!array_index_exists(@battle, @damager)
		|| @battle[@damager]['lastdamaged'] != @damaged) {
			@battle[@damager] = array(
				'lastdamaged': @damaged,
				'lasttime': time(),
				'totaldamage': @event['amount'],
				
			);
		} else if(@battle[@damager]['lasttime'] + 500 < time()) {
			@battle[@damager]['totaldamage'] += @event['amount'];
			@battle[@damager]['lasttime'] = time();
		} else {
			die();
		}
		action_msg(@damager, color('green').'+'.@event['amount'].'  ('.@battle[@damager]['totaldamage'].')');
		if(@event['damager'] === 'ARROW') {
			play_sound(ploc(@damager), array('sound': 'SUCCESSFUL_HIT', 'pitch': 0.5), @damager);
		}
		action_msg(@damaged, color('red').'+'.@event['amount'].'  ('.@battle[@damager]['totaldamage'].')');
		play_sound(ploc(@damaged), array('sound': 'HURT_FLESH'));
		play_entity_effect(puuid(@damaged), 'HURT');
	}
	*/
}
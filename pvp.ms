/*
	Survival PVP
*/
bind(entity_damage_player, null, null, @event) {
	if(!is_array(@event['data']) # is not dispenser
	&& ponline(@event['data']) # is player
	&& @event['data'] != @event['player'] # is not self-inflicted
	&& _is_survival_world(@event['location']['world'])) {
		@vehicle = get_entity_vehicle(puuid(@event['player']));
		@weapon = pinfo(@event['data'], 6);
		if(@vehicle && @weapon == '280:0') { # stick is lance
			modify_event('amount', 0);
			set_entity_rider(@vehicle, null);
		} else {
			cancel();
		}
	}
}

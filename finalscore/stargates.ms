if(extension_exists('CHStargate')) {
	proc _uuid_match(@p1, @p2) {
		return(get_value('players', to_lower(@p1)) == get_value('players', to_lower(@p2)));
	}

	bind(stargate_access, null, array('deny': true), @event) {
		if(_uuid_match(@event['player'], @event['owner'])) {
			modify_event('owner', @event['player']);
			modify_event('deny', false);
		}
	}
	
	bind(stargate_destroy, null, array('deny': true), @event) {
		if(_uuid_match(@event['player'], @event['owner'])) {
			modify_event('owner', @event['player']);
			modify_event('deny', false);
		}
	}
}
proc _bind(@pvp) {
	@pvp['blockcheck'] = false;

	@pvp['binds'][] = bind('block_break', null, null, @event, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			@pvp['blockcheck'] = true;
		}
	}

	@pvp['binds'][] = bind('entity_explode', null, array(type: 'PRIMED_TNT'), @event, @pvp) {
		if(!_is_survival_world(@event['location']['world'])
		&& sk_region_contains(@pvp['arena']['region'], @event['location'])) {
			@pvp['blockcheck'] = true;
		}
	}
}
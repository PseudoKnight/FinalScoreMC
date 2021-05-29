proc _bind(@pvp) {
	@pvp['blockcheck'] = false;

	@pvp['binds'][] = bind('block_break', null, null, @event, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			@pvp['blockcheck'] = true;
		}
	}

	@pvp['binds'][] = bind('entity_explode', null, array(type: 'PRIMED_TNT'), @event, @pvp) {
		if(!_is_survival_world(@event['location']['world'])
		&& array_contains(sk_regions_at(@event['location']), @pvp['arena']['region'])) {
			@pvp['blockcheck'] = true;
		}
	}
}
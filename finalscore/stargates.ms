if(extension_exists('CHStargate')) {
	bind(stargate_access, null, null, @event) {
		if(@event['player'] != @event['owner']) {
			@pdata = _pdata(@event['player']);
			if(array_index_exists(@pdata, 'names') && array_contains(@pdata['names'], @event['owner'])) {
				modify_event('owner', @event['player']);
			}
		}
	}

	bind(stargate_destroy, null, array('deny': true), @event) {
		if(@event['player'] != @event['owner']) {
			@pdata = _pdata(@event['player']);
			if(array_index_exists(@pdata, 'names') && array_contains(@pdata['names'], @event['owner'])) {
				modify_event('owner', @event['player']);
				modify_event('deny', false);
			}
		}
	}
}

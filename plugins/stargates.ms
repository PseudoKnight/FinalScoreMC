if(extension_exists('CHStargate')) {
	bind('stargate_access', null, null, @event) {
		if(@event['player'] != @event['owner']) {
			@pdata = _pdata(@event['player']);
			if(array_index_exists(@pdata, 'names') && array_contains(@pdata['names'], @event['owner'])) {
				sg_set_owner(@event['portal'], @event['network'], @event['player']);
			}
		}
	}

	bind('stargate_destroy', null, array('deny': true), @event) {
		if(@event['player'] != @event['owner']) {
			@pdata = _pdata(@event['player']);
			if(array_index_exists(@pdata, 'names') && array_contains(@pdata['names'], @event['owner'])) {
				sg_set_owner(@event['portal'], @event['network'], @event['player']);
				cancel(false);
			} else {
				msg('This Stargate belongs to '.@event['owner']);
			}
		}
	}
	
	bind('stargate_open', null, null, @event) {
		if(array_index_exists(@event, 'player')) {
			@loc = ploc(@event['player']);
			play_named_sound(@loc, array('sound': 'entity.shulker.shoot', 'pitch': 1.3));
			play_named_sound(@loc, array('sound': 'entity.evocation_illager.cast_spell', 'pitch': 0.6));
		}
	}
}

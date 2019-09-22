if(extension_exists('CHStargate')) {
	bind('stargate_access', null, null, @event) {
		@ownerName = sg_get_owner_name(@event['portal'], @event['network']);
		if(sg_get_owner_uuid(@event['portal'], @event['network']) != null && @event['player'] != @ownerName) {
			@pdata = _pdata(@event['player']);
			if(array_index_exists(@pdata, 'names') && array_contains(@pdata['names'], @ownerName)) {
				sg_set_owner(@event['portal'], @event['network'], puuid(@event['player']));
			}
		}
	}

	bind('stargate_destroy', null, array('deny': true), @event) {
		@ownerName = sg_get_owner_name(@event['portal'], @event['network']);
		if(sg_get_owner_uuid(@event['portal'], @event['network']) != null && @event['player'] != @ownerName) {
			@pdata = _pdata(@event['player']);
			if(array_index_exists(@pdata, 'names') && array_contains(@pdata['names'], @ownerName)) {
				sg_set_owner(@event['portal'], @event['network'], puuid(@event['player']));
				cancel(false);
			} else {
				msg('This Stargate belongs to '.@ownerName);
			}
		}
	}
	
	bind('stargate_open', null, null, @event) {
		if(array_index_exists(@event, 'player')) {
			@loc = ploc(@event['player']);
			play_sound(@loc, array('sound': 'ENTITY_SHULKER_SHOOT', 'pitch': 1.3));
			play_sound(@loc, array('sound': 'ENTITY_EVOKER_CAST_SPELL', 'pitch': 0.6));
		}
	}
}

if(extension_exists('CHStargate')) {
	bind('stargate_access', null, null, @event) {
		@ownerName = sg_get_owner_name(@event['portal'], @event['network']);
		if(sg_get_owner_uuid(@event['portal'], @event['network']) != null && @event['player'] != @ownerName) {
			@pdata = _pdata(@event['player']);
			if(array_index_exists(@pdata, 'names') && array_contains(@pdata['names'], @ownerName)) {
				sg_set_owner(@event['portal'], @event['network'], puuid(@event['player']));
			}
		}
		// Players on bedrock clients cannot enter end gateway blocks, 
		// so change these to water on alwaysOn gates.
		if(extension_exists('chgeyser')) {
			if(geyser_connected() && sg_is_portal_open(@event['portal'], @event['network'])) {
				@portal = sg_get_portal_info(@event['portal'], @event['network']);
				if(@portal['options']['alwaysOn']) {
					foreach(@block in @portal['entrance']) {
						psend_block_change(@block, 'water');
					}
				}
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

			// Players on bedrock clients cannot enter end gateway blocks, 
			// so change these to water a tick after it opens.
			if(extension_exists('chgeyser')) {
				if(geyser_connected()) {
					set_timeout(50, closure(){
						foreach(@block in sg_get_portal_info(@event['portal'], @event['network'])['entrance']) {
							psend_block_change(@block, 'water');
						}
					});
				}
			}
		}
	}

	if(extension_exists('chgeyser')) {
		bind('stargate_portal', null, null, @event) {
			// Players on bedrock clients cannot enter end gateway blocks, 
			// so change alwaysOn gates to water for other nearby bedrock players.
			foreach(@player in players_in_radius(ploc(@event['player']), 64)) {
				if(@player != @event['player'] && geyser_connected(@player)) {
					@portal = sg_get_portal_info(@event['portal'], @event['network']);
					if(@portal['options']['alwaysOn']) {
						foreach(@block in @portal['entrance']) {
							psend_block_change(@player, @block, 'water');
						}
					}
				}
			}
		}
	}
}

proc _bind(@pvp) {
	@pvp['binds'][] = bind('block_break', null, null, @e, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			cancel();
		}
	}

	@pvp['binds'][] = bind('block_place', null, null, @e, @pvp) {
		if(array_index_exists(@pvp['players'], player())) {
			cancel();
		}
	}
	
	// prevent all item frame and painting destruction
	@pvp['binds'][] = bind('hanging_break', null, array(world: @pvp['arena']['lobby'][3]), @event, @pvp) {
		cancel();
	}

	@pvp['binds'][] = bind('player_interact_entity', array(priority: 'LOWEST'), array(clicked: '/(GLOW_)?ITEM_FRAME/'), @event, @pvp) {
		if(!is_cancelled()
		&& array_contains(sk_regions_at(entity_loc(@event['id'])), @pvp['arena']['region'])) {
			action_msg('Item frames are disabled');
			cancel();
		}
	}

	@pvp['binds'][] = bind('entity_damage', array(priority: 'LOWEST'), array(type: '/(GLOW_)?ITEM_FRAME/'), @event, @pvp) {
		if(!is_cancelled()
		&& array_contains(sk_regions_at(@event['location']), @pvp['arena']['region'])) {
			cancel();
		}
	}
}
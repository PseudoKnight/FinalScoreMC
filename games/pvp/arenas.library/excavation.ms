proc _arena_bind_events(@id) {
	@pvp = import('pvp'.@id);
	@pvp['binds'][] = bind('vehicle_collide', null, array(collisiontype: 'ENTITY', type: 'MINECART'), @event) {
		if(array_contains(sk_regions_at(entity_loc(@event['id'])), 'excavation')) {
			cancel();
		}
	}
}
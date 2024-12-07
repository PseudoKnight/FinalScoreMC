proc _arena_bind_events(@id) {
	@pvp = import('pvp'.@id);
	@pvp['binds'][] = bind('vehicle_collide', null, array(collisiontype: 'ENTITY', type: 'MINECART'), @event) {
		if(sk_region_contains('excavation', entity_loc(@event['id']))) {
			cancel();
		}
	}
}
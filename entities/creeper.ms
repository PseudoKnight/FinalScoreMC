# Block creeper damage on the surface.
bind('entity_explode', null, array('type': 'CREEPER'), @event, @worlds = array('world', 'world3', 'world4', 'omega', 'psi')) {
	if(array_contains(@worlds, @event['location']['world'])) {
		cancel();
		spawn_particle(@event['location'], 'EXPLOSION_HUGE');
	}
}
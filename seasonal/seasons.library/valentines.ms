bind('entity_damage', null, null, @event) {
	if(is_entity_living(@event['id'])) {
		spawn_particle(location_shift(@event['location'], 'up', 2), array(
			particle: 'HEART', 
			count: min(20, ceil(@event['finalamount'])), 
			xoffset: 0.5, 
			zoffset: 0.5,
			yoffset: 0.5,
		));
	}
}

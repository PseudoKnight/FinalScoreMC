// Sets ender crystal beams to target nearby newly placed dragon eggs
bind('block_place', array('priority': 'LOW'), array(block: 'DRAGON_EGG'), @event) {
	@loc = @event['location'];
	@loc['x'] += 0.5;
	@loc['y'] -= 1.5;
	@loc['z'] += 0.5;
	foreach(@enderCrystal in entities_in_radius(@event['location'], 32, 'ENDER_CRYSTAL')) {
		@target = entity_spec(@enderCrystal)['beamtarget'];
		if(!@target || get_block(location_shift(@target, 'up', 2)) !== 'DRAGON_EGG') {
			set_entity_spec(@enderCrystal, array(beamtarget: @loc));
		}
	}
}
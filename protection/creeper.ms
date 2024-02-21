/*
	Prevent creeper block damage in main overworlds.
	Recreates explosion effects, which now don't play when event is canceled.
	Entity damage from creepers still happens. That's handled separately with entity_damage event.
 */
bind('entity_explode', null, array(type: 'CREEPER'), @event, @worlds = array('world', 'world3', 'world4', 'omega', 'psi')) {
	if(array_contains(@worlds, @event['location']['world'])) {
		cancel();
		spawn_particle(@event['location'], 'EXPLOSION_HUGE');
		play_sound(@event['location'], array(sound: 'ENTITY_GENERIC_EXPLODE', pitch: 0.6));
		foreach(@block in @event['blocks']) {
			spawn_particle(_center(@block), array(
				particle: 'BLOCK_CRACK',
				block: get_block(@block),
				count: 5,
				xoffset: 0.5,
				yoffset: 0.5,
				zoffset: 0.5
			));
		}
	}
}
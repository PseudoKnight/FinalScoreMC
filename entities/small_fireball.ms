bind('projectile_hit', null, array(type: 'SMALL_FIREBALL'), @event) {
	spawn_particle(@event['location'], 
		array(particle: 'LAVA', count: 7, speed: 0.05, force: true),
		players_in_radius(@event['location'], 144));
	play_sound(@event['location'], array(sound: 'BLOCK_NOTE_BLOCK_BASEDRUM', pitch: 2, volume: 5));
	play_sound(@event['location'], array(sound: 'BLOCK_FIRE_EXTINGUISH', pitch: 2, volume: 5));
}
bind('player_interact', null, array(itemname: 'GUNPOWDER', button: 'right'), @event) {
	if(@event['action'] == 'right_click_block') {
		@trace = ray_trace(4);
		spawn_particle(@trace['location'], array(particle: 'ELECTRIC_SPARK'));
		spawn_particle(@trace['location'], array(particle: 'SMOKE_NORMAL'));
		play_sound(@trace['location'], array(sound: 'ENTITY_CREEPER_HURT', pitch: 2.0, volume: 0.2));
	}
}
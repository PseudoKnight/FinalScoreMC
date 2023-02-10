proc _class_load(@player, @pvp) {
	bind('vehicle_leave', array(id: @player.'dismount'), array(vehicletype: 'HORSE'), @event, @player) {
		if(@player == @event['player']) {
			@horseHealth = 100.0;
			try(@horseHealth = get_entity_health(@event['vehicle']))
			set_timeout(1, closure(){
				try {
					entity_remove(@event['vehicle']);
					set_pcooldown(@player, 'SADDLE', 2500 / 50);
					set_pinv(@player, 1, array(name: 'SADDLE', meta: array(display: 'Steed', lore: array(@horseHealth))));
				} catch(BadEntityException @e) {}
			});
		}
	}
	bind('player_interact', array(id: @player.'mount', priority: 'HIGHEST'), array(player: @player, itemname: 'SADDLE', button: 'right'), @event){
		cancel();
		consume();
		if(!entity_grounded(puuid()) || pcooldown('SADDLE')) {
			die();
		}
		@item = pinv(player(), null);
		set_pinv(player(), null, null);
		@loc = entity_loc(puuid());
		_spawn_entity('steed', @loc, null, closure(@horse) {
			set_entity_health(@horse, @item['meta']['lore'][0]);
			add_scoreboard_tag(@horse, 'nodrops');
		});
		@effectLoc = location_shift(@loc, 'up');
		play_sound(@effectLoc, array(sound: 'ENTITY_HORSE_AMBIENT'));
		spawn_particle(@effectLoc, array(particle: 'CLOUD', count: 10, xoffset: 0.4, zoffset: 0.4, yoffset: 0.4));
	}
}

proc _class_powerup(@player) {
	@vehicle = pvehicle(@player);
	if(@vehicle) {
		set_entity_health(@vehicle, 100);
	} else {
		set_pinv(@player, 1, array(name: 'SADDLE', meta: array(
			display: 'Steed',
			lore: array(100),
		)));
	}
}


proc _class_unload(@player, @pvp) {
	unbind(@player.'dismount');
	unbind(@player.'mount');
}

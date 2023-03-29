proc _class_load(@player, @pvp) {
	bind('player_interact', array(id: @player.'grenade'), array(player: @player, itemname: 'STONE_SHOVEL', button: 'right'), @e, @pvp) {
		if(!ptake_item(player(), array(name: 'STONE_SHOVEL'))) {
			die();
		}
		@loc = location_shift(ploc(), 'up', 2);
		@armorStand = spawn_entity('ARMOR_STAND', 1, @loc)[0];
		add_scoreboard_tag(@armorStand, 'remove');
		set_entity_spec(@armorStand, array(visible: false, small: true, arms: true));
		set_mob_equipment(@armorStand, array(WEAPON: array(name: 'STONE_SHOVEL')));
		set_entity_spec(@armorStand, array(poses: array(poseArmRight: array(x: -0.28, y: -1.656, z: 0.338))));
		@loc['yaw'] = @loc['yaw'] + 90;
		@loc['pitch'] = 0 - @loc['pitch'];
		@x = 1.40 * cos(to_radians(@loc['yaw'])) * cos(to_radians(@loc['pitch']));
		@y = max((1.40 * sin(to_radians(@loc['pitch']))) + 0.2, 0.2);
		@z = 1.40 * sin(to_radians(@loc['yaw'])) * cos(to_radians(@loc['pitch']));
		set_entity_velocity(@armorStand, array(@x, @y, @z));
		play_sound(@loc, array(sound: 'ENTITY_IRON_GOLEM_ATTACK', volume: 2));
		@timer = array(12);
		set_interval(250, closure(){
			try {
				if(--@timer[0] <= 0) {
					clear_task();
					explosion(entity_loc(@armorStand), 3, true, false, puuid());
					entity_remove(@armorStand);
				} else {
					spawn_particle(location_shift(entity_loc(@armorStand), 'up', 0.6), 'SMOKE_LARGE');
				}
			} catch(BadEntityException @ex) {
				// grenade no longer exists
				clear_task();
			}
		});
	}
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'grenade');
}

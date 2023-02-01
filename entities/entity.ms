/*
	100% drop rate for all explosions
 */
bind('entity_explode', array(priority: 'HIGH'), null, @event) {
	// While normally you would not have to exempt ender dragons,
	// if they get to an overworld, the number of drops will tank performance.
	if(@event['type'] != 'ENDER_DRAGON') {
		modify_event('yield', 1.0);
	}
}

/*
	Limit breeding in high entity areas
 */
bind('creature_spawn', null, array(reason: 'BREEDING'), @event) {
	if(array_size(entities_in_radius(@event['location'], 48, @event['type'])) > 100
	&& array_size(entities_in_radius(@event['location'], 32, @event['type'])) > 300) {
		cancel();
		spawn_particle(@event['location'], 'SMOKE_NORMAL');
		_tellraw(players_in_radius(@event['location'], 16), array(
			array('plain', color('gold').'Breeding failed due to overcrowding. '),
			array('hover', '&e[!]', 'Client performance may suffer. Recommend reducing entities in the area.')));
	}
}

/*
	Limit dispensing entities
 */
bind('creature_spawn', null, array(reason: 'DISPENSE_EGG'), @event) {
	if(!_is_survival_world(@event['location']['world'])) {
		// 48 radius is the configured entity-tracking-range for animals in spigot.yml
		// 300 is a rough estimate for when performance noticeably suffers on many clients.
		// This will vary depending on performance targets, typical client hardware and mods,
		// as well as the Minecraft version.
		if(array_size(entities_in_radius(@event['location'], 48, @event['type'])) > 100) {
			cancel();
			spawn_particle(@event['location'], 'SMOKE_NORMAL');
		}
	}
}

/*
	Prevent egg-spawned mobs from despawning
 */
bind('creature_spawn', null, array(reason: 'SPAWNER_EGG'), @event) {
	set_entity_persistence(@event['id'], true);
}

/*
	No-AI mob posing
 */
bind('player_interact_at_entity', null, array(hand: 'main_hand'), @event) {
	if(pmode() == 'CREATIVE'
	&& psneaking()
	&& is_entity_living(@event['id'])
	&& !get_entity_ai(@event['id'])
	&& entity_type(@event['id']) != 'ARMOR_STAND'
	&& sk_can_build(entity_loc(@event['id']))) {

		@dir = pfacing();
		@eloc = entity_loc(@event['id']);
		@newloc = @eloc[];

		export(player().'posing', true);
		cancel();

		// This is roughly the same as the armor stand rotation and moving.
		if(@event['position']['y'] < 0.5) {
			title('', color(6).'Rotating entity.', 0, 40, 10);

			@taskid = set_interval(50, closure(){
				if(!psneaking() || !entity_exists(@event['id'])) {
					clear_task();
					export(player().'posing', null);
					return();
				}

				@newdir = pfacing();

				@yawdiff = @newdir[0] - @dir[0];
				if(@yawdiff > 180) {
					@yawdiff -= 360;
				} else if(@yawdiff < -180) {
					@yawdiff += 360;
				}

				@dyaw = @yawdiff * 2.5;
				@newloc['yaw'] = @eloc['yaw'] - @dyaw;
				set_entity_loc(@event['id'], @newloc);
			});

		} else {
			title('', color(6).'Adjusting entity position.', 0, 40, 10);

			@eloc = entity_loc(@event['id']);
			@originalYaw = @eloc['yaw'];
			@dist = distance(@eloc, location_shift(ploc(), 'up'));

			set_interval(50, closure(){
				if(!ponline(player()) || !psneaking() || !entity_exists(@event['id'])) {
					clear_task();
					export(player().'posing', null);
					return();
				}

				@eloc = location_shift(ploc(), 'up', 1.3);
				@yaw = to_radians(@eloc['yaw'] + 90);
				@pitch = to_radians(0 - @eloc['pitch']);
				@eloc['x'] += @dist * cos(@yaw) * cos(@pitch);
				@eloc['y'] += @dist * sin(@pitch);
				@eloc['z'] += @dist * sin(@yaw) * cos(@pitch);
				@eloc['yaw'] = @originalYaw;
				set_entity_loc(@event['id'], @eloc);
			});
		}
	}
}
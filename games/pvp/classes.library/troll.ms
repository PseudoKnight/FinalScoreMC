proc _class_load(@player, @pvp) {
	proc _swing_club(@player, @victim) {
		if(pattack_cooldown(@player) == 1.0) {
			@raytrace = ray_trace(@player, 2);
			spawn_particle(location_shift(@raytrace['location'], 'down'), array(particle: 'SWEEP_ATTACK', speed: 32.0, count: 0, xoffset: 1));
			play_named_sound(@raytrace['location'], array(sound: 'entity.player.attack.sweep', pitch: 0.5));
			play_named_sound(@raytrace['location'], array(sound: 'entity.ravager.attack', pitch: 0.5));
			foreach(@p in players_in_radius(@raytrace['location'], 3)) {
				if(@p == @player || pmode(@p) == 'SPECTATOR' || puuid(@p) == @victim) {
					continue();
				}
				damage_entity(puuid(@p), 6, puuid(@player));
			}
		}
	}

	bind('player_interact', array(id: @player.'club'), array(player: @player, itemname: 'POINTED_DRIPSTONE', button: 'left'), @event) {
		_swing_club(@event['player']);
	}

	bind('entity_damage', array(id: @player.'clubdamage'), array(cause: 'ENTITY_ATTACK'), @event, @player) {
		if(@event['damager'] == @player && @event['amount'] >= 8.0) {
			_swing_club(@player, @event['id']);
		}
	}

	bind('player_toggle_sneak', array(id: @player.'roar'), array(player: @player, sneaking: true), @event) {
		if(pexp() == 99) {
			play_named_sound(ploc(), array(sound: 'entity.ravager.roar', pitch: 0.6));
			set_pexp(0);
			set_interval(50, closure(){
				try {
					@xp = pexp();
					@xp = min(99, @xp + 1);
					set_pexp(@xp);
					if(@xp == 15) {
						@loc = location_shift(ploc(), 'up');
						if(!psneaking()) {
							clear_task();
							set_pexp(99);
							die();
						}
						@yaw = to_radians(@loc['yaw'] + 45);
						for(@radius = 1, @radius <= 16, @radius++) {
							queue_push(closure() {
								for(@angle = @yaw, @angle < @yaw + 1.57, @angle += rand() / 3) {
									@point = array(
										@radius * cos(@angle) + @loc['x'],
										@loc['y'],
										@radius * sin(@angle) + @loc['z'],
										@loc['world'],
									);
									if(get_block(@point) == 'AIR') {
										@block = get_block(location_shift(@point, 'down'));
										if(@block != 'AIR') {
											spawn_particle(@point, array(particle: 'BLOCK_CRACK', block: @block, count: 5));
										}
									}
									foreach(@player in players_in_radius(@point, 2)) {
										if(@player == player() && pmode(@player) != 'SPECTATOR') {
											continue();
										}
										damage_entity(puuid(@player), 1, puuid());
										set_peffect(@player, 'SLOWNESS', 2, 10, true);
										set_peffect(@player, 'NAUSEA', 0, 2, true, false);
									}
								}
							}, player().'roar');
						}
					} else if(@xp == 99) {
						clear_task();
					}
				} catch(Exception @ex) {
					clear_task();
				}
			});
		}
	}
	
	bind('entity_damage', array(id: @player.'groundpound'), array(id: puuid(@player), cause: 'FALL'), @event, @player, @pvp) {
		@damage = @event['amount'];
		@target = location_shift(entity_loc(@event['id']), 'up', 0.2);
		@world = @target['world'];

		modify_event('amount', @damage * 0.2);
		foreach(@p in players_in_radius(@target, 6)) {
			if(@p != @player && array_index_exists(@pvp['players'], @p) && pmode(@p) != 'SPECTATOR') {
				damage_entity(puuid(@p), @damage, @event['id']);
			}
		}
		play_named_sound(@target, array(sound: 'entity.ravager.step', pitch: 0.5));
		play_named_sound(@target, array(sound: 'entity.ravager.hurt', pitch: 0.5));

		spawn_particle(@target, array(particle: 'CAMPFIRE_COSY_SMOKE', count: 20, xoffset: 4, zoffset: 4));

		@radius = 6;
		for(@angle = 0, @angle < 6.28, @angle += rand() / 3) {
			@point = array(
				@radius * cos(@angle) + @target['x'],
				@target['y'],
				@radius * sin(@angle) + @target['z'],
				@world,
			);
			if(get_block(@point) == 'AIR') {
				@block = get_block(location_shift(@point, 'down'));
				if(@block != 'AIR') {
					spawn_particle(@point, array(particle: 'CAMPFIRE_COSY_SMOKE'));
				}
			}
		}
	}

	bind('player_interact_entity', array(id: @player.'throw'), array(hand: 'main_hand', clicked: 'PLAYER'), @event, @player) {
		if(player() == @player && pcooldown('POINTED_DRIPSTONE') == 0) {
			play_named_sound(ploc(), array(sound: 'entity.ravager.step', pitch: 0.5));
			set_pcooldown('POINTED_DRIPSTONE', 50);
			set_entity_rider(puuid(), @event['id']);
			@timer = array(10);
			set_interval(50, closure(){
				@timer[0]--;
				try {
					if(@timer[0] <= 0) {
						clear_task();
						@loc = ploc();
						@vector = get_vector(@loc, 1.6);
						@vector['y'] = max(@vector['y'] + 0.2, 0.2);
						play_named_sound(@loc, array(sound: 'entity.ravager.stunned'));
						set_entity_velocity(@event['id'], @vector);
					} else if(@timer[0] == 1) {
						if(get_entity_rider(puuid()) == @event['id']) {
							set_entity_rider(puuid(), null);
						} else {
							clear_task();
						}
					}
				} catch(Exception @ex) {
					clear_task();
				}
			});
		}
	}

	add_entity_attribute_modifier(puuid(@player), array(
		attribute: 'GENERIC_KNOCKBACK_RESISTANCE',
		operation: 'ADD_NUMBER',
		amount: 1.0,
		id: 'commandhelper:troll_knockback'));
	add_entity_attribute_modifier(puuid(@player), array(
		attribute: 'GENERIC_ATTACK_DAMAGE',
		operation: 'ADD_NUMBER',
		amount: 7.0,
		id: 'commandhelper:troll_damage'));
	add_entity_attribute_modifier(puuid(@player), array(
		attribute: 'GENERIC_MAX_HEALTH',
		operation: 'ADD_NUMBER',
		amount: 10.0,
		id: 'commandhelper:troll_health'));
	set_phealth(@player, 30);
}

proc _class_powerup(@player) {
	set_pexp(@player, 99);
	set_phunger(@player, 2);
	set_phealth(@player, min(get_max_health(puuid(@player)), phealth(@player) + 1));
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'club');
	unbind(@player.'roar');
	unbind(@player.'groundpound');
	unbind(@player.'throw');
	unbind(@player.'clubdamage');
	remove_entity_attribute_modifier(puuid(@player), 'GENERIC_KNOCKBACK_RESISTANCE', 'commandhelper:troll_knockback');
	remove_entity_attribute_modifier(puuid(@player), 'GENERIC_ATTACK_DAMAGE', 'commandhelper:troll_damage');
	remove_entity_attribute_modifier(puuid(@player), 'GENERIC_MAX_HEALTH', 'commandhelper:troll_health');
	set_phunger(@player, 20);
}
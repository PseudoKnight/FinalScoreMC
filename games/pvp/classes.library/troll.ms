proc _class_load(@player, @pvp) {
	proc _swing_club(@player, @victim) {
		if(pcooldown(@player, 'POINTED_DRIPSTONE') == 0) {
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
			set_pcooldown(@player, 'POINTED_DRIPSTONE', 50);
		}
	}

	bind('player_interact', array(id: @player.'club'), array(player: @player, itemname: 'POINTED_DRIPSTONE', button: 'left'), @event) {
		_swing_club(@event['player']);
	}

	bind('entity_damage', array(id: @player.'clubdamage'), array(cause: 'ENTITY_ATTACK'), @event, @player) {
		if(@event['damager'] == @player) {
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
						for(@radius = 1, @radius <= 8, @radius++) {
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
									foreach(@player in players_in_radius(@point, 1.5)) {
										if(@player == player() && pmode(@player) != 'SPECTATOR') {
											continue();
										}
										damage_entity(puuid(@player), 0.5, puuid());
										set_peffect(@player, 'SLOWNESS', 0, 10, true);
										set_peffect(@player, 'NAUSEA', 0, 1, true, false);
									}
								}
							}, player().'roar');
							queue_delay(50, player().'roar');
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
		if(player() == @player) {
			play_named_sound(ploc(), array(sound: 'entity.ravager.step', pitch: 0.5));
			@timer = array(20);
			set_interval(50, closure(){
				@timer[0]--;
				try {
					@loc = ploc();
					if(@timer[0] <= 0) {
						clear_task();
						@vector = get_vector(@loc, 1.6);
						@vector['y'] = max(@vector['y'] + 0.2, 0.2);
						set_entity_velocity(@event['id'], @vector);
						play_named_sound(@loc, array(sound: 'entity.ravager.stunned'));
					} else {
						set_entity_loc(@event['id'], location_shift(@loc, 'up', 3));
					}
				} catch(Exception @ex) {
					clear_task();
				}
			});
		}
	}

	set_entity_attribute_base(puuid(@player), 'GENERIC_KNOCKBACK_RESISTANCE', 1.0);
	set_entity_attribute_base(puuid(@player), 'GENERIC_MAX_HEALTH', 40.0);
	set_entity_attribute_base(puuid(@player), 'GENERIC_ATTACK_DAMAGE', 8.0);
	set_phealth(@player, 40);
}

proc _class_powerup(@player) {
	set_pexp(@player, 99);
	set_phunger(@player, 2);
	set_phealth(@player, max(1, phealth(@player) - 1));
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'club');
	unbind(@player.'roar');
	unbind(@player.'groundpound');
	unbind(@player.'throw');
	set_entity_attribute_base(puuid(@player), 'GENERIC_KNOCKBACK_RESISTANCE', 0.0);
	set_entity_attribute_base(puuid(@player), 'GENERIC_MAX_HEALTH', 20.0);
	set_entity_attribute_base(puuid(@player), 'GENERIC_ATTACK_DAMAGE', 1.0);
	set_phunger(@player, 20);
}
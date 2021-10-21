switch(@action) {
case 'load':
	set_pheld_slot(@player, 0);
	bind('item_held', array(id: @player.'cyborghand'), array(player: @player), @e) {
		cancel();
	}

	bind('player_interact', array(id: @player.'cyborgshoot'), array(player: @player), @event, @pvp) {
		@slot = 0;
		if(@event['button'] == 'left') {
			@slot = -106;
		}
		@item = pinv(player(), @slot);
		if(@item && @item['name'] == 'PLAYER_HEAD' && !pcooldown('PLAYER_HEAD')) {
			set_pcooldown('PLAYER_HEAD', 20);

			@trace = ray_trace(player(), 90, 0.5);
			@target = @trace['location'];
			if(!array_contains(sk_regions_at(@target), @pvp['arena']['region'])) {
				title(player(), '', color('red').'[no_target_found]', 0, 10, 10);
				die();
			}
			if(@trace['entities']) {
				foreach(@entity in @trace['entities']) {
					if(ponline(@entity['uuid']) && pmode(@entity['uuid']) != 'SPECTATOR') {
						@target = @entity['uuid'];
						@targetedSound = array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED', pitch: 2.0, volume: 0.5);
						@targetSound = array(sound: 'BLOCK_NOTE_BLOCK_BIT', pitch: 2.0);
						play_sound(ploc(), @targetSound, player());
						set_timeout(500, closure(play_sound(ploc(), @targetSound, player())));
						play_sound(@trace['location'], @targetSound, player(@target));
						set_timeout(500, closure(play_sound(@trace['location'], @targetedSound, player(@target))));
						title(player(), '', color('green').'[target_locked]', 0, 10, 10);
						break();
					}
				}
			}

			set_pinv(player(), @slot, null);
			@loc = location_shift(ploc(), 'up', 2.25);
			@tempLoc = @loc[];
			if(@event['button'] == 'left') {
				@tempLoc['yaw'] -= 90;
			} else {
				@tempLoc['yaw'] += 90;
			}
			@v = get_vector(@tempLoc, 0.35);
			@loc['x'] += @v['x'];
			@loc['y'] += @v['y'];
			@loc['z'] += @v['z'];

			proc _get_entity_location(@loc) {
				return(location_shift(@loc, 'down', 0.9));
			}

			proc _get_missile_location(@loc) {
				return(location_shift(@loc, 'up', 0.9));
			}

			@box = spawn_entity('ARMOR_STAND', 1, _get_entity_location(@loc), closure(@e) {
				set_mob_equipment(@e, array(HELMET: @item));
				set_entity_spec(@e, array(
					gravity: false,
					visible: false,
					small: true,
				));
			})[0];

			// launch sound
			play_sound(@loc, array(sound: 'ENTITY_PUFFER_FISH_BLOW_OUT', pitch: 0.5), player());

			@returnToSender = closure(){
				if(ponline(player()) && pmode() != 'SPECTATOR' && array_index_exists(@pvp['players'], player())) {
					@item['qty']--;
					@newItem = pinv(player(), @slot);
					if(@newItem && @newItem['name'] == 'PLAYER_HEAD') {
						@item['qty'] += @newItem['qty'];
					}
					set_pinv(player(), @slot, @item);
				}
				play_sound(ploc(), array(sound: 'ENTITY_PUFFER_FISH_BLOW_UP', pitch: 0.5), player());
			}

			@explode = closure(@loc) {
				spawn_particle(@loc, 'EXPLOSION_LARGE');
				play_sound(@loc, array(sound: 'ENTITY_GENERIC_EXPLODE', pitch: 1.3, volume: 4));
				entity_remove(@box);
				foreach(@e in entities_in_radius(@loc, 4)) {
					if(is_entity_living(@e)) {
						damage_entity(@e, 7 - distance(location_shift(entity_loc(@e), 'up'), @loc), puuid());
						if(@e != puuid()) {
							play_sound(ploc(), array(sound: 'ENTITY_ARROW_HIT_PLAYER'), player());
						}
					}
				}
			}

			set_interval(50, closure(){
				try {
					if(is_string(@target) && (!entity_exists(@target) || pmode(player(@target)) == 'SPECTATOR')
					|| !ponline(player())
					|| pmode() == 'SPECTATOR'
					|| !array_index_exists(@pvp['players'], player())) {
						clear_task();
						execute(@returnToSender);
						// Self-detonate missile
						try(execute(_get_missile_location(entity_loc(@box)), @explode));
					} else {
						@loc = _get_missile_location(entity_loc(@box));

						@targetLoc = @target;
						if(!is_array(@targetLoc)) {
							@targetLoc = _get_missile_location(entity_loc(@target));
						}
						@newLoc = @targetLoc[];
						@yaw = get_yaw(@loc, @newLoc);
						@pitch = get_pitch(@loc, @newLoc);

						if(@yaw == 'NaN') {
							clear_task();
							execute(@loc, @explode);
							set_timeout(500, @returnToSender);
							die();
						}

						// clamp turning radius
						@diffYaw = @loc['yaw'] - @yaw;
						if(abs(@diffYaw) > 180) {
							if(@diffYaw < 0) {
								@diffYaw += 360;
							} else {
								@diffYaw -= 360;
							}
						}
						if(@diffYaw < -5) {
							@yaw = @loc['yaw'] + 5;
						} else if(@diffYaw > 5) {
							@yaw = @loc['yaw'] - 5;
						}

						@diffPitch = @loc['pitch'] - @pitch;
						if(@diffPitch < -5) {
							@pitch = min(90, @loc['pitch'] + 5);
						} else if(@diffPitch > 5) {
							@pitch = max(-90, @loc['pitch'] - 5);
						}

						@loc['yaw'] = @yaw;
						@loc['pitch'] = @pitch;
						@v = get_vector(@loc, 0.5);
						@newLoc['x'] = @loc['x'] + @v['x'];
						@newLoc['y'] = @loc['y'] + @v['y'];
						@newLoc['z'] = @loc['z'] + @v['z'];
						@newLoc['yaw'] = @yaw;
						@newLoc['pitch'] = @pitch;

						// needs to be changed to a ray trace
						if(get_block_info(@newLoc, 'solid') || distance(@newLoc, @targetLoc) < 1) {
							clear_task();
							set_entity_loc(@box, _get_entity_location(@newLoc));
							set_timeout(500, @returnToSender);
							execute(@loc, @explode);
						} else {
							set_entity_loc(@box, _get_entity_location(@newLoc));
							set_entity_spec(@box, array(poses: array(poseHead: array(to_radians(@pitch), 0, 0))));
							if(!rand(3)) {
								@back = @loc[];
								@back['x'] += neg(@v['x']) * 2;
								@back['y'] += neg(@v['y']) * 2;
								@back['z'] += neg(@v['z']) * 2;
								spawn_particle(@back, 'CAMPFIRE_COSY_SMOKE');
								play_sound(@loc, array(sound: 'ENTITY_GUARDIAN_ATTACK', pitch: 0.5 + rand() * 1.5));
							}
						}
					}
				} catch(Exception @ex) {
					clear_task();
					set_timeout(500, @returnToSender);
				}
			});
		}
	}

	bind('entity_damage', array(id: @player.'cyborgmissile', priority: 'HIGH'), array(type: 'ARMOR_STAND'), @event, @pvp, @player) {
		@damager = null;
		if(array_index_exists(@event, 'damager') && array_index_exists(@pvp['players'], @event['damager'])) {
			@damager = @event['damager'];
		} else if(array_index_exists(@event, 'shooter') && array_index_exists(@pvp['players'], @event['shooter'])) {
			@damager = @event['shooter'];
		}
		if(@damager && @damager != @player) {
			@helmet = get_mob_equipment(@event['id'])['helmet'];
			if(@helmet && @helmet['name'] == 'PLAYER_HEAD') {
				consume();
				@loc = entity_loc(@event['id']);
				spawn_particle(@loc, 'EXPLOSION_LARGE');
				play_sound(@loc, array(sound: 'ENTITY_GENERIC_EXPLODE'));
				entity_remove(@event['id']);
				foreach(@e in entities_in_radius(@loc, 4)) {
					if(is_entity_living(@e)) {
						damage_entity(@e, 8 - distance(location_shift(entity_loc(@e), 'up'), @loc), puuid(@player));
					}
				}
			}
		}
	}

	bind('player_toggle_sneak', array(id: @player.'cyborgsneak'), array(player: @player, sneaking: true), @event, @pvp) {
		set_pexp(0);
		@loc = ploc();
		play_sound(@loc, array(sound: 'BLOCK_NOTE_BLOCK_BIT', volume: 0.5, pitch: 0.5), player());
		set_interval(100, closure(){
			try {
				if(!psneaking()) {
					clear_task();
					set_pexp(0);
					die();
				}
				@xp = pexp();
				if(@xp < 99) {
					@xp = min(99, @xp + 6);
					set_pexp(@xp);
					play_sound(@loc, array(sound: 'BLOCK_NOTE_BLOCK_BIT', volume: 0.4, pitch: 0.52 + 1.48 * (@xp / 99)), player());
				} else {
					title(player(), '', color('yellow').'[launching_orbital_strike]', 0, 10, 10);
					clear_task();
					set_pexp(0);
					@loc = location_shift(ploc(), 'up', 1.5);
					play_sound(@loc, array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED'));

					@radius = 5;
					@circle = array();
					for(@angle = 0, @angle < 6.28, @angle += 0.3) {
						@circle[] = array(
							x: @radius * cos(@angle) + @loc['x'],
							y: @loc['y'],
							z: @radius * sin(@angle) + @loc['z'],
							world: @loc['world'],
						);
					}

					@timer = array(5);
					set_interval(500, closure(){
						@timer[0]--;
						if(@timer[0] < -10) {
							clear_task();
						} else if(@timer[0] < 0) {
							@hitLoc = @loc[];
							@hitLoc['yaw'] = rand(360);
							@hitLoc['pitch'] = 0;
							@vector = get_vector(@hitLoc, rand() * 5);
							@hitLoc['x'] += @vector['x'];
							@hitLoc['z'] += @vector['z'];
							@bind = bind('entity_damage', null, array(type: 'PLAYER'), @event, @damager = player(), @pvp) {
								if(array_index_exists(@pvp['players'], @event['player'])) {
									set_mob_killer(@event['id'], @damager);
									_stats_damage(@damager, @event['player'], @event['amount'], @pvp);
								}
							}
							explosion(@hitLoc, 2, true);
							unbind(@bind);
							@particle = array(particle: 'REDSTONE', color: 'WHITE');
							while(@hitLoc['y'] < @loc['y'] + 40) {
								@hitLoc['y'] += 0.2 + (@hitLoc['y'] - @loc['y']) * 0.1;
								spawn_particle(@hitLoc, @particle);
							}
						} else {
							@targetLoc = @loc[];
							while(@targetLoc['y'] < @loc['y'] + 40) {
								@targetLoc['y'] += 0.2 + (@targetLoc['y'] - @loc['y']) * 0.1;
								spawn_particle(@targetLoc, 'REDSTONE');
							}
							foreach(@point in @circle) {
								spawn_particle(@point, 'REDSTONE');
							}
						}
					});
				}
			} catch(PlayerOfflineException @ex) {
				clear_task();
			}
		});
	}

	
case 'unload':
	unbind(@player.'cyborghand');
	unbind(@player.'cyborgmissile');
	unbind(@player.'cyborgshoot');
	unbind(@player.'cyborgsneak');
	
}
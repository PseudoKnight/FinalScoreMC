register_command('worm', array(
	description: 'Creates a worm',
	usage: '/worm <create|delete> [length]',
	permission: 'command.entity',
	tabcompleter: closure(@alias, @sender, @args, @info) {
		return(array());
	},
	executor: closure(@alias, @sender, @args, @info) {
		@worms = import('worms', array());

		@body = 'BLACK_CONCRETE_POWDER';
		@heart = 'NETHER_WART_BLOCK';
		@speed = 0.25;
		@digSpeed = 0.10;

		if(@args[0] == 'create') {
			@loc = ptarget_space();
			@length = integer(array_get(@args, 1, 11));

			@segments = spawn_entity('ARMOR_STAND', @length, @loc);
			foreach(@i: @segment in @segments) {
				set_entity_spec(@segment, array('baseplate': false, 'gravity': false, 'arms': true, 'visible': false, 'poses': array(
					'poseArmLeft': array(-0.2, 0, -0.9),
					'poseArmRight': array(-0.3, 0, 1.0),
					'poseLegLeft': array(-3.2, 0, 0),
					'poseLegRight': array(-3.2, 0, 0),
				)));
				set_mob_equipment(@segment, array(
					'helmet': array('name': if(@i % 4 != 1, @body, @heart)),
				));
			}
			@worm = array(
				'segments': @segments,
				'target': '',
				'loc': entity_loc(@segments[0]),
			);
			@worms[] = @worm;
			export('worms', @worms);

			if(array_size(@worms) == 1) {
				set_interval(50, closure(){
					@clear = false;
					try {
						foreach(@i: @w in @worms) {
							if(entity_exists(@w['segments'][0])) {
								@loc = entity_loc(@w['segments'][0]);
								@p = @w['target'];
								
								if(!@p || phealth(@p) == 0 || pmode(@p) == 'SPECTATOR') {
									@players = players_in_radius(@loc, 32);
									@p = '';
									foreach(@pl in @players) {
										if(phealth(@pl) > 0 && pmode(@pl) != 'SPECTATOR') {
											@w['target'] = @pl;
											@p = @pl;
											break();
										}
									}
									if(!@p) {
										continue();
									}
								}

								// tick worm
								@headLoc = location_shift(@loc, 'up', 2);
								@headLoc['pitch'] = 90;
								@gravity = false;
								if(get_block_info(@headLoc)['solid']) {
									spawn_particle(@headLoc, array('particle': 'BLOCK_DUST', 'count': 15, 'block': get_block(@headLoc)));
									@speed = @digSpeed;
								} else if(!ray_trace(@headLoc, 0.60)['hitblock']) {
									@gravity = true;
								}

								@ploc = ploc(@p);
								@newLoc = location_shift(@ploc, 'down', 0.45);
								if(distance(@loc, @newLoc) < 1) {
									damage_entity(puuid(@p), 2, @w['segments'][0]);
								} else {
									play_sound(@loc, array('sound': 'ENTITY_SPIDER_STEP', 'pitch': 1.5 + (@speed * 2), 'volume': 0.05));
									@yaw = get_yaw(@loc, @newLoc);
									@pitch = get_pitch(@loc, @newLoc);
									
									// clamp turning radius
									@diffYaw = @w['loc']['yaw'] - @yaw;
									if(abs(@diffYaw) > 180) {
										if(@diffYaw < 0) {
											@diffYaw += 360;
										} else {
											@diffYaw -= 360;
										}
									}
									if(@diffYaw < -7) {
										@yaw = @w['loc']['yaw'] + 7;
									} else if(@diffYaw > 7) {
										@yaw = @w['loc']['yaw'] - 7;
									}

									if(@gravity && (@pitch < 1 || @pitch > 4)) {
										@pitch = min(90, @w['loc']['pitch'] + 4);
									} else {
										@diffPitch = @w['loc']['pitch'] - @pitch;
										if(@diffPitch < -7) {
											@pitch = min(90, @w['loc']['pitch'] + 7);
										} else if(@diffPitch > 7) {
											@pitch = max(-90, @w['loc']['pitch'] - 7);
										}
									}

									@loc['yaw'] = @yaw;
									@loc['pitch'] = @pitch;
									@v = get_vector(@loc, @speed);
									@newLoc['x'] = @loc['x'] + @v['x'];
									@newLoc['y'] = @loc['y'] + @v['y'];
									@newLoc['z'] = @loc['z'] + @v['z'];
									@newLoc['yaw'] = @yaw;
									@newLoc['pitch'] = @pitch;
									set_entity_loc(@w['segments'][0], @newLoc);
									@poseHead = array(to_radians(@pitch), 0, 0);
									set_entity_spec(@w['segments'][0], array('poses': array('poseHead': @poseHead)));
									@w['loc'] = @newLoc;

									foreach(@i: @s in @w['segments']) {
										if(@i > 0) {
											@loc = entity_loc(@s);
											if(distance(@loc, @newLoc) > 0.7) {
												@loc['yaw'] = get_yaw(@loc, @newLoc);
												@poseHead[0] = to_radians(get_pitch(@loc, @newLoc));
												@newLoc = location_shift(@loc, @newLoc, @speed);
												set_entity_loc(@s, @newLoc);
												set_entity_spec(@s, array('poses': array('poseHead': @poseHead)));
											} else {
												@newLoc = @loc;
											}
										}
									}
								}
							} else {
								array_remove(@worms, @i);
								foreach(@s in @w['segments']) {
									try {
										spawn_particle(location_shift(entity_loc(@s), 'up', 2), array('particle': 'BLOCK_DUST', 'count': 15, 'block': @body));
										entity_remove(@s);
									} catch (BadEntityException @ex) {
										// doesn't exist
									}
								}
							}
						}
					} catch (Exception @ex) {
						console(@ex);
						@clear = true;
					}
					if(!@worms || @clear) {
						clear_task();
						unbind('wormdamage');
						export('worms', null);
						if(@worms) {
							foreach(@w in @worms) {
								foreach(@s in @w) {
									try(entity_remove(@s))
								}
							}
						}
					}
				});
				bind('entity_damage', array('id': 'wormdamage', 'priority': 'HIGH'), array('type': 'ARMOR_STAND'), @event, @worms, @body, @heart) {
					if(is_cancelled()) {
						foreach(@i: @w in @worms) {
							@found = false;
							foreach(@s in @w['segments']) {
								if(@event['id'] == @s) {
									@equipment = get_mob_equipment(@s);
									if(@equipment['helmet'] && @equipment['helmet']['name'] == @heart) {
										@equipment['helmet'] = array('name': @body);
										set_mob_equipment(@s, @equipment);
										@loc = location_shift(@event['location'], 'up', 2);
										spawn_particle(@loc, array('particle': 'BLOCK_DUST', 'count': 15, 'block': @heart));
										play_sound(@loc, array('sound': 'BLOCK_SLIME_BLOCK_BREAK', 'pitch': 0.7));
										spawn_entity('AREA_EFFECT_CLOUD', 1, location_shift(@loc, 'down', 0.55), closure(@id){
											set_entity_spec(@id, array(
												'particle': array('particle': 'REDSTONE','color': array('r': 200, 'g': 90, 'b': 60)),
												'color': array('r': 160, 'g': 80, 'b': 60),
												'radius': 2,
												'duration': 200,
												'reapplicationdelay': 10,
												'potionmeta': array(
													'base': array(
														'type': 'INSTANT_DAMAGE',
													),
												),
												'source': @event['id'],
											));
										});
										@found = true;
										break();
									}
									if(array_index_exists(@event, 'damager') && length(@event['damager']) < 17) {
										@w['target'] = @event['damager'];
									} else if(array_index_exists(@event, 'shooter') && length(@event['shooter'])) {
										@w['target'] = @event['shooter'];
									}
								}
							}
							if(@found) {
								@alive = false;
								foreach(@s in @w['segments']) {
									@equipment = get_mob_equipment(@s);
									if(@equipment['helmet']['name'] == @heart) {
										@alive = true;
										break();
									}
								}
								if(!@alive) {
									array_remove(@worms, @i);
									foreach(@s in @w['segments']) {
										queue_push(closure() {
											@loc = location_shift(entity_loc(@s), 'up', 2);
											spawn_particle(@loc, array('particle': 'BLOCK_DUST', 'count': 15, 'block': @body));
											play_sound(@loc, array('sound': 'BLOCK_SLIME_BLOCK_BREAK', 'pitch': 1.4));
											entity_remove(@s);
										}, 'worm');
										queue_delay(50, 'worm');
									}
								}
								break();
							}
						}
					}
				}
			}
		} else if(@args[0] == 'delete') {
			foreach(@i: @w in @worms) {
				foreach(@s in @w['segments']) {
					try(entity_remove(@s))
				}
				array_remove(@worms, @i);
			}
			export('worms', null);
			unbind('wormdamage');
		}
	}
));
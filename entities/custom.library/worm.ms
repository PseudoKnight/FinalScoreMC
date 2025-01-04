proc _worm_spawn(@loc, @spec = associative_array()) {
	@worms = import('worms', array());
	export('worms', @worms);

	@type = array_get_rand(reflect_pull('enum', 'WoodType'));
	string @body;
	string @heart;
	if(@type == 'BAMBOO') {
		if(rand(2)) {
			@body = 'STRIPPED_CRIMSON_HYPHAE';
			@heart = 'CRIMSON_HYPHAE';
		} else {
			@body = 'STRIPPED_WARPED_HYPHAE';
			@heart = 'WARPED_HYPHAE';
		}
	} else {
		@body = 'STRIPPED_'.@type.'_WOOD';
		@heart = 'STRIPPED_'.@type.'_LOG';
	}

	@loc = location_shift(@loc, 'down', 1.5);
	@worm = array_merge(array(
		length: 11,
		speed: 0.25,
		digSpeed: 0.10,
		body: @body,
		heart: @heart,
		target: '',
		loc: @loc,
	), @spec);

	@worm['segments'] = spawn_entity('ARMOR_STAND', @worm['length'], @loc, closure(@id) {
		set_entity_saves_on_unload(@id, false);
		set_entity_spec(@id, array(
			baseplate: false, 
			gravity: false, 
			arms: true, 
			visible: false, 
			poses: array(
				poseArmLeft: array(-0.2, 0, -0.9),
				poseArmRight: array(-0.3, 0, 1.0),
				poseLegLeft: array(-3.2, 0, 0),
				poseLegRight: array(-3.2, 0, 0))));
		add_scoreboard_tag(@id, 'remove');
		add_scoreboard_tag(@id, 'worm');
	});
	foreach(@i: @segment in @worm['segments']) {
		set_mob_equipment(@segment, array(
			helmet: array(name: if(@i % 4 != 1, @worm['body'], @worm['heart'])),
		));
	}

	@worms[] = @worm;

	if(has_bind('wormdamage')) {
		return(@worm['segments'][0]);
	}

	set_interval(50, closure(){
		foreach(@i: @w in @worms) {
			try {
				if(get_entity_invulnerable(@w['segments'][0])) {
					continue();
				}
				@loc = entity_loc(@w['segments'][0]);
				@target = @w['target'];
				
				if(!@target || !phealth(@target) || pmode(@target) === 'SPECTATOR' || distance(ploc(@target), @loc) > 32) {
					@players = players_in_radius(@loc, 32);
					@target = '';
					foreach(@p in @players) {
						if(phealth(@p) > 0 && pmode(@p) !== 'SPECTATOR') {
							@w['target'] = @p;
							@target = @p;
							break();
						}
					}
					if(!@target) {
						continue();
					}
				}

				// tick worm
				@headLoc = location_shift(@loc, 'up', 2);
				@headLoc['pitch'] = 90;
				@gravity = false;
				@iterationSpeed = @w['speed'];
				@trace = ray_trace(@headLoc, 0.60);
				if(get_block_info(@headLoc)['solid']) {
					spawn_particle(@headLoc, array(particle: 'BLOCK_DUST', count: 15, block: get_block(@headLoc)));
					@iterationSpeed = @w['digSpeed'];
				} else if(!@trace['hitblock']) {
					@gravity = true;
				}

				@ploc = ploc(@target);
				@newLoc = location_shift(@ploc, 'down', 0.45);
				if(distance(@loc, @newLoc) < 1) {
					damage_entity(puuid(@target), 2, @w['segments'][0]);
				} else {
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

					play_sound(@loc, array(sound: 'ENTITY_SPIDER_STEP', pitch: 1.5 + (@iterationSpeed * 2), volume: 0.05));

					@v = get_vector(@loc, @iterationSpeed);
					@newLoc['x'] = @loc['x'] + @v['x'];
					@newLoc['y'] = @loc['y'] + @v['y'];
					@newLoc['z'] = @loc['z'] + @v['z'];
					@newLoc['yaw'] = @yaw;
					@newLoc['pitch'] = @pitch;
					set_entity_loc(@w['segments'][0], @newLoc);
					@poseHead = array(to_radians(@pitch), 0, 0);
					set_entity_spec(@w['segments'][0], array(poses: array(poseHead: @poseHead)));
					@w['loc'] = @newLoc;

					foreach(@i: @s in @w['segments']) {
						if(@i > 0) {
							@segmentLoc = entity_loc(@s);
							@d = distance(@segmentLoc, @loc);
							if(@d > 0.3) {
								@segmentLoc['yaw'] = get_yaw(@segmentLoc, @loc);
								@poseHead[0] = to_radians(get_pitch(@segmentLoc, @loc));
								@adjustedPos = location_shift(@segmentLoc, @loc, @d - 0.3);
								if(@i % 4 == 1) {
									@adjustedPos = location_shift(@adjustedPos, 'up', 0.01);
								}
								set_entity_loc(@s, @adjustedPos);
								set_entity_spec(@s, array(poses: array(poseHead: @poseHead)));
							}
							@loc = @segmentLoc;
						}
					}
				}
			} catch (Exception @ex) {
				array_remove(@worms, @i);
				foreach(@s in @w['segments']) {
					try(entity_remove(@s))
				}
			}
		}
		if(!@worms) {
			clear_task();
			unbind('wormdamage');
		}
	});

	bind('entity_damage', array(id: 'wormdamage', priority: 'HIGH'), array(type: 'ARMOR_STAND'), @event, @worms) {
		if(has_scoreboard_tag(@event['id'], 'worm')) {
			cancel();
			@id = @event['id'];
			foreach(@i: @w in @worms) {
				foreach(@s in @w['segments']) {
					if(@id !== @s) {
						continue();
					}
					if(array_index_exists(@event, 'damager') && length(@event['damager']) < 17) {
						@w['target'] = @event['damager'];
					} else if(array_index_exists(@event, 'shooter') && length(@event['shooter'])) {
						@w['target'] = @event['shooter'];
					}
					@equipment = get_mob_equipment(@s);
					if(@equipment['helmet'] && @equipment['helmet']['name'] === @w['heart']) {
						@equipment['helmet'] = array(name: @w['body']);
						set_mob_equipment(@s, @equipment);
						@loc = location_shift(@event['location'], 'up', 2);
						spawn_particle(@loc, array(particle: 'BLOCK_DUST', count: 15, block: @w['heart']));
						play_sound(@loc, array(sound: 'BLOCK_SLIME_BLOCK_BREAK', pitch: 0.7));
						spawn_entity('AREA_EFFECT_CLOUD', 1, location_shift(@loc, 'down', 0.55), closure(@cloud){
							set_entity_spec(@cloud, array(
								particle: array(particle: 'REDSTONE', color: array(r: 200, g: 90, b: 60)),
								color: array(r: 160, g: 80, b: 60),
								radius: 2,
								duration: 200,
								reapplicationdelay: 10,
								source: @id,
								potionmeta: array(potiontype: 'HARMING')));
						});
						foreach(@s in @w['segments']) {
							@equipment = get_mob_equipment(@s);
							if(@equipment['helmet']['name'] === @w['heart']) {
								die();
							}
						}
						array_remove(@worms, @i);
						foreach(@s in @w['segments']) {
							queue_push(closure() {
								@loc = location_shift(entity_loc(@s), 'up', 2);
								spawn_particle(@loc, array(particle: 'BLOCK_DUST', count: 15, block: @w['body']));
								play_sound(@loc, array(sound: 'BLOCK_SLIME_BLOCK_BREAK', pitch: 1.4));
								entity_remove(@s);
							}, 'worm');
							queue_delay(50, 'worm');
						}
					}
					die();
				}
			}
		}
	}
	return(@worm['segments'][0]);
}
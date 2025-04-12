proc _worm_spawn(@loc, @spec = associative_array()) {
	@worms = import('worms', array());
	export('worms', @worms);

	@type = array_get_rand(reflect_pull('enum', 'WoodType'));
	string @body;
	string @heart;
	if(@type == 'BAMBOO') {
		if(rand(2)) {
			@body = 'STRIPPED_CRIMSON_HYPHAE';
			@heart = 'CRIMSON_STEM';
		} else {
			@body = 'STRIPPED_WARPED_HYPHAE';
			@heart = 'WARPED_STEM';
		}
	} else {
		@body = 'STRIPPED_'.@type.'_WOOD';
		@heart = 'STRIPPED_'.@type.'_LOG';
	}
	
	@loc = location_shift(@loc, 'up', 0.0); // create new standard location array
	@worm = array_merge(array(
		length: 5 + 4 * rand(6) + 1,
		width: 0.3 + rand() / 2,
		speed: 0.25,
		digSpeed: 0.10,
		body: @body,
		heart: @heart,
		target: '',
		loc: @loc,
		elevateTicks: 0,
		pauseTicks: 0,
		groundedTicks: 0,
	), @spec);

	@worm['segments'] = spawn_entity('ITEM_DISPLAY', @worm['length'], @loc, closure(@id) {
		set_entity_saves_on_unload(@id, false);
		set_display_entity(@id, array(
			brightness: 15,
			teleportduration: 2,
			transformation: array(
				scale: array(x: @worm['width'], y: @worm['width'], z: @worm['width']),
				translation: array(x: 0.0, y: @worm['width'] / 2, z: 0.0))));
	});
	@teeth = spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@id) {
		set_entity_saves_on_unload(@id, false);
		set_display_entity(@id, array(
			brightness: 15,
			teleportduration: 2,
			transformation: array(
				scale: array(x: @worm['width'] * 0.57, y: @worm['width'] * 0.57, z: @worm['width'] * 0.57),
				translation: array(x: 0.0, y: @worm['width'] * 0.5, z: (@worm['width'] * 0.52)),
				leftRotation: array(x: 0.71, y: 0.0, z: 0.0, w: 0.71))));
		set_entity_spec(@id, array(item: array(name: 'SCULK_SHRIEKER')));
	})[0];
	set_entity_rider(@worm['segments'][0], @teeth);
	foreach(@i: @segment in @worm['segments']) {
		set_entity_spec(@segment, array(item: array(name: if(@i && @i % 4 != 2, @worm['body'], @worm['heart']))));
		if(@i >= length(@worm['segments']) - 2) {
			if(@i >= length(@worm['segments']) - 1) {
				set_display_entity(@segment, array(
					transformation: array(
						scale: array(x: @worm['width'] * 0.7, y: @worm['width'] * 0.7, z: @worm['width']))));
			} else {
				set_display_entity(@segment, array(
					transformation: array(
						scale: array(x: @worm['width'] * 0.85, y: @worm['width'] * 0.85, z: @worm['width']))));
			}
		} else if(!@i) {
				set_display_entity(@segment, array(
					transformation: array(
						leftRotation: array(x: 0.71, y: 0.0, z: 0.0, w: 0.71),
						scale: array(x: @worm['width'] * 0.85, y: @worm['width'], z: @worm['width'] * 0.85))));
		} else if(@i % 4 == 2) {
			set_display_entity(@segment, array(
				transformation: array(
					scale: array(x: @worm['width'] * 1.05, y: @worm['width'] * 1.05, z: @worm['width'] * 1.05))));
			@shulker = spawn_entity('SHULKER', 1, @loc, closure(@id) {
				set_entity_ai(@id, false);
				set_entity_silent(@id, true);
				set_entity_saves_on_unload(@id, false);
				set_entity_attribute_base(@id, 'GENERIC_SCALE', @worm['width']);
				set_mob_effect(@id, 'invisibility', 0, -1, true, false);
				add_scoreboard_tag(@id, 'worm');
			})[0];
			set_entity_rider(@segment, @shulker);
		}
	}

	@worms[] = @worm;

	if(has_bind('wormdamage')) {
		return(@worm['segments'][0]);
	}

	set_interval(50, closure(){
		foreach(@i: @w in @worms) {
			try {
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

				// check if in range to attack target
				@ploc = ploc(@target);
				@newLoc = location_shift(@ploc, 'up', 1.02);
				if(distance(@loc, @newLoc) < 1) {
					damage_entity(puuid(@target), 2, @w['segments'][0]);
					continue();
				}

				// check if pausing movement
				if(@w['pauseTicks']) {
					@w['pauseTicks']--;
					continue();
				}

				// tick worm
				@headLoc = @loc[];
				@headLoc['pitch'] = 90;
				@gravity = false;
				@iterationSpeed = @w['speed'];
				@w['groundedTicks']++;
				if(get_block_info(@headLoc)['solid']) {
					spawn_particle(@headLoc, array(
						particle: 'BLOCK_DUST',
						count: 15,
						block: get_block(@headLoc),
						xoffest: @w['width'],
						zoffset: @w['width']));
					@iterationSpeed = @w['digSpeed'];
				} else if(!ray_trace(@headLoc, @w['width'])['hitblock']) {
					@gravity = true;
					@w['groundedTicks'] = 0;
				} else if(@w['groundedTicks'] > 40) {
					foreach(@nearbyEntity in entities_in_radius(@loc, 1, 'ITEM_DISPLAY')) {
						if(@nearbyEntity != get_entity_rider(@w['segments'][0]) && !array_contains(@w['segments'], @nearbyEntity)) {
							@w['elevateTicks'] = min(ceil(length(@w['segments']) / 2), rand(4, 16));
							break();
						}
					}
				}

				// rear head up
				if(@w['elevateTicks']) {
					@w['elevateTicks']--;
					@halfLength = length(@w['segments']) / 2;
					foreach(@segmentIndex: @s in @w['segments']) {
						if(@segmentIndex > @halfLength) {
							continue();
						}
						@segmentLoc = entity_loc(@s);
						@adjustedLoc = location_shift(@segmentLoc, 'up', @w['width'] / 8 * (sin(1.57 + @segmentIndex / @halfLength * 3.14) + 1));
						set_entity_loc(@s, @adjustedLoc);
						if(@segmentIndex == 0) {
							@w['loc'] = @adjustedLoc;
						}
					}
					if(!@w['elevateTicks']) {
						@w['pauseTicks'] = rand(10, 30);
					}
					continue();
				}

				// regular movement
				@yaw = get_yaw(@loc, @newLoc);
				if(@yaw == NaN) {
					@yaw = @loc['yaw'];
				}
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
					@pitch = min(89, @w['loc']['pitch'] + 4);
				} else {
					@diffPitch = @w['loc']['pitch'] - @pitch;
					if(@diffPitch < -7) {
						@pitch = min(89, @w['loc']['pitch'] + 7);
					} else if(@diffPitch > 7) {
						@pitch = max(-89, @w['loc']['pitch'] - 7);
					}
				}

				@loc['yaw'] = @yaw;
				@loc['pitch'] = @pitch;

				play_sound(@loc, array(sound: 'ENTITY_SPIDER_STEP', pitch: 1.5 + (@iterationSpeed * 2), volume: 0.05));

				@v = get_vector(@loc, @iterationSpeed + if(@gravity, @iterationSpeed / 2, 0));
				@newLoc['x'] = @loc['x'] + @v['x'];
				@newLoc['y'] = @loc['y'] + @v['y'];
				@newLoc['z'] = @loc['z'] + @v['z'];
				@newLoc['yaw'] = @yaw;
				@newLoc['pitch'] = @pitch;
				set_entity_loc(@w['segments'][0], @newLoc);
				set_entity_rotation(get_entity_rider(@w['segments'][0]), @yaw, @pitch);
				@w['loc'] = @newLoc;
				@parentLoc = @newLoc[];

				foreach(@segmentIndex: @s in @w['segments']) {
					if(@segmentIndex < 1) {
						continue();
					}
					@v = get_vector(@parentLoc, @w['width'] / 2.2);
					@parentLoc = array(
						x: @parentLoc['x'] - @v['x'],
						y: @parentLoc['y'] - @v['y'],
						z: @parentLoc['z'] - @v['z'],
						world: @parentLoc['world'],
					);
					@segmentLoc = entity_loc(@s);
					@d = distance(@segmentLoc, @parentLoc);
					if(@d > @w['width'] / 2.2) {
						@adjustedLoc = location_shift(@segmentLoc, @parentLoc, @d - @w['width'] / 2.2);
						if(@segmentLoc['x'] != @parentLoc['x'] || @segmentLoc['z'] != @parentLoc['z']) {
							@adjustedLoc['yaw'] = get_yaw(@segmentLoc, @parentLoc);
							@adjustedLoc['pitch'] = get_pitch(@segmentLoc, @parentLoc);
						} else if(@segmentLoc['y'] != @parentLoc['y']) {
							@adjustedLoc['pitch'] = get_pitch(@segmentLoc, @parentLoc);
						}
						set_entity_loc(@s, @adjustedLoc);
						@parentLoc = @adjustedLoc;
					} else {
						@parentLoc = @segmentLoc;
					}
				}
			} catch (Exception @ex) {
				array_remove(@worms, @i);
				foreach(@s in @w['segments']) {
					try {
						foreach(@r in get_entity_riders(@s)) {
							entity_remove(get_entity_rider(@r));
						}
						entity_remove(@s);
					} catch(BadEntityException @ignore) {}
				}
			}
		}
		if(!@worms) {
			clear_task();
			unbind('wormdamage');
		}
	});

	bind('entity_damage', array(id: 'wormdamage'), array(type: 'SHULKER'), @event, @worms) {
		if(has_scoreboard_tag(@event['id'], 'worm')) {
			cancel();
			@damager = null;
			if(array_index_exists(@event, 'damager') && @event['damagertype'] === 'PLAYER') {
				@damager = @event['damager'];
			} else if(array_index_exists(@event, 'shooter') && ponline(@event['shooter'])) {
				@damager = @event['shooter'];
			}
			if(!@damager) {
				die();
			}
			@id = @event['id'];
			foreach(@i: @w in @worms) {
				foreach(@s in @w['segments']) {
					if(@id !== get_entity_rider(@s)) {
						continue();
					}
					if(!@w['groundedTicks']) {
						die();
					}
					@w['target'] = @damager;
					set_entity_spec(@s, array(item: array(name: @w['body'])));
					set_display_entity(@s, array(transformation: array(scale: array(x: @w['width'], y: @w['width'], z: @w['width']))));
					spawn_entity('EXPERIENCE_ORB', 1, @event['location'], closure(@orb) {
						set_entity_spec(@orb, array(amount: 5));
					});
					@loc = @event['location'];
					spawn_particle(location_shift(@loc, 'up', @w['width'] / 2), array(
						particle: 'BLOCK_DUST',
						count: 15,
						block: @w['heart'],
						xoffest: @w['width'],
						yoffset: @w['width'],
						zoffset: @w['width']));
					play_sound(@loc, array(sound: 'BLOCK_SLIME_BLOCK_BREAK', pitch: 0.7));
					spawn_entity('AREA_EFFECT_CLOUD', 1, @loc, closure(@cloud){
						set_entity_spec(@cloud, array(
							particle: array(particle: 'REDSTONE', color: array(r: 200, g: 90, b: 60)),
							color: array(r: 160, g: 80, b: 60),
							radius: 2,
							duration: 200,
							reapplicationdelay: 10,
							potionmeta: array(potiontype: 'HARMING')));
					});
					entity_remove(@id);
					foreach(@s in @w['segments']) {
						@rider = get_entity_rider(@s);
						if(@rider && entity_type(@rider) === 'SHULKER') {
							die();
						}
					}
					array_remove(@worms, @i);
					foreach(@s in @w['segments']) {
						queue_push(closure() {
							@loc = entity_loc(@s);
							spawn_particle(location_shift(@loc, 'up', @w['width'] / 2), array(
								particle: 'BLOCK_DUST', 
								count: 15,
								block: @w['body'],
								xoffest: @w['width'],
								yoffset: @w['width'],
								zoffset: @w['width']));
							play_sound(@loc, array(sound: 'BLOCK_SLIME_BLOCK_BREAK', pitch: 1.4));
							@rider = get_entity_rider(@s);
							if(@rider) {
								entity_remove(@rider);
							}
							entity_remove(@s);
						}, 'worm');
						queue_delay(50, 'worm');
					}
					die();
				}
			}
		}
	}
	return(@worm['segments'][0]);
}
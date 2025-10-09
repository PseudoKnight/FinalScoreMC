execute(iclosure(){
	proc _opposite_portal(@portals, @color, @button) {
		return(@portals[@color][if(@button === 'left', 'right', 'left')]);
	}

	proc _portal_to(@player, @portals, @color, @button, @entityLoc, @exitVelocity = 0.15) {
		@yaw = @entityLoc['yaw'];
		@pitch = @entityLoc['pitch'];
		@portal = @portals[@color][@button];
		@entrance = @portal['exit'];
		@opposite = _opposite_portal(@portals, @color, @button);
		if(!@opposite) {
			return();
		}
		@exit = @opposite['exit'];
		if(time() < @portal['lastEnter'] + 150) {
			return();
		}
		if(time() < @opposite['lastEnter'] + 150) {
			return();
		}
		@portal['lastEnter'] = time();
		@opposite['lastEnter'] = time();
		if(!is_null(@entrance['yaw']) && !is_null(@exit['yaw'])) {
			@yaw += @exit['yaw'] - @entrance['yaw'] + 180;
		} else if(!is_null(@entrance['pitch'])) {
			if(!is_null(@exit['pitch'])) {
				if(@entrance['pitch'] == @exit['pitch']) {
					@pitch = neg(@pitch);
				}
			} else {
				@yaw = @exit['yaw'];
			}
		}
		relative_teleport(@player, array(@exit['x'], @exit['y'], @exit['z'], @exit['world'], @yaw, @pitch));
		set_pvelocity(@player, get_vector(@exit, min(3, @exitVelocity)));
		play_sound(@exit, array(sound: 'ENTITY_ILLUSIONER_MIRROR_MOVE', volume: 0.3));
		play_sound(@exit, array(sound: 'ENTITY_ILLUSIONER_CAST_SPELL', volume: 0.3));
	}

	proc _use_portal_gun(@color, @button, @portals) {
		if(import(player().'cube')) {
			export(player().'cube', null);
			return(true);
		}

		@trace = ray_trace(72);

		if(@trace['entities']) {
			@id = null;
			@clickLoc = null;
			foreach(@entity in @trace['entities']) {
				if(has_scoreboard_tag(@entity['uuid'], 'movable')) {
					@id = @entity['uuid'];
					while(@vehicle = get_entity_vehicle(@id)) {
						@id = @vehicle;
					}
					@clickLoc = @entity['location'];
					break();
				}
			}

			if(@id) {
				if(distance(@clickLoc, @trace['origin']) > 6) {
					play_sound(ploc(), array(sound: 'ENTITY_SHULKER_CLOSE'));
					return(true);
				}

				export(player().'cube', true);
				cancel();

				@eloc = entity_loc(@id);
				@dist = 2.5;
				play_sound(@id, array(sound: 'BLOCK_CHISELED_BOOKSHELF_PICKUP_ENCHANTED', volume: 0.6));

				@collider = spawn_entity('ARMOR_STAND', 1, @eloc, closure(@e) {
					set_entity_saves_on_unload(@e, false);
					set_entity_spec(@e, array(visible: false, small: true));
					set_entity_size(@e, 1, 1);
					set_entity_attribute_base(@e, 'GENERIC_GRAVITY', 0.0);
				})[0];
				play_sound(@collider, array(sound: 'MUSIC_DISC_CHIRP', pitch: 1.69, volume: 0.2));

				set_interval(50, 1, closure(){
					if(!ponline(player())
					|| !entity_exists(@collider)
					|| !entity_exists(@id)) {
						clear_task();
						export(player().'cube', null);
						play_sound(@id, array(sound: 'BLOCK_CHISELED_BOOKSHELF_PICKUP_ENCHANTED', pitch: 0.5, volume: 0.6));
						set_entity_rider(@id, get_entity_rider(@id));
						try(entity_remove(@collider))
						return();
					}
					@loc = entity_loc(@collider);
					if(entity_attribute_base(@collider, 'GENERIC_GRAVITY') > 0) {
						set_entity_loc(@id, @loc);
						if(entity_grounded(@collider)) {
							entity_remove(@collider);
						}
						return();
					}
					@item = pinv(player(), null);
					if(!import(player().'cube') || !@item || @item['name'] !== 'LANTERN' && @item['name'] !== 'SOUL_LANTERN') {
						set_entity_attribute_base(@collider, 'GENERIC_GRAVITY', 0.08);
					}
					@loc = entity_loc(@collider);
					@trace = ray_trace(player(), @dist);
					@distance = distance(@loc, @trace['location']);
					@vector = array(
						x: @trace['location']['x'] - @loc['x'],
						y: @trace['location']['y'] - 0.45 - @loc['y'],
						z: @trace['location']['z'] - @loc['z'],
					);
					set_entity_velocity(@collider, @vector);
					play_sound(@collider, array(sound: 'BLOCK_BEACON_AMBIENT', pitch: 2, volume: 0.2));
					set_entity_loc(@id, @loc);
				});
				return(true);
			}
		}

		if(!@trace['hitblock']) {
			play_sound(ploc(), array(sound: 'ENTITY_SHULKER_CLOSE'));
			return(true);
		}

		@block = @trace['block'];
		@loc = @trace['location'];
		@face = @trace['hitface'];

		// render particle trail
		@blockdata = null;
		@glowcolor = null;
		if(@color === 'orange') {
			if(@button === 'left') {
				@blockdata = 'yellow_concrete_powder';
				@glowcolor = array(r: 204, g: 171, b: 40);
			} else {
				@blockdata = 'orange_concrete_powder';
				@glowcolor = array(r: 216, g: 110, b: 23);
			}
		} else {
			if(@button === 'left') {
				@blockdata = 'light_blue_concrete_powder';
				@glowcolor = array(r: 40, g: 176, b: 204);
			} else {
				@blockdata = 'blue_concrete_powder';
				@glowcolor = array(r: 68, g: 79, b: 229);
			}
		}
		@origin = location_shift(@trace['origin'], 'down', 0.3);
		@particleDist = 0.2;
		@distance = distance(@origin, @loc);
		@maxParticles = @distance * 4;
		@distance /= @maxParticles;
		@particles = 0;
		while(@particles++ <= @maxParticles) {
			@origin = location_shift(@origin, @loc, @distance);
			spawn_particle(@origin, array(particle: 'BLOCK_CRUMBLE', block: @blockdata));
		}
		spawn_particle(@loc, array(particle: 'BLOCK_CRACK', block: @blockdata, count: 20));

		@portal = @block[];

		@portal['x'] += 0.5;
		@portal['z'] += 0.5;

		@extension = null;
		if(@face !== 'UP' && @face !== 'DOWN') {
			@portal = location_shift(@portal, @face);
			if(round(@loc['y']) == floor(@loc['y']) && get_block(location_shift(@portal, 'down')) === 'AIR') {
				@extension = location_shift(@block, 'down', 0); // consistent arrays
				@block = location_shift(@block, 'down');
				@portal['y'] -= 1;
			} else if(get_block(location_shift(@portal, 'up')) === 'AIR') {
				@block = location_shift(@block, 'down', 0); // consistent arrays
				@extension = location_shift(@block, 'up');
			} else {
				play_sound(ploc(), array(sound: 'ENTITY_SHULKER_CLOSE'));
				return(true);
			}
		} else if(@face === 'UP') {
			@portal['y'] += 1;
		} else if(@face === 'DOWN') {
			@portal['y'] -= 2;
		}

		if(get_block(@block) !== 'WHITE_CONCRETE' || @extension && get_block(@extension) !== 'WHITE_CONCRETE') {
			play_sound(ploc(), array(sound: 'ENTITY_SHULKER_CLOSE', seed: 2));
			return(true);
		}

		array @scale;
		array @translation;
		switch(@face) {
			case 'NORTH':
				@portal['yaw'] = 180;
				@portal['pitch'] = null;
				@scale = array(x: 0.96875, y: if(@extension, 1.96875, 0.96875), z: 0.015625);
				@translation = array(x: 0.015625, y: 0.015625, z: 0.984375);
			case 'SOUTH':
				@portal['yaw'] = 0;
				@portal['pitch'] = null;
				@scale = array(x: 0.96875, y: if(@extension, 1.96875, 0.96875), z: 0.015625);
				@translation = array(x: 0.015625, y: 0.015625, z: 0);
			case 'EAST':
				@portal['yaw'] = 270;
				@portal['pitch'] = null;
				@scale = array(x: 0.015625, y: if(@extension, 1.96875, 0.96875), z: 0.96875);
				@translation = array(x: 0, y: 0.015625, z: 0.015625);
			case 'WEST':
				@portal['yaw'] = 90;
				@portal['pitch'] = null;
				@scale = array(x: 0.015625, y: if(@extension, 1.96875, 0.96875), z: 0.96875);
				@translation = array(x: 0.984375, y: 0.015625, z: 0.015625);
			case 'UP':
				@portal['yaw'] = null;
				@portal['pitch'] = -90;
				@scale = array(x: 0.96875, y: 0.015625, z: 0.96875);
				@translation = array(x: 0.015625, y: 0.015625, z: 0.015625);
			case 'DOWN':
				@portal['yaw'] = null;
				@portal['pitch'] = 90;
				@scale = array(x: 0.96875, y: 0.015625, z: 0.96875);
				@translation = array(x: 0.015625, y: 0.984375, z: 0.015625);
		}

		@oppositePortal = _opposite_portal(@portals, @color, @button);
		if(@oppositePortal) {
			if(@oppositePortal['exit']['yaw'] == @portal['yaw'] && @oppositePortal['exit']['pitch'] == @portal['pitch']) {
				foreach(@b in @oppositePortal['blocks']) {
					if(@b && (array_subset_of(@b, @block) || @extension && array_subset_of(@b, @extension))) {
						play_sound(ploc(), array(sound: 'ENTITY_SHULKER_CLOSE', seed: 2));
						return(true);
					}
				}
			}
		}

		// clean up old portal entities before modifying the portals array
		if(@portals[@color][@button]) {
			try {
				entity_remove(@portals[@color][@button]['entity']);
			} catch(BadEntityException @ex) {
				msg('Failed to remove other portal.');
			}
		}

		// set new portal frames
		@portalDisplay = spawn_entity('BLOCK_DISPLAY', 1, location_shift(@block, @face), closure(@e){
			set_entity_saves_on_unload(@e, false);
			set_entity_spec(@e, array(blockdata: @blockdata));
			set_display_entity(@e, array(
				brightness: array(block: 0, sky: 15),
				glowcolor: @glowcolor,
				transformation: array(
					scale: @scale,
					translation: @translation)));
			set_entity_glowing(@e, true);
		})[0];

		@portals[@color][@button] = array(
			exit: @portal,
			blocks: array(@block, @extension),
			entity: @portalDisplay,
			lastEnter: 0,
			face: @face);

		if(!has_bind('portalgun'.player())) {
			bind('player_move', array(id: 'portalgun'.player()), array(threshold: 0, player: player()), @event, @portals) {
				if(pmode() !== 'ADVENTURE') {
					set_timeout(1, closure(unbind()));
					if(array_size(all_players(pworld())) <= 1) {
						foreach(@color in array('orange', 'blue')) {
							foreach(@button in array('left', 'right')) {
								@portal = @portals[@color][@button];
								if(@portal) {
									try(entity_remove(@portal['entity']))
									@portals[@color][@button] = null;
								}
							}
						}
					}
					die();
				}
				@from = @event['from'];
				@to = @event['to'];
				@clearPortals = false;
				if(get_block(@to) === 'LIGHT') {
					@clearPortals = true;
				}
				set_entity_fall_distance(puuid(), 0);
				@dist = distance(@from, @to);
				if(@dist < 3) { // ignore likely teleports
					@loc = @to[];
					@to['y'] -= 0.03;
					@loc['yaw'] = get_yaw(@from, @to);
					@loc['pitch'] = get_pitch(@from, @to);
					if(@loc['yaw'] == math_const('NaN')) {
						@loc['yaw'] = @to['yaw']; // fallback to old yaw
					}
					@loc['y'] += 0.1;
					@trace = ray_trace(@loc, @dist * 2 + 0.5);
					if(@trace['hitblock']) {
						@block = @trace['block'];
						@type = get_block(@block);
						if(@type === 'WHITE_CONCRETE') {
							foreach(@color in array('orange', 'blue')) {
								foreach(@button in array('left', 'right')) {
									@portal = @portals[@color][@button];
									if(@portal) {
										@b = @portal['blocks'][0];
										if(is_array(@b) && array_subset_of(@block, @b) && @trace['hitface'] === @portal['face']) {
											_portal_to(player(), @portals, @color, @button, @to, @dist);
											die();
										}
									}
								}
							}
						} else if(@type === 'LIGHT_BLUE_STAINED_GLASS_PANE') {
							@to['y'] += 0.03;
							relative_teleport(location_shift(@from, @to, distance(@to, @trace['location']) * 2));
							@clearPortals = true;
						}
					}
					if(@clearPortals) {
						if(phas_item(array(name: 'LANTERN'))) {
							foreach(@button in array('left', 'right')) {
								@portal = @portals['orange'][@button];
								if(@portal) {
									try(entity_remove(@portal['entity']))
									@portals['orange'][@button] = null;
									play_sound(@to, array(sound: 'ENTITY_SILVERFISH_AMBIENT', pitch: 2));
									play_sound(@to, array(sound: 'ENTITY_GENERIC_EXTINGUISH_FIRE', pitch: 2));
								}
							}
						}
						if(phas_item(array(name: 'SOUL_LANTERN'))) {
							foreach(@button in array('left', 'right')) {
								@portal = @portals['blue'][@button];
								if(@portal) {
									try(entity_remove(@portal['entity']))
									@portals['blue'][@button] = null;
									play_sound(@to, array(sound: 'ENTITY_SILVERFISH_AMBIENT', pitch: 2));
									play_sound(@to, array(sound: 'ENTITY_GENERIC_EXTINGUISH_FIRE', pitch: 2));
								}
							}
						}
					}
				}
			}
		}

		// play effects
		play_sound(@loc, array(sound: 'ENTITY_SHULKER_SHOOT', pitch: 1.3, volume: 3));

		// special case if they shoot right below a player
		if(@face === 'UP' && @oppositePortal) {
			foreach(@player in players_in_radius(@portal, 0.5)) {
				_portal_to(@player, @portals, @color, @button, ploc(@player));
			}
		}

		@edges = array();
		@particleLoc = location_shift(@block, @face, 0.0625);
		@targetLoc = @particleLoc[];
		if(@face === 'UP' || @face === 'DOWN') {
			if(@face === 'UP') {
				@particleLoc['y'] += 1.0;
				@targetLoc['y'] += 1.0;
			}
			@particleLoc['dir'] = 'south';
			@edges[] = @particleLoc[];
			@particleLoc['x'] += 1.0;
			@edges[] = @particleLoc[];
			@particleLoc['dir'] = 'east';
			@particleLoc['x'] -= 1.0;
			@edges[] = @particleLoc[];
			@particleLoc['z'] += 1.0;
			@edges[] = @particleLoc[];
			@targetLoc['x'] = floor(@targetLoc['x']) + 0.5;
			@targetLoc['z'] = floor(@targetLoc['z']) + 0.5;
		} else {
			if(@face === 'EAST') {
				@particleLoc['x'] += 1.0;
				@targetLoc['x'] += 1.0;
			} else if(@face === 'SOUTH') {
				@particleLoc['z'] += 1.0;
				@targetLoc['z'] += 1.0;
			}
			@particleLoc['dir'] = 'up';
			@edges[] = @particleLoc[];
			@particleLoc['y'] += 1;
			@edges[] = @particleLoc[];
			if(@face === 'EAST' || @face === 'WEST') {
				@particleLoc['z'] += 1;
				@edges[] = @particleLoc[];
				@particleLoc['y'] -= 1;
				@edges[] = @particleLoc[];
				@particleLoc['z'] -= 1;
				@particleLoc['dir'] = 'south';
				@targetLoc['z'] = floor(@targetLoc['z']) + 0.5;
			} else {
				@particleLoc['x'] += 1;
				@edges[] = @particleLoc[];
				@particleLoc['y'] -= 1;
				@edges[] = @particleLoc[];
				@particleLoc['x'] -= 1;
				@particleLoc['dir'] = 'east';
				@targetLoc['x'] = floor(@targetLoc['x']) + 0.5;
			}
			@edges[] = @particleLoc[];
			@particleLoc['y'] += 2;
			@edges[] = @particleLoc[];
			@targetLoc['y'] = ceil(@targetLoc['y']) + 1;
		}
		set_interval(50, closure(){
			if(!entity_exists(@portalDisplay)) {
				clear_task();
				if(@portals[@color][@button] && @portals[@color][@button]['entity'] === @portalDisplay) {
					@portals[@color][@button] = null;
				}
			} else {
				foreach(@edge in @edges) {
					@particleLoc = location_shift(@edge, @edge['dir'], rand());
					spawn_particle(@particleLoc, array(particle: 'REDSTONE', color: @glowcolor));
					if(_opposite_portal(@portals, @color, @button)) {
						spawn_particle(@particleLoc, array(particle: 'TRAIL', color: @glowcolor, target: @targetLoc));
					}
				}
			}
		});

		return(true);
	}

	@portals = array(
		orange: array(
			left: null,
			right: null),
		blue: array(
			left: null,
			right: null));

	bind('player_interact', array(priority: 'LOW'), array(itemname: 'LANTERN'), @event, @portals) {
		if(pmode() === 'ADVENTURE' && !pcooldown('LANTERN')) {
			if(_use_portal_gun('orange', @event['button'], @portals)) {
				set_pcooldown('LANTERN', 5);
			}
		}
	}

	bind('player_interact', array(priority: 'LOW'), array(itemname: 'SOUL_LANTERN'), @event, @portals) {
		if(pmode() === 'ADVENTURE' && !pcooldown('SOUL_LANTERN')) {
			if(_use_portal_gun('blue', @event['button'], @portals)) {
				set_pcooldown('SOUL_LANTERN', 5);
			}
		}
	}

});
proc _class_load(@player, @pvp) {
	set_interval(500, closure(){
		try {
			if(pmode(@player) === 'SPECTATOR'
			|| !array_index_exists(@pvp['players'], @player)
			|| @pvp['players'][@player]['class'] !== 'keeper') {
				clear_task();
				die();
			}
			@entities = @pvp['players'][@player]['entities'];
			foreach(@p in array_keys(@pvp['players'])) {
				if(@p === @player) {
					continue();
				}
				if(pmode(@p) === 'SPECTATOR') {
					if(!pcan_see_entity(@player, puuid(@p))) {
						pshow_entity(@player, puuid(@p));
					}
					continue();
				}
				@dist = 128;
				@loc = null;
				foreach(@id in array('sculk_sensor_first', 'sculk_sensor_last')) {
					if(array_index_exists(@entities, @id)) {
						try {
							@loc = location_shift(entity_loc(@entities[@id]), 'up', 0.7);
							@d = distance(@loc, ploc(@p));
							if(@d < @dist) {
								@dist = @d;
							}
						} catch(BadEntityException @ex) {}
					}
				}
				if(psneaking(@p) || @dist > 16) {
					if(pcan_see_entity(@player, puuid(@p))) {
						phide_entity(@player, puuid(@p));
					}
				} else if(!pcan_see_entity(@player, puuid(@p))) {
					spawn_particle(@loc, array(particle: 'VIBRATION', destination: puuid(@p)));
					play_named_sound(@loc, array(sound: 'entity.warden.tendril_clicks', pitch: 1.2));
					pshow_entity(@player, puuid(@p));
					set_peffect(@p, 'glowing', 1, 1, true, false);
				} else {
					set_peffect(@p, 'glowing', 1, 1, true, false);
				}
			}
		} catch(Exception @ex) {
			clear_task();
		}
	});

	bind('player_interact', array(id: @player.'sculk'), array(player: @player, button: 'right', itemname: 'SCULK_SENSOR', hand: 'main_hand'), @event, @pvp) {
		if(array_index_exists(@event, 'location') && @event['facing'] == 'up') {
			@material = material_info(get_block(@event['location']));
			if(@material['isTransparent'] || !@material['isSolid']) {
				die();
			}
			@loc = location_shift(@event['location'], 'up');
			if(get_block(@loc) == 'AIR') {
				@entities = @pvp['players'][player()]['entities'];
				if(array_index_exists(@entities, 'sculk_sensor_first')) {
					if(array_index_exists(@entities, 'sculk_sensor_last')) {
						try {
							@oldLoc = entity_loc(@entities['sculk_sensor_last']);
							entity_remove(@entities['sculk_sensor_last']);
							spawn_particle(location_shift(@oldLoc, 'up'), array(particle: 'SCULK_SOUL', count: 3, xoffset: 0.5, yoffset: 0.2, zoffset: 0.5));
						} catch(BadEntityException @ex) {}
					}
					@entities['sculk_sensor_last'] = @entities['sculk_sensor_first'];
				}
				@loc['x'] += @event['position']['x']
				@loc['y'] += 0.2;
				@loc['z'] += @event['position']['z'];
				spawn_particle(@loc, array(particle: 'SCULK_CHARGE', count: 5, xoffset: 0.6, yoffset: 0.2, zoffset: 0.6));
				play_named_sound(@loc, array(sound: 'block.sculk.place'));
				@loc = location_shift(@loc, 'down', 0.88);
				@entities['sculk_sensor_first'] = spawn_entity('ARMOR_STAND', 1, @loc, closure(@stand) {
					set_entity_spec(@stand, array(gravity: false, visible: false, small: true));
					set_mob_equipment(@stand, array(HELMET: array(name: 'SCULK_SENSOR')));
					add_scoreboard_tag(@stand, 'remove');
				})[0];
			}
		}
	}

	bind('entity_damage', array(id: @player.'sensor'), array(type: 'ARMOR_STAND', cause: 'ENTITY_ATTACK'), @event,
			@entities = @pvp['players'][@player]['entities']) {
		foreach(@sensor in array('sculk_sensor_first', 'sculk_sensor_last')) {
			if(array_index_exists(@entities, @sensor)) {
				if(@event['id'] == @entities[@sensor]) {
					spawn_particle(location_shift(entity_loc(@event['id']), 'up'), array(particle: 'SCULK_SOUL', count: 3, xoffset: 0.5, yoffset: 0.2, zoffset: 0.5));
					try(entity_remove(@entities[@sensor]))
					array_remove(@entities, @sensor);
					consume();
				}
			}
		}
	}

	bind('player_toggle_sneak', array(id: @player.'boom'), array(player: @player, sneaking: true), @event) {
		if(pexp() == 99) {
			play_named_sound(ploc(), array(sound: 'entity.warden.sonic_charge', volume: 2));
			set_pexp(0);
			set_interval(100, closure(){
				try {
					@xp = pexp();
					@xp = min(99, @xp + 1);
					set_pexp(@xp);
					if(@xp == 17) {
						if(!psneaking()) {
							clear_task();
							set_pexp(99);
							die();
						}
						@loc = location_shift(ploc(), 'up', 2.5);
						play_named_sound(@loc, array(sound: 'entity.warden.sonic_boom', volume: 2));
						@v = get_vector(@loc);
						@i = 16;
						while(@i-- > 0) {
							@loc['x'] += @v['x'];
							@loc['y'] += @v['y'];
							@loc['z'] += @v['z'];
							spawn_particle(@loc, 'SONIC_BOOM');
							foreach(@p in players_in_radius(location_shift(@loc, 'down'), 1.6)) {
								if(@p != player() && pmode(@p) !== 'SPECTATOR') {
									damage_entity(puuid(@p), 12, puuid());
									play_named_sound(ploc(), array(sound: 'entity.arrow.hit_player'), player());
								}
							}
						}
					} else if(@xp == 99) {
						play_named_sound(ploc(), array(sound: 'entity.warden.ambient', pitch: 2.0, volume: 2));
						clear_task();
					} else if(@xp < 17) {
						@center = location_shift(ploc(), 'up', 1.2);
						@radius = 16 / @xp;
						@r = rand() * 2;
						for(@angle = @r, @angle < 6.28 + @r, @angle += rand() * 2) {
							@point = array(
								@radius * cos(@angle) + @center['x'],
								@center['y'],
								@radius * sin(@angle) + @center['z'],
								@center['world'],
							);
							spawn_particle(@point, array(particle: 'SCULK_CHARGE_POP'));
						}
					}
				} catch(Exception @ex) {
					clear_task();
				}
			});
		}
	}
	
}

proc _class_powerup(@player) {
	set_pexp(@player, 99);
}

proc _class_unload(@player, @pvp) {
	foreach(@p in all_players()) {
		pshow_entity(@player, puuid(@p));
	}
	unbind(@player.'sculk');
	unbind(@player.'boom');
	unbind(@player.'sensor');
	try(entity_remove(@pvp['players'][@player]['entities']['sculk_sensor_first']))
	try(entity_remove(@pvp['players'][@player]['entities']['sculk_sensor_last']))
}
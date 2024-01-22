proc _class_load(@player, @pvp) {
	set_interval(1000, closure(){
		try {
			if(pmode(@player) == 'SPECTATOR'
			|| !array_index_exists(@pvp['players'], @player)
			|| @pvp['players'][@player]['class'] != 'keeper') {
				clear_task();
				die();
			}
			@loc = location_shift(ploc(@player), 'up', 3);
			if(!rand(8)) {
				play_named_sound(@loc, array(sound: 'entity.warden.ambient', pitch: 2.0));
			}
			foreach(@p in players_in_radius(@loc, 14)) {
				if(@p == @player) {
					continue();
				}
				if(!array_index_exists(get_peffect(@p), 'glowing')) {
					spawn_particle(@loc, array(particle: 'VIBRATION', destination: puuid(@p)));
					play_named_sound(@loc, array(sound: 'entity.warden.tendril_clicks', pitch: 1.2));
				}
				set_peffect(@p, 'glowing', 1, 2, true, false);
			}
			if(array_index_exists(@pvp['players'][@player]['entities'], 'sculk_sensor')) {
				try {
					@loc = location_shift(entity_loc(@pvp['players'][@player]['entities']['sculk_sensor']), 'up', 0.7);
					foreach(@p in players_in_radius(@loc, 14)) {
						if(@p == @player) {
							continue();
						}
						if(!array_index_exists(get_peffect(@p), 'glowing')) {
							spawn_particle(@loc, array(particle: 'VIBRATION', destination: puuid(@p)));
							play_named_sound(@loc, array(sound: 'entity.warden.tendril_clicks', pitch: 1.2));
						}
						set_peffect(@p, 'glowing', 1, 2, true, false);
					}
				} catch(BadEntityException @ex) {}
			}
		} catch(Exception @ex) {
			clear_task();
		}
	});

	bind('player_interact', array(id: @player.'sculk'), array(player: @player, button: 'right', itemname: 'SCULK_SENSOR', hand: 'main_hand'), @event, @pvp) {
		if(array_index_exists(@event, 'location') && @event['facing'] == 'up') {
			@loc = location_shift(@event['location'], 'up');
			if(get_block(@loc) == 'AIR') {
				if(array_index_exists(@pvp['players'][player()]['entities'], 'sculk_sensor')) {
					try {
						@sensor = @pvp['players'][player()]['entities']['sculk_sensor'];
						@oldLoc = entity_loc(@sensor);
						entity_remove(@sensor);
						spawn_particle(location_shift(@oldLoc, 'up', 0.78), array(particle: 'SCULK_CHARGE', count: 8, xoffset: 0.5, yoffset: 0.2, zoffset: 0.5));
					} catch(BadEntityException @ex) {}
				}
				@loc = _center(@loc, 0.2);
				spawn_particle(@loc, array(particle: 'SCULK_CHARGE', count: 8, xoffset: 0.5, yoffset: 0.2, zoffset: 0.5));
				play_named_sound(@loc, array(sound: 'block.sculk.place'));
				@loc = location_shift(@loc, 'down', 0.88);
				@pvp['players'][player()]['entities']['sculk_sensor'] = spawn_entity('ARMOR_STAND', 1, @loc, closure(@stand) {
					set_entity_spec(@stand, array(gravity: false, visible: false, small: true));
					set_mob_equipment(@stand, array(HELMET: array(name: 'SCULK_SENSOR')));
					add_scoreboard_tag(@stand, 'remove');
				})[0];
			}
		}
	}

	bind('player_toggle_sneak', array(id: @player.'boom'), array(player: @player, sneaking: true), @event) {
		if(pexp() == 99) {
			@center = location_shift(ploc(), 'up');
			@radius = 2;
			for(@angle = 0, @angle < 6.28, @angle += rand() / 3) {
				@point = array(
					@radius * cos(@angle) + @center['x'],
					@center['y'],
					@radius * sin(@angle) + @center['z'],
					@center['world'],
				);
				spawn_particle(@point, array(particle: 'SCULK_CHARGE'));
			}
			play_named_sound(ploc(), array(sound: 'entity.warden.sonic_charge'));
			set_pexp(0);
			set_interval(50, closure(){
				try {
					@xp = pexp();
					@xp = min(99, @xp + 1);
					set_pexp(@xp);
					if(@xp == 34) {
						if(!psneaking()) {
							clear_task();
							set_pexp(99);
							die();
						}
						@loc = location_shift(ploc(), 'up', 2.5);
						play_named_sound(@loc, array(sound: 'entity.warden.sonic_boom'));
						@v = get_vector(@loc);
						@i = 16;
						while(@i-- > 0) {
							@loc['x'] += @v['x'];
							@loc['y'] += @v['y'];
							@loc['z'] += @v['z'];
							spawn_particle(@loc, 'SONIC_BOOM');
							foreach(@p in players_in_radius(@loc, 1.5)) {
								damage_entity(puuid(@p), 16, puuid());
							}
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
	
}

proc _class_powerup(@player) {
	set_pexp(@player, 99);
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'sculk');
	unbind(@player.'boom');
	try(entity_remove(@pvp['players'][@player]['entities']['sculk_sensor']))
}
@pvp['binds'][] = bind('player_interact', null, array(itemname: 'ANVIL', button: 'right'), @event, @pvp) {
	if(!array_index_exists(@pvp['players'], player())) {
		die();
	}
	@taken = ptake_item(array(name: 'SLIME_BALL', qty: 1));
	if(@taken) {
		@entity = shoot_projectile(player(), 'SNOWBALL');
		set_projectile_item(@entity, array(name: 'SLIME_BALL'));
		@v = entity_velocity(@entity);
		@v['x'] = (@v['x'] / @v['magnitude']) * 2;
		@v['y'] = (@v['y'] / @v['magnitude']) * 2;
		@v['z'] = (@v['z'] / @v['magnitude']) * 2;
		set_entity_velocity(@entity, @v);
		play_sound(ploc(), array(sound: 'BLOCK_SLIME_BLOCK_HIT', volume: 2));
		play_sound(ploc(), array(sound: 'BLOCK_BONE_BLOCK_PLACE', pitch: 0.5, volume: 2));
	}
}

@pvp['binds'][] = bind('projectile_hit', null, array(type: 'SNOWBALL'), @event, @pvp) {
	@item = get_projectile_item(@event['id']);
	if(@item && @item['name'] == 'SLIME_BALL') {
		@v = entity_velocity(@event['id']);
		@loc = @event['location'];
		@loc['yaw'] = get_yaw(array(0, 0, 0), @v);
		@loc['pitch'] = get_pitch(array(0, 0, 0), @v);
		@trace = ray_trace(@event['shooter'], @loc, 4, 0.2);
		@hit = @trace['location'];
		@hitEntity = '';
		if(@trace['entities']) {
			@hit = @trace['entities'][0]['location'];
			@hitEntity = @trace['entities'][0]['uuid'];
			@entityPos = entity_loc(@hitEntity);
			@relativePos = array(
				x: @hit['x'] - @entityPos['x'],
				y: @hit['y'] - @entityPos['y'] - 0.75,
				z: @hit['z'] - @entityPos['z'],
				world: @hit['world'];
			);
			@hit['yaw'] = @loc['yaw'];
			@hit['pitch'] = @loc['pitch'];
		}
		play_sound(@hit, array(sound: 'BLOCK_SLIME_BLOCK_PLACE', pitch: 1.3));
		@slime = spawn_entity('ARMOR_STAND', 1, location_shift(@hit, 'down', 0.75), closure(@stand) {
			set_entity_spec(@stand, array(small: true, gravity: false, visible: false));
			set_mob_equipment(@stand, array(HELMET: array(name: 'SLIME_BLOCK')));
		})[0];

		@explode = closure(){
			try {
				@hit = location_shift(entity_loc(@slime), 'up', 0.75);
				entity_remove(@slime);

				spawn_particle(@hit, 'EXPLOSION_LARGE');
				play_sound(@hit, associative_array(sound: 'ENTITY_GENERIC_EXPLODE', volume: 3));

				foreach(@e in entities_in_radius(@hit, 5)) {
					if(entity_type(@e) == 'PLAYER' && pmode(@e) == 'SPECTATOR') {
						continue();
					}
					@eloc = location_shift(entity_loc(@e), 'up');
					@dist = distance(@hit, @eloc);
					if(is_entity_living(@e)) {
						damage_entity(@e, 7 / max(1, @dist - 1), puuid(@event['shooter']));
					}
					try {
						set_entity_velocity(@e, array(
							(@eloc['x'] - @hit['x']) / max(1, @dist ** 2),
							(@eloc['y'] - @hit['y']) / max(1, @dist ** 2),
							(@eloc['z'] - @hit['z']) / max(1, @dist ** 2)
						));
					} catch(BadEntityException @ex) {
						// blew completely off server
					}
				}

			} catch (BadEntityException @ex) {
				// doesn't exist, don't explode
			}
		}

		if(@hitEntity) {
			@ticks = array(40);
			set_interval(50, closure(){
				try {
					if(@ticks[0] > 10) {
						@entityPos = entity_loc(@hitEntity);
						if(@entityPos['world'] == @loc['world']) {
							@hit['x'] = @entityPos['x'] + @relativePos['x'];
							@hit['y'] = @entityPos['y'] + @relativePos['y'];
							@hit['z'] = @entityPos['z'] + @relativePos['z'];
							set_entity_loc(@slime, @hit);
						}
					} else if(@ticks[0] == 10) {
						set_entity_spec(@slime, array(gravity: true));
					}
					if(--@ticks[0] <= 0) {
						clear_task();
						execute(@explode);
					}
				} catch (BadEntityException @ex) {
					clear_task();
					execute(@explode);
				}
			});
		} else {
			set_timeout(2000, @explode);
		}
	}
}

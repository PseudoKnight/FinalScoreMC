proc _class_load(@player, @pvp) {
	bind('player_interact', array(id: @player.'lightning'), array(itemname: 'LIGHTNING_ROD', button: 'right', player: @player, hand: 'main_hand'), @e, @pvp) {
		if(pcooldown('LIGHTNING_ROD')) {
			die();
		}
		@trace = ray_trace(player(), 96);
		@loc = @trace['location'];
		foreach(@entity in @trace['entities']) {
			if(!ponline(@entity['uuid']) || pmode(@entity['uuid']) != 'SPECTATOR') {
				@loc = @trace['entities'][0]['location'];
				break();
			}
		}

		lightning(location_shift(@loc, 'down', 0.1), true);
		foreach(@p in array_keys(@pvp['players'])) {
			@l = ploc(@p);
			@y = @l['y'] + 1;
			@l['y'] = @loc['y'];
			if(distance(@loc, @l) <= 3) {
				@l['y'] = @y;
				if(@y >= @loc['y'] || distance(@l, @loc) <= 3) {
					@l['y'] += 1;
					damage_entity(puuid(@p), 7.4, puuid());
					set_peffect(@p, 'SLOWNESS', 2, 1.5, true, false);
					spawn_particle(@l, array(particle: 'ELECTRIC_SPARK', count: 30, xoffset: 2, yoffset: 3, zoffset: 2, force: true));
					set_pvelocity(@p, array(0, 0, 0));
				}
			}
		}

		@slot = pheld_slot();
		@item = pinv(player(), null);
		set_pinv(player(), null, array(name: 'LIGHTNING_ROD'));
		set_pcooldown('LIGHTNING_ROD', 8000 / 50);
		queue_clear(player().'lightning');
		queue_delay(8000, player().'lightning');
		queue_push(closure(){
			if(!ponline(@e['player'])) {
				return();
			}
			@newitem = pinv(player(), @slot);
			if(!is_null(@newitem) && !@newitem['meta']) {
				set_pinv(player(), @slot, @item);
				play_sound(ploc(), array(sound: 'BLOCK_FIRE_EXTINGUISH', volume: 4));
			}
		}, player().'lightning');
	}

	bind('player_interact', array(id: @player.'woosh'), array(itemname: 'FEATHER', button: 'right', player: @player, hand: 'main_hand'), @event, @pvp) {
		_weapon_cooldown(player(), 6000, 'INK_SAC', false, 0);

		@loc1 = location_shift(ploc(), 'up');
		play_sound(@loc1, array(sound: 'ENTITY_ENDER_DRAGON_FLAP', pitch: 0.5));
		play_sound(@loc1, array(sound: 'ENTITY_GHAST_SHOOT', pitch: 0.9));
		spawn_particle(location_shift(@loc1, 'up'), array(
			particle: 'CLOUD',
			count: 80,
			speed: 0.5,
			force: true,
		));

		@excludeEntities = array('COMPLEX_PART', 'GLOW_ITEM_FRAME', 'ITEM_FRAME', 'PAINTING', 'ITEM_DISPLAY', 'BLOCK_DISPLAY', 'TEXT_DISPLAY', 'UNKNOWN');
		foreach(@entity in entities_in_radius(@loc1, 10)) {
			@force = 1.4;
			@type = entity_type(@entity);
			if(@type == 'PLAYER') {
				@player = player(@entity);
				if(@player == player() || pmode(@player) == 'SPECTATOR') {
					continue();
				}
				if(entity_grounded(@entity) && psneaking(@player)) {
					@force *= 0.5;
				}
				if(pblocking(@player)) {
					@force *= 0.5;
				}
				if(array_index_exists(@pvp, 'teams') && @pvp['players'][player()]['team'] == @pvp['players'][@player]['team']) {
					@force *= 0.5;
				}
			} else if(@type == 'ARMOR_STAND') {
				@spec = entity_spec(@entity);
				if(@spec['visible'] || @spec['marker']) {
					continue();
				}
			} else if(array_contains(@excludeEntities, @type)) {
				continue();
			} else {
				@force *= 0.6;
			}
			@loc2 = entity_loc(@entity);
			@loc2['y'] += 1.0;
			@dist = distance(@loc1, @loc2);

			if(!entity_can_see(puuid(), @entity)) {
				@force *= 0.5;
			}

			if(is_entity_living(@entity)) {
				damage_entity(@entity, 1.2, puuid());
			}

			# if we use a queue, velocity works more consistently with grounded entities
			queue_push(closure(){
				try {
					set_entity_velocity(@entity, array(
						@force * ((@loc2['x'] - @loc1['x']) / @dist), # vector normalization
						min(max((@loc2['y'] - @loc1['y']) / @dist, 0.15), @force), # clamp to an upwards vector
						@force * ((@loc2['z'] - @loc1['z']) / @dist),
					));
				} catch(BadEntityException @ex) {
					// they logged off or entity dead; feather OP
				}
			});
		}
	}

	bind('player_interact', array(id: @player.'freeze'), array(itemname: 'SOUL_TORCH', button: 'right', player: @player, hand: 'main_hand'), @e, @pvp) {
		if(pcooldown('SOUL_TORCH')) {
			die();
		}
		set_pcooldown('SOUL_TORCH', 8000 / 50);

		@radius = 5;
		@trace = ray_trace(player(), 96);
		@origin = @trace['origin'];
		@loc = @trace['location'];
		play_sound(@origin, array(sound: 'ENTITY_GLOW_SQUID_SQUIRT', pitch: 0.8));
		@count = array(96);
		set_interval(50, closure() {
			@count[0]--;
			@trace = ray_trace(location_shift(@origin, @loc), 0.8);
			@origin['x'] = @trace['origin']['x'];
			@origin['y'] = @trace['origin']['y'];
			@origin['z'] = @trace['origin']['z'];
			@loc['x'] = @trace['location']['x'];
			@loc['y'] = @trace['location']['y'];
			@loc['z'] = @trace['location']['z'];
			spawn_particle(@loc, array(particle: 'SNOWFLAKE', count: 5, xoffset: 0.3, yoffset: 0.3, zoffset: 0.3, force: true));
			spawn_particle(@loc, array(particle: 'SOUL_FIRE_FLAME', force: true));
			@hit = false;
			if(@trace['entities']) {
				foreach(@entity in @trace['entities']) {
					if(@entity['uuid'] != puuid() && (!ponline(@entity['uuid']) || pmode(@entity['uuid']) != 'SPECTATOR')) {
						@hit = true;
						@loc = @entity['location'];
					}
				}
			}
			if(!@hit && !@trace['hitblock']) {
				if(@count[0] <= 0) {
					clear_task();
				}
				return();
			}
			spawn_particle(@loc, array(particle: 'SNOWFLAKE', count: integer(@radius ** 3), xoffset: @radius * 1.5, yoffset: @radius * 1.5, zoffset: @radius * 1.5, speed: 0.01, force: true));
			spawn_particle(@loc, array(particle: 'SOUL_FIRE_FLAME', count: integer(@radius ** 2), xoffset: @radius, yoffset: @radius, zoffset: @radius, force: true));
			play_sound(@loc, array(sound: 'ENTITY_ZOMBIE_VILLAGER_CURE', volume: 2));
			foreach(@p in array_keys(@pvp['players'])) {
				if(pmode(@p) != 'SPECTATOR') {
					@ploc = location_shift(ploc(@p), 'up', 2);
					@dist = distance(@loc, @ploc);
					if(@dist < @radius) {
						set_peffect(@p, 'WEAKNESS', 0, 7.5 / max(1, @dist));
						set_peffect(@p, 'MINING_FATIGUE', 0, 7.5 / max(1, @dist));
						set_peffect(@p, 'GLOWING', 0, 7.5 / max(1, @dist));
						damage_entity(puuid(@p), 1, puuid());
						set_entity_freezing(puuid(@p), integer(300 / max(1, @dist)));
					}
				}
			}
			clear_task();
		});
	}
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'lightning');
	unbind(@player.'woosh');
	unbind(@player.'freeze');
}

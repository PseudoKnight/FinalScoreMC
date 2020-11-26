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
		if(@item && @item['name'] == 'DIAMOND_BLOCK' && !pcooldown('DIAMOND_BLOCK')) {
			set_pcooldown('DIAMOND_BLOCK', 20);

			@hitplayers = _weapon_hit_scan(player(), 90, 0.6, null, array(
				tracerparticle: 'REDSTONE',
				hitsound: array(sound: 'ENTITY_PUFFER_FISH_BLOW_OUT', pitch: 0.5)
			), @pvp);
			if(!@hitplayers) {
				die();
			}
			@target = puuid(@hitplayers[0]);

			set_pinv(player(), @slot, null);
			@loc = location_shift(ploc(), 'up', 1.55);
			@box = spawn_entity('ARMOR_STAND', 1, @loc, closure(@e) {
				set_mob_equipment(@e, array(HELMET: @item));
				set_entity_spec(@e, array(
					gravity: false,
					visible: false,
					small: true,
					poses: array(
						poseHead: array(3.14159, 0, 0)
					)
				));
			})[0];

			@returnToSender = closure(){
				if(ponline(player()) && pmode() != 'SPECTATOR' && array_index_exists(@pvp['players'], player())) {
					set_pinv(player(), @slot, @item);
				}
				play_sound(ploc(), array(sound: 'ENTITY_PUFFER_FISH_BLOW_UP', pitch: 0.5), player());
			}

			@explode = closure(@loc) {
				foreach(@p in players_in_radius(@loc, 4)) {
					damage_entity(puuid(@p), 7 - distance(location_shift(ploc(@p), 'up', 2), @loc), puuid())
				}
				spawn_particle(@loc, 'EXPLOSION_LARGE');
				play_sound(@loc, array(sound: 'ENTITY_GENERIC_EXPLODE'));
				entity_remove(@box);
			}

			set_interval(50, closure(){
				try {
					if(get_entity_health(@target) <= 0
					|| !ponline(player())
					|| pmode() == 'SPECTATOR'
					|| !array_index_exists(@pvp['players'], player())) {
						clear_task();
						execute(@returnToSender);
						// Self-detonate missile
						try(execute(entity_loc(@box), @explode));
					} else {
						@loc = entity_loc(@box);
						spawn_particle(location_shift(@loc, 'up', 0.35), 'CAMPFIRE_COSY_SMOKE');
						@targetLoc = location_shift(entity_loc(@target), 'up');
						@newLoc = location_shift(@loc, @targetLoc, 0.5);
						if(get_block_info(location_shift(@newLoc, 'up', 0.5), 'solid') || distance(@newLoc, @targetLoc) < 1) {
							clear_task();
							set_entity_loc(@box, @newLoc);
							set_timeout(500, @returnToSender);
							execute(@newLoc, @explode);
						} else {
							set_entity_loc(@box, @newLoc);
							play_sound(@loc, array('sound': 'ENTITY_GUARDIAN_ATTACK', 'pitch': 2.0));
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
			if(@helmet && @helmet['name'] == 'DIAMOND_BLOCK') {
				consume();
				@loc = entity_loc(@event['id']);
				foreach(@p in players_in_radius(@loc, 4)) {
					damage_entity(puuid(@p), 8 - distance(location_shift(ploc(@p), 'up', 2), @loc), puuid());
				}
				spawn_particle(@loc, 'EXPLOSION_LARGE');
				play_sound(@loc, array(sound: 'ENTITY_GENERIC_EXPLODE'));
				entity_remove(@event['id']);
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
					clear_task();
					set_pexp(0);
					@loc = location_shift(ploc(), 'up', 1.5);
					play_sound(@loc, array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED'));

					@radius = 5;
					@circle = array();
					for(@angle = 0, @angle < 6.28, @angle += 0.3) {
						@circle[] = array(
							'x': @radius * cos(@angle) + @loc['x'],
							'y': @loc['y'],
							'z': @radius * sin(@angle) + @loc['z'],
							'world': @loc['world'],
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
							explosion(@hitLoc, 2, true);
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
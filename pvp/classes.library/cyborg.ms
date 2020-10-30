switch(@action) {
case 'load':
	bind('player_interact', array(id: @player.'cyborgmissiles'), array(player: @player), @event, @pvp) {
		@slot = 0;
		if(@event['button'] == 'left') {
			@slot = -106;
		}
		@item = pinv(player(), @slot);
		if(@item && @item['name'] == 'DIAMOND_BLOCK' && !pcooldown('DIAMOND_BLOCK')) {
			set_pcooldown('DIAMOND_BLOCK', 10);
			@loc = location_shift(ploc(), 'up');

			@trace = ray_trace(player(), 90, 0.5);
			@target = '';
			foreach(@entity in @trace['entities']) {
				if(ponline(@entity['uuid'])) {
					@target = @entity['uuid'];
				}
			}
			if(!@target) {
				play_sound(@loc, array(sound: 'BLOCK_NOTE_BLOCK_BIT', pitch: 0.6));
				die();
			}

			play_sound(@loc, array(sound: 'BLOCK_NOTE_BLOCK_BIT', pitch: 1.5));
			set_timeout(200, closure(play_sound(@loc, array(sound: 'BLOCK_NOTE_BLOCK_BIT', pitch: 1.5))));
			set_pinv(player(), @slot, null);

			@loc = location_shift(ploc(), 'up', 1.5);
			@box = spawn_entity('ARMOR_STAND', 1, @loc, closure(@e) {
				set_mob_equipment(@e, array('WEAPON': @item));
				set_entity_spec(@e, array(
					gravity: false,
					visible: false,
					small: true,
				));
			});

			@returnToSender = closure(){
				if(ponline(player()) && pmode() != 'SPECTATOR' && array_index_exists(@pvp['players'], player())) {
					set_pinv(player(), @slot, @item);
				}
				try {
					entity_remove(@box);
				} catch(BadEntityException @ex) {
					// Destroyed.
				}
			}

			set_interval(50, closure(){
				try {
					if(get_entity_health(@target) <= 0
					|| !ponline(player())
					|| pmode() == 'SPECTATOR'
					|| !array_index_exists(@pvp['players'], player())) {
						clear_task();
						execute(@returnToSender);
					} else {
						@loc = entity_loc(@box);
						@targetLoc = location_shift(entity_loc(@target), 'up');
						@newLoc = location_shift(@loc, @targetLoc, 0.4);
						if(get_block_info(location_shift(@newLoc, 'up'), 'solid') || distance(@loc, @targetLoc) < 1) {
							clear_task();
							execute(@returnToSender);
							explosion(@loc, 1, true);
						} else {
							set_entity_loc(@box, @newLoc);
							play_sound(@loc, array('sound': 'ENTITY_GUARDIAN_ATTACK'));
						}
					}
				} catch(Exception @ex) {
					clear_task();
					execute(@returnToSender);
				}
			});
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
					set_pexp(min(99, @xp + 3));
					play_sound(@loc, array(sound: 'BLOCK_NOTE_BLOCK_BIT', volume: 0.5, pitch: 0.52 + 1.48 * (@xp / 99)), player());
				} else {
					clear_task();
					set_pexp(0);
					@loc = location_shift(ploc(), 'up', 1.5);
					play_sound(@loc, array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED'));
					@timer = array(5);
					set_interval(500, closure(){
						@timer[0]--;
						if(@timer[0] < -10) {
							clear_task();
						} else if(@timer[0] < 0) {
							@hitLoc = @loc[];
							@hitLoc['x'] += rand() * 8 - 4;
							@hitLoc['z'] += rand() * 8 - 4;
							explosion(@hitLoc, 2, true);
							@particle = array(particle: 'REDSTONE', color: 'WHITE');
							while(@hitLoc['y'] < @loc['y'] + 32) {
								@hitLoc['y'] += 0.1 + (@hitLoc['y'] - @loc['y']) * 0.1;
								spawn_particle(@hitLoc, @particle);
							}
						} else {
							@targetLoc = @loc[];
							while(@targetLoc['y'] < @loc['y'] + 32) {
								@targetLoc['y'] += 0.6;
								spawn_particle(@targetLoc, 'REDSTONE');
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
	unbind(@player.'cyborgmissiles');
	unbind(@player.'cyborgsneak');
	
}
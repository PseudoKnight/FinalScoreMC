proc _class_load(@player, @pvp) {
	proc _set_equipment(@player, @thorns, @pvp) {
		if(array_index_exists(@pvp['players'], @player) && @pvp['players'][@player]['class'] == 'ent') {
			@kit = array(
				helmet: array(name: 'SPRUCE_LOG'),
				chestplate: array(name: 'LEATHER_CHESTPLATE', meta: array(
					color: array(r: 0, g: 50, b: 0),
				)),
				leggings: array(name: 'LEATHER_LEGGINGS', meta: array(
					color: array(r: 58, g: 28, b: 1),
				)),
				boots: array(name: 'LEATHER_BOOTS', meta: array(
					color: array(r: 58, g: 28, b: 1),
				)),
			);
			if(@thorns) {
				@enchants = array(thorns: array(elevel: 13));
				foreach(@item in @kit) {
					@item['meta']['enchants'] = @enchants;
				}
				set_peffect(@player, 'RESISTANCE', 0, 999);
			} else {
				set_peffect(@player, 'RESISTANCE', 0, 0);
			}
			set_mob_equipment(puuid(@player), @kit);
		}
	}

	bind('item_held', array(id: @player.'entbark'), null, @event, @player, @pvp) {
		if(@player == player() && (@event['to'] == 1 && pinv(player(), 1) || @event['from'] == 1)) {
			_set_equipment(player(), @event['to'] == 1, @pvp);
		}
	}
	
	bind('entity_damage', array(id: @player.'entdamage', priority: 'MONITOR'), array(id: puuid(@player)), @event, @player, @pvp) {
		if(pheld_slot(@player) == 1) {
			@item = pinv(@player, 1);
			if(@item) {
				@item['qty']--;
				if(@item['qty'] == 0) {
					set_pinv(@player, 1, null);
					_set_equipment(@player, false, @pvp);
				} else {
					set_pinv(@player, 1, @item);
				}
			}
		}
	}

	bind('entity_damage', array(id: @player.'entfall'), array(id: puuid(@player), cause: 'FALL'), @event, @player, @pvp) {
		@damage = @event['amount'];
		@target = entity_loc(@event['id']);
		@world = @target['world'];
		
		modify_event('amount', @damage * 0.1);
		foreach(@p in players_in_radius(@target, 6)) {
			if(@p != @player && array_index_exists(@pvp['players'], @p) && pmode(@p) != 'SPECTATOR') {
				damage_entity(puuid(@p), @damage, puuid(@player));
			}
		}
		play_sound(@target, array(sound: 'ENTITY_WITHER_BREAK_BLOCK', pitch: 0.7));
		
		@radius = 6;
		@circle = array();
		for(@angle = 0, @angle < 6.28, @angle += 0.5) {
			@circle[] = array(
				@radius * cos(@angle) + @target['x'],
				@target['y'],
				@radius * sin(@angle) + @target['z'],
				@world,
			);
		}
		
		foreach(@point in @circle) {
			if(get_block(@point) == 'AIR') {
				@block = get_block(location_shift(@point, 'down'));
				if(@block != 'AIR') {
					spawn_particle(@point, array(particle: 'BLOCK_CRACK', block: @block, count: 5));
					foreach(@p in all_players(@world)) {
						psend_block_change(@p, @point, 'DEAD_BUSH');
					}
				}
			}
		}
		
		set_timeout(1000, closure(){
			foreach(@point in @circle) {
				@block = get_block(@point);
				if(@block == 'AIR') {
					foreach(@p in all_players(@world)) {
						psend_block_change(@p, @point, @block);
					}
				}
			}
		});
	}
	
	bind('player_toggle_sneak', array(id: @player.'entsneak'), array(player: @player, sneaking: true), @event, @pvp) {
		if(pheld_slot() != 0) {
			die();
		}
		set_pexp(0);
		@loc = ploc();
		play_sound(@loc, array(sound: 'ENTITY_ILLUSIONER_PREPARE_BLINDNESS', pitch: 0.7));
		play_sound(@loc, array(sound: 'ENTITY_HUSK_AMBIENT', pitch: 0.8));
		add_entity_attribute_modifier(puuid(), array(
			attribute: 'GENERIC_KNOCKBACK_RESISTANCE',
			operation: 'ADD_NUMBER',
			amount: 1,
			id: 'commandhelper:ent'));
		set_interval(100, closure(){
			try {
				if(!psneaking() || pheld_slot() != 0) {
					clear_task();
					set_pexp(0);
					remove_entity_attribute_modifier(puuid(), 'GENERIC_KNOCKBACK_RESISTANCE', 'commandhelper:ent');
					die();
				}
				@xp = pexp();
				if(@xp < 99) {
					set_pexp(min(99, @xp + 3));
				} else {
					clear_task();
					set_pexp(0);
					remove_entity_attribute_modifier(puuid(), 'GENERIC_KNOCKBACK_RESISTANCE', 'commandhelper:ent');
					@players = _weapon_hit_scan(player(), array(range: 13, raySize: 0.2), 2, array(tracer: 'VILLAGER_HAPPY'), @pvp);
					@loc = ploc();
					if(@players) {
						@p = @players[0];
						play_sound(@loc, array(sound: 'BLOCK_CHEST_OPEN', pitch: 0.6));
						@timer = array(20);
						set_interval(50, closure(){
							@timer[0]--;
							try {
								if(@timer[0] <= 0) {
									clear_task();
									@facing = pfacing(player());
									@facing[0] = @facing[0] + 90;
									@facing[1] = 0 - @facing[1];
									@x = 1.60 * cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
									@y = max((1.60 * sin(to_radians(@facing[1]))) + 0.2, 0.2);
									@z = 1.60 * sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
									set_pvelocity(@p, @x, @y, @z);
									@loc = ploc();
									play_sound(@loc, array(sound: 'entity_player_attack_sweep', pitch: 1.4));
									play_sound(@loc, array(sound: 'entity_snowball_throw', pitch: 0.52));
								} else {
									set_ploc(@p, location_shift(ploc(), 'up', 2));
								}
							} catch(PlayerOfflineException @ex) {
								clear_task();
							}
						});
					} else {
						play_sound(@loc, array(sound: 'entity_player_attack_sweep', pitch: 1.4));
						play_sound(@loc, array(sound: 'entity_snowball_throw', pitch: 0.52));
					}
				}
			} catch(PlayerOfflineException @ex) {
				clear_task();
			}
		});
	}
	
	bind('player_death', array(id: @player.'entdeath'), array(player: @player), @event) {
		drop_item(@event['location'], array(name: 'APPLE'), true);
		play_sound(@event['location'], array(sound: 'ENTITY_HUSK_DEATH', pitch: 0.5));
	}
	
	bind('player_interact', array(id: @player.'entattack'), array(player: @player, itemname: 'OAK_LEAVES', hand: 'main_hand', button: 'right'), @event) {
		if(!pcooldown('LEAVES')) {
			@loc = ptarget_space();
			if(get_block(location_shift(@loc, 'down')) != 'AIR') {
				set_pcooldown('OAK_LEAVES', 5);
				@loc['x'] += 0.5;
				@loc['z'] += 0.5;
				play_sound(@loc, array(sound: 'ENTITY_WITHER_BREAK_BLOCK', pitch: 1.5, volume: 0.7));
				play_sound(ploc(), array(sound: 'ENTITY_PLAYER_ATTACK_SWEEP', pitch: 2));
				foreach(@p in all_players(pworld())) {
					if(@p == player()) {
						set_timeout(1, closure(){
							psend_block_change(player(), @loc, 'DEAD_BUSH');
						});
					} else {
						psend_block_change(@p, @loc, 'DEAD_BUSH');
					}
				}
				foreach(@p in players_in_radius(@loc, 1)) {
					damage_entity(puuid(@p), 3.5, puuid());
				}
				set_timeout(1000, closure(){
					foreach(@p in all_players(pworld())) {
						psend_block_change(@p, @loc, 'AIR');
					}
				});
			}
		}
	}
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'entfall');
	unbind(@player.'entsneak');
	unbind(@player.'entbark');
	unbind(@player.'entdamage');
	unbind(@player.'entdeath');
	unbind(@player.'entattack');
	remove_entity_attribute_modifier(puuid(), 'GENERIC_KNOCKBACK_RESISTANCE', 'commandhelper:ent');
}

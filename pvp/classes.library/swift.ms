switch(@action) {
case 'load':
	proc _swift_grab(@swift, @entity) {
		if(!get_entity_vehicle(puuid(@swift)) && !get_entity_rider(puuid(@swift))) {
			set_entity_rider(puuid(@swift), @entity);
			play_sound(ploc(@swift), array('sound': 'GHAST_SCREAM2', 'pitch': 1.6 + (rand(5) / 10)));
			set_timeout(200, closure(){
				play_sound(ploc(@swift), array('sound': 'GHAST_SCREAM2', 'pitch': 1.6 + (rand(5) / 10)));
			});
			return(true);
		}
	}

	bind(entity_damage, array('id': @player.'grab'), array('type': 'PLAYER', 'cause': 'ENTITY_ATTACK'), @e, @pvp, @player) {
		if(@e['damager'] == @player && get_entity_vehicle(puuid(@player)) != @e['id']) {
			if(get_entity_vehicle(puuid(@player)) == @e['id']) {
				cancel();
			} else if(_swift_grab(@player, puuid(@e['player']))) {
				modify_event('amount', 3);
			}
		}
	}

	bind(player_interact_entity, array('id': @player.'clickgrab'), array('clicked': 'PLAYER'), @e, @player) {
		if(@e['player'] == @player) {
			_swift_grab(@player, @e['id']);
		}
	}

	set_pexp(@player, 0);
	bind(player_interact, array('id': @player.'boost'), array('item': 420, 'player': @player, 'button': 'right'), @e) {
		if(pexp() > 0) {
			die();
		}
		set_pexp(99);
		if(psaturation() > 0) {
			set_psaturation(psaturation() - 1);
		} else {
			set_phunger(max(0, phunger() - 1));
		}
		@uuid = puuid();
		@grounded = entity_grounded(@uuid);
		@closure = closure(@grounded){
			@v = entity_velocity(@uuid);
			@facing = pfacing();
			@nv = _get_vector(@facing[0], @facing[1], 1, if(@grounded, 0.6, 0));
			@v['x'] += @nv['x'];
			@v['y'] += @nv['y'];
			@v['z'] += @nv['z'];
			@magnitude = _distance(associative_array('x': 0, 'y': 0, 'z': 0), @v);
			@v['x'] = (@v['x'] / @magnitude) * 1.1;
			@v['y'] = (@v['y'] / @magnitude) * 1.1;
			@v['z'] = (@v['z'] / @magnitude) * 1.1;
			set_entity_velocity(@uuid, @v);
			play_sound(ploc(), array('sound': 'BAT_TAKEOFF', 'volume': 0.5));
			set_timeout(150, closure(){
				set_entity_gliding(@uuid, true);
			});
		}
		if(@grounded) {
			set_timeout(50, closure(){
				execute(@grounded, @closure);
			});
		} else {
			execute(@grounded, @closure);
		}
		set_timeout(500, closure(){
			set_pexp(0);
		});
	}

	/*
	set_pexp(@player, 0);
	bind(player_interact, array('id': @player.'boost'), array('item': 420, 'player': @player, 'button': 'right'), @e, @pvp) {
		if(pexp() > 0) {
			die();
		}
		set_pexp(99);
		set_phunger(max(0, phunger() - 1));
		@uuid = puuid();
		@grounded = entity_grounded(@uuid);
		@closure = closure(){
			@v = entity_velocity(@uuid);
			@facing = pfacing();
			@nv = _get_vector(@facing[0], @facing[1], 1, if(@grounded, 0.7, 0));
			@v['x'] += @nv['x'];
			@v['y'] += @nv['y'];
			@v['z'] += @nv['z'];
			@magnitude = _distance(associative_array('x': 0, 'y': 0, 'z': 0), @v);
			@v['x'] = (@v['x'] / @magnitude) * 1.1;
			@v['y'] = (@v['y'] / @magnitude) * 1.1;
			@v['z'] = (@v['z'] / @magnitude) * 1.1;
			set_entity_velocity(@uuid, @v);
			play_sound(ploc(), array('sound': 'BAT_TAKEOFF', 'volume': 0.5));
			set_timeout(150, closure(){
				set_entity_gliding(@uuid, true);
			});
		}
		if(@grounded) {
			set_timeout(50, @closure);
		} else {
			execute(@closure);
			@players = _hit_scan(14, 0, 'MAGIC_CRIT', 'NOTE', @pvp);
			if(@players){
				play_sound(ploc(), array('sound': 'GHAST_SCREAM2', 'pitch': 1.6));
				@target = @players[0];
				set_interval(50, closure(){
					@loc = _relative(ploc(), 'down', 1.5);
					@dist = _distance(@loc, ploc(@target));
					if(@dist < 4) {
						@stand = spawn_entity('ARMOR_STAND', 1, @loc)[0];
						set_entity_spec(@stand, associative_array('marker': true, 'visible': false));
						set_entity_rider(@stand, puuid(@target));
						clear_task();
						play_sound(@loc, array('sound': 'GHAST_SCREAM2', 'pitch': 2));
						damage_entity(puuid(@target), 3, puuid());
						set_interval(50, closure(){
							try {
								@loc = ploc();
								if(!get_entity_rider(@stand) || entity_grounded(puuid())){
									play_named_sound(ploc(), array('sound': 'item.armor.equip_leather'));
									clear_task();
									entity_remove(@stand);
									if(pinfo(@target, 5) > 0) {
										set_ploc(@target, @loc);
										set_pvelocity(@target, entity_velocity(puuid()));
									}
								} else {
									set_entity_loc(@stand, @loc);
									@v = entity_velocity(puuid());
									@v['x'] *= 1.1;
									@v['y'] *= 1.1;
									@v['z'] *= 1.1;
									set_entity_velocity(@stand, @v);
								}
							} catch(BadEntityException @ex) {
								clear_task();
							}
						});
					} else if(pexp() > 0) {
						clear_task();
					}
				});
			}
		}
		set_timeout(700, closure(){
			set_pexp(0);
		});
	}
	*/

	bind(player_toggle_sneak, array('id': @player.'sneak'), array('sneaking': true), @e, @player) {
		@uuid = puuid();
		if(@player == @e['player']) {
			@rider = get_entity_rider(@uuid);
			if(@rider) {
				set_entity_rider(@uuid, null);
				@v = entity_velocity(@uuid);
				@v['x'] *= 2;
				@v['y'] *= 1.5;
				@v['z'] *= 2;
				set_entity_velocity(@rider, @v);
			}
		}
	}

case 'powerup':
	set_phunger(@player, min(20, phunger(@player) + 4));

case 'unload':
	unbind(@player.'grab');
	unbind(@player.'boost');
	unbind(@player.'sneak');
	unbind(@player.'damage');
	unbind(@player.'clickgrab');

}

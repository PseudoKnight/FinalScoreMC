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

	bind(entity_damage, array('id': @player.'grab'), array('type': 'PLAYER', 'cause': 'ENTITY_ATTACK', 'world': 'custom'), @e, @pvp, @player) {
		if(@e['damager'] == @player && get_entity_vehicle(puuid(@player)) != @e['id']) {
			if(_swift_grab(@player, puuid(@e['player']))) {
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
		set_pexp(100);
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
			set_timeout(100, closure(){
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

	bind(player_toggle_sneak, array('id': @player.'sneak'), array('sneaking': true), @e, @player) {
		@uuid = puuid();
		if(@player == @e['player']) {
			@rider = get_entity_rider(@uuid);
			if(@rider) {
				set_entity_rider(@uuid, null);
				@v = entity_velocity(@uuid);
				@v['x'] *= 3;
				@v['y'] *= 1.6;
				@v['z'] *= 3;
				set_timeout(50, closure(){
					set_entity_rider(@uuid, null);
					set_entity_velocity(@rider, @v);
				});
			}
		} else {
			@vehicle = get_entity_vehicle(@uuid);
			if(@vehicle && @vehicle == puuid(@player)) {
				set_entity_rider(@vehicle, null);
				@v = entity_velocity(@vehicle);
				@v['x'] *= 3;
				@v['y'] *= 1.6;
				@v['z'] *= 3;
				set_timeout(50, closure(){
					set_entity_rider(@vehicle, null);
					set_entity_velocity(@uuid, @v);
				});
			}
		}
	}

case 'powerup':
	set_phunger(@player, min(20, phunger(@player) + 2));
	set_psaturation(@player, psaturation(@player) + 2);

case 'unload':
	unbind(@player.'grab');
	unbind(@player.'boost');
	unbind(@player.'sneak');
	unbind(@player.'damage');
	unbind(@player.'clickgrab');

}

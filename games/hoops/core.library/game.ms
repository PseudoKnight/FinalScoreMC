include('player.ms');
include('ball.ms');

proc _hoops_create() {
	@coords = sk_region_info('hoops', pworld(), 0);
	@center = array(
		(@coords[1][0] + (@coords[0][0] - @coords[1][0]) / 2) + 0.5,
		@coords[1][1],
		(@coords[1][2] + (@coords[0][2] - @coords[1][2]) / 2) + 0.5,
		pworld(),
	)
	@game = array(
		'teams': array(
			'red': array(
				'name': '',
				'score': 0,
				'players': array(),
			),
			'blue': array(
				'name': '',
				'score': 0,
				'players': array(),
			),
		),
		'ball': '',
		'slime': '',
		'holder': '',
		'lastholder': '',
		'players': associative_array(),
		'state': 0,
		'world': pworld(),
		'center': @center,
		'trail': false,
		'possession': '',
		'possessionLoc': null,
		'coords': @coords,
		'villagers': array(),
		'shootLoc': null,
	);
	export('hoops', @game);
	create_bar('hoops', array('percent': 0.0, 'style': 'SEGMENTED_6'));
}

proc _hoops_add_players() {
	@count = 0;
	@invitations = array();
	foreach(@p in all_players(pworld())) {
		if(array_contains(sk_current_regions(@p), 'hoops')) {
			_hoops_player_add(@p);
			@count++;
		} else {
			@invitations[] = @p;
		}
	}
	_click_tell(@invitations, array('&7[Hoops]&r Starting... ', array('&b[Click to Warp]', '/warp hoops')));
	return(@count);
}

proc _hoops_equip_players() {
	@game = import('hoops');
	foreach(@i: @p in array_keys(@game['players'])) {
		if(ponline(@p) && pworld(@p) == @game['world']) {
			_hoops_player_set_team(@p, array_size(@game['players']) - @i - 1);
			_hoops_player_equip(@p);
		} else {
			_hoops_player_remove(@p);
		}
	}
}

proc _hoops_queue() {
	@game = import('hoops');
	@game['state'] = 1;

	@startTime = time();
	set_interval(1000, closure() {
		@countdown = 5 - integer((time() - @startTime) / 1000);
		if(@countdown <= 0) {
			clear_task();
			_hoops_start();
		} else {
			foreach(@p in array_keys(@game['players'])) {
				title(@p, @countdown, null, 0, 20, 20);
			}
			@count = 10;
			while(@count-- > 0) {
				@randomLoc = array(
					0.0,
					@game['coords'][1][1],
					0.0,
					@game['world'],
					0.0,
					0.0,
				);
				switch(rand(4)) {
					case 0:
						@randomLoc[0] = @game['coords'][0][0] + 1;
						@randomLoc[2] = rand(@game['coords'][1][2], @game['coords'][0][2]);
					case 1:
						@randomLoc[0] = @game['coords'][1][0] - 1;
						@randomLoc[2] = rand(@game['coords'][1][2], @game['coords'][0][2]);
					case 2:
						@randomLoc[0] = rand(@game['coords'][1][0], @game['coords'][0][0]);
						@randomLoc[2] = @game['coords'][0][2] + 1;
					case 3:
						@randomLoc[0] = rand(@game['coords'][1][0], @game['coords'][0][0]);
						@randomLoc[2] = @game['coords'][1][2] - 1;
				}
				if(get_block(location_shift(@randomLoc, 'down')) != 'AIR'
				&& !entities_in_radius(@randomLoc, 1, 'VILLAGER')) {
					@randomLoc = _center(@randomLoc, 0);
					@randomLoc[4] = get_yaw(@randomLoc, @game['center']);
					@villager = spawn_entity('VILLAGER', 1, @randomLoc)[0];
					set_entity_ai(@villager, false);
					set_entity_silent(@villager, true);
					@game['villagers'][] = @villager;
				}
			}
		}
	});
}

proc _hoops_start() {
	@game = import('hoops');
	@game['state'] = 2;
	
	@startTime = time();

	set_interval(1000, 0, closure(){
		if(@game['state'] == 3) {
			clear_task();
			die();
		}
		foreach(@p in all_players(@game['world'])) {
			@inRegion = array_contains(sk_current_regions(@p), 'hoops');
			if(array_index_exists(@game['players'], @p)) {
				if(!@inRegion) {
					_hoops_player_remove(@p);
				}
			} else if(@inRegion) {
				_hoops_player_add(@p);
			}
		}
		foreach(@p in array_keys(@game['players'])) {
			if(!ponline(@p)) {
				_hoops_player_remove(@p);
			}
		}
		
		@timeLeft = 5 * 60 * 1000 - (time() - @startTime);
		
		update_bar('hoops', color('red').color('bold').@game['teams']['red']['score'].color('reset')
				.'   '.simple_date('m:ss', @timeLeft).'   '
				.color('blue').color('bold').@game['teams']['blue']['score']);
		
		if(!@game['teams']['red']['players'] && !@game['teams']['blue']['players']) {
			_hoops_end();
		} else if(@timeLeft <= 0) {
			if(@game['teams']['red']['score'] > @game['teams']['blue']['score']) {
				_hoops_end('Red');
			} else if(@game['teams']['red']['score'] < @game['teams']['blue']['score']) {
				_hoops_end('Blue');
			} else {
				_hoops_end('');
			}
			die();
		}

		if(!@game['ball']) {
			if(@game['teams']['red']['score'] >= 10) {
				_hoops_end('Red');
			} else if(@game['teams']['blue']['score'] >= 10) {
				_hoops_end('Blue');
			} else {
				if(@game['possession']) {
					_hoops_ball_create(@game['possessionLoc']);
					@possession = @game['possession'];
					if(@game['teams'][@possession]['players']) {
						set_entity_spec(@game['ball'], array('gravity': false));
						@holder = array_get_rand(@game['teams'][@possession]['players']);
						@game['holder'] = @holder;
						@game['possessionLoc']['yaw'] = get_yaw(@game['possessionLoc'], @game['center']);
						set_ploc(@holder, location_shift(@game['possessionLoc'], 'down'));
						@game['possession'] = '';
						@game['possessionLoc'] = null;
						set_pinv(@holder, -106, array('name': 'MAGMA_CREAM'));
						update_bar('hoops', array('color': to_upper(@game['players'][@holder]['team'])));
					}
				} else {
					_hoops_ball_create(@game['center']);
					foreach(@p in array_keys(@game['players'])) {
						title(@p, 'Jump!', null, 0, 20, 20);
					}
				}
			}
		}
	});
}

proc _hoops_boo() {
	_hoops_cheer(5, false, array('ENTITY_VILLAGER_NO', 'ENTITY_VINDICATOR_AMBIENT'));
}

proc _hoops_cheer(@count = 15, @jump = true, @sound = array('ENTITY_VILLAGER_YES', 'ENTITY_ILLUSIONER_AMBIENT')) {
	@game = import('hoops');
	@count = array(@count);
	set_interval(150, closure() {
		if(@count[0]-- <= 0) {
			clear_task();
		}
		try {
			@villager = array_get_rand(@game['villagers']);
			@loc = entity_loc(@villager);
			play_sound(@loc, array('sound': array_get_rand(@sound), 'volume': 3));
			if(@jump) {
				set_entity_loc(@villager, location_shift(@loc, 'up'));
				set_timeout(800, closure(){
					@loc['y'] = @game['center'][1];
					try(set_entity_loc(@villager, @loc))
				});
			}
		} catch(BadEntityException @ex) {
			clear_task();
		}
	});
}

proc _hoops_end(@team) {
	@game = import('hoops');
	@game['state'] = 3;
	
	if(@team) {
		@color = color(@team);
		play_sound(@game['center'], array('sound': 'UI_TOAST_CHALLENGE_COMPLETE', 'volume': 4));
		@msg = @color.@team.' team wins!';
		broadcast(@msg, all_players(@game['world']));
		foreach(@p in array_keys(@game['players'])) {
			title(@p, @msg, null, 0, 20, 20);
		}
	}

	set_block(@game['center'], 'AIR');
	_hoops_delete();
}

proc _hoops_delete() {
	@game = import('hoops');
	foreach(@p in array_keys(@game['players'])) {
		_hoops_player_remove(@p);
	}
	foreach(@v in @game['villagers']) {
		try(entity_remove(@v))
	}
	export('hoops', null);
	remove_bar('hoops');
}

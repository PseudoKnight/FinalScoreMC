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
	);
	export('hoops', @game);
}

proc _hoops_queue(@seconds) {
	@game = import('hoops');
	@game['state'] = 1;
	create_bar('hoops', array('percent': 0.0, 'style': 'SEGMENTED_6'));
	
	foreach(@i: @p in array_keys(@game['players'])) {
		if(pworld(@p) == @game['world']) {
			_hoops_player_set_team(@p, array_size(@game['players']) - @i - 1);
			_hoops_player_equip(@p);
		} else {
			_hoops_player_remove(@p);
		}
	}
	
	@startTime = time();
	set_interval(1000, closure() {
		@countdown = 10 - integer((time() - @startTime) / 1000);
		if(@countdown <= 0) {
			clear_task();
			_hoops_start();
		} else {
			foreach(@p in array_keys(@game['players'])) {
				title(@p, @countdown, null, 0, 20, 20);
			}
		}
	});
}

proc _hoops_start() {
	@game = import('hoops');
	@game['state'] = 2;
	
	@startTime = time();

	set_interval(1000, closure(){
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
		
		@timeLeft = 180 * 1000 - (time() - @startTime);
		
		update_bar('hoops', color('red').@game['teams']['red']['score'].color('reset')
				.' | '
				.simple_date('m:ss', @timeLeft)
				.' | '
				.color('blue').@game['teams']['blue']['score']);
		
		if(!@game['teams']['red']['players']) {
			_hoops_end('Blue');
		} else if(!@game['teams']['blue']['players']) {
			_hoops_end('Red');
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
			if(@game['teams']['red']['score'] >= 7) {
				_hoops_end('Red');
			} else if(@game['teams']['blue']['score'] >= 7) {
				_hoops_end('Blue');
			} else {
				if(@game['possession']) {
					_hoops_ball_create(@game['possessionLoc']);
					@game['holder'] = array_rand(@game['teams'][@game['possession']]['players'], 1, false)[0];
					@game['possessionLoc']['yaw'] = get_yaw(@game['possessionLoc'], @game['center']);
					set_ploc(@game['holder'], location_shift(@game['possessionLoc'], 'down'));
					@game['possession'] = '';
					@game['possessionLoc'] = null;
					set_pinv(@game['holder'], -106, array('name': 'MAGMA_CREAM'));
					update_bar('hoops', 0.0);
					update_bar('hoops', array('color': to_upper(@game['players'][@game['holder']]['team'])));
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

proc _hoops_end(@team) {
	@game = import('hoops');
	@game['state'] = 3;
	
	@color = color(@team);
	if(!@team) {
		@color = color('WHITE');
		@team = 'No';
	} else {
		play_sound(@game['center'], array('sound': 'UI_TOAST_CHALLENGE_COMPLETE'));
	}
	broadcast(@color.@team.' team wins!', all_players(@game['world']));
	
	_hoops_delete();
}

proc _hoops_delete() {
	@game = import('hoops');
	foreach(@p in array_keys(@game['players'])) {
		_hoops_player_remove(@p);
	}
	export('hoops', null);
	remove_bar('hoops');
}

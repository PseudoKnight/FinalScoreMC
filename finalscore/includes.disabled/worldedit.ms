proc _send_block_changes(@players, @loc, @block) {
	foreach(@p in @players) {
		psend_block_change(@p, @loc, @block);
	}
}

proc _draw_selection(@clear = false) {
	try(
		@1 = sk_pos1();
		@2 = sk_pos2();
	, # not a cuboid region
		return();
	);

	@players = players_in_radius(112);

	if(!is_null(@1)) {
		_send_block_changes(@players, @1, if(@clear, get_block_at(@1), '95:11'));
	}
	if(!is_null(@2)) {
		_send_block_changes(@players, @2, if(@clear, get_block_at(@2), '95:1'));
	}

	if(!is_null(@1) && !is_null(@2)) {
		@1block = '95:3';
		@2block = '95:4';

		if(@1['x'] != @2['x']) {
			@1x = @1[];
			@2x = @2[];
			if(@1['x'] > @2['x']) {
				@1x['x'] -= 1;
				@2x['x'] += 1;
			} else {
				@1x['x'] += 1;
				@2x['x'] -= 1;
			}
			_send_block_changes(@players, @1x, if(@clear, get_block_at(@1x), @1block));
			_send_block_changes(@players, @2x, if(@clear, get_block_at(@2x), @2block));
		}

		if(@1['y'] != @2['y']) {
			@1y = @1[];
			@2y = @2[];
			if(@1['y'] > @2['y']) {
				@1y['y'] -= 1;
				@2y['y'] += 1;
			} else {
				@1y['y'] += 1;
				@2y['y'] -= 1;
			}
			_send_block_changes(@players, @1y, if(@clear, get_block_at(@1y), @1block));
			_send_block_changes(@players, @2y, if(@clear, get_block_at(@2y), @2block));
		}

		if(@1['z'] != @2['z']) {
			@1z = @1[];
			@2z = @2[];
			if(@1['z'] > @2['z']) {
				@1z['z'] -= 1;
				@2z['z'] += 1;
			} else {
				@1z['z'] += 1;
				@2z['z'] -= 1;
			}
			_send_block_changes(@players, @1z, if(@clear, get_block_at(@1z), @1block));
			_send_block_changes(@players, @2z, if(@clear, get_block_at(@2z), @2block));
		}
	}
}

proc _redraw_selection() {
	_draw_selection(true);
	set_timeout(50, closure(){
		_draw_selection();
	});
}

bind(player_interact, null, array('item': 286), @event) {
	if(!array_index_exists(@event, 'location') || @event['location']['world'] !== 'dev') {
		die();
	}

	_redraw_selection();
}

bind(player_command, null, null, @event) {
	if(pworld() !== 'dev') {
		die();
	}
	# all worldedit commands that affect selections start with double slashes
	if(array_get(@event['prefix'], 1, '') === '/') {
		if(@event['prefix'] === '//sel') {
			_draw_selection(true);
			# sk_pos retains previous selection points, so clear those
			try(
				sk_pos1(player(), null);
				sk_pos2(player(), null);
			);
		} else {
			_redraw_selection();
		}
	} else if(equals_ic(@event['prefix'], '/rg') || equals_ic(@event['prefix'], '/region')) {
		@args = parse_args(@event['command']);
		if(array_index_exists(@args, 1) && array_contains_ic(array('s', 'sel', 'select'), @args[1])) {
			_redraw_selection();
		}
	}
}

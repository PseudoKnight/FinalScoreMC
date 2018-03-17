proc _worms_create(@region) {
	@world = pworld();
	@coords = sk_region_info(@region, @world, 0);
	
	@game = array(
		'world': @world,
		'height': 12,
		'region': @region,
		'x': array('highest': @coords[0][0], 'lowest': @coords[1][0]),
		'y': array('highest': @coords[0][1], 'lowest': @coords[1][1]),
		'z': array('highest': @coords[0][2], 'lowest': @coords[1][2]),
		'players': associative_array(),
		'segments': array(),
	);
	
	create_scoreboard('worms');
	create_objective('segments', 'DUMMY', 'worms');
	set_objective_display('segments', array('displayname': 'Segments (50)', 'slot': 'SIDEBAR'), 'worms');
	
	return(@game);
}

proc _worms_start(@game) {
	foreach(@p in all_players(@game['world'])) {
		if(array_contains(sk_current_regions(@p), @game['region'])) {
			_worms_add_player(@p, @game);
		}
	}
	if(array_size(@game['players']) < 1) {
		_worms_cleanup(@game);
		die(color('gold').'Not enough players.');
	}
	foreach(@p: @worm in @game['players']) {
		_worms_spawn_player(@p, @game);
	}
	export('worms'.@game['region'], true);
	_worms_bind_events(@game);
}

proc _worms_end(@game) {
	export('worms'.@game['region'], null);
	_worms_unbind_events(@game);
	@winner = '';
	foreach(@player: @worm in @game['players']) {
		@winner = @player;
	}
	if(@winner) {
		broadcast(@winner.' won worms!', all_players(@game['world']));
	}
	_worms_cleanup(@game);
}

proc _worms_cleanup(@game) {
	foreach(@player: @worm in @game['players']) {
		_worms_remove_player(@player, @game);
	}
	foreach(@segment in @game['segments']) {
		entity_remove(@segment);
	}
	remove_scoreboard('worms');
}
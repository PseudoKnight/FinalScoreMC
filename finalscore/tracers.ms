if(extension_exists('CHDynmap')) {

@closure = closure() {

if(!array_contains(dm_all_markersets(), 'tracers')) {
	dm_create_markerset('tracers', array('label': 'Tracers', 'persistent': false));
	dm_set_markerset_hide_by_default('tracers', false);
}

bind(player_move, null, array('threshold': 10), @event) {
	try(
		if(player() == '~console'
		|| pmode() == 'CREATIVE' 
		|| !has_permission('livemap.tracers')
		|| array_get(_pdata(player()), 'support', 5) < 10) {
			die();
		}
	, # sometimes the player is offline in player_move
		die();
	);
	
	try(
		if((@playerCount = _player_count()) > 20) {
			die();
		}
		@lines = dm_marker_corners('tracers', player());
		if(array_size(@lines) > 128 - @playerCount * 7) {
			array_remove(@lines, 0);
		}
		@lines[] = ploc();
		dm_set_marker_corners('tracers', player(), @lines);
	, # catch
		dm_create_marker('tracers', array(
			'type': 'POLYLINE',
			'world': pworld(),
			'label': player(),
			'id': player(),
			'corners': array(@event['to'])
		));
		# dm_set_marker_line_style() does not seem to update the line.
		runas('~console', '/dmarker updateline set:tracers id:'.player()
			.' opacity:0.4 weight:2');
	)
}

bind(player_teleport, null, null, @event) {
	@pdata = _pdata(player());
	if(array_get(@pdata, 'group', 'default') != 'donor'
	|| array_get(@pdata, 'support', 5) < 10) {
		die();
	}
	set_timeout(50, closure(){
		if(@event['from']['world'] != @event['to']['world']) {
			if(array_contains(dm_all_markers('tracers'), player())) {
				dm_delete_marker('tracers', player());
			}
		} else if(@event['type'] != 'ENDER_PEARL' && has_permission('livemap.tracers')) {
			@dist = sqrt((@event['to']['x'] - @event['from']['x'])**2 
				+ (@event['to']['z'] - @event['from']['z'])**2);
			if(@dist > 64) {
				try(dm_set_marker_corners('tracers', player(), array(@event['to'])));
			}
		}
	});
}

bind(player_death, null, null, @event) {
	if(!has_permission('livemap.deathmarkers')) {
		die();
	}
	@markers = dm_all_markers('tracers');
	foreach(@marker in @markers) {
		if(@marker == player()
		|| @marker == player().'lastdeath') {
			dm_delete_marker('tracers', @marker);
		}
	}
	dm_create_marker('tracers', array(
		'world': pworld(),
		'label': @event['death_message'],
		'id': player().'lastdeath',
		'icon': 'skull',
		'location': ploc()
	));
}

bind(player_quit, null, null, @event) {
	if(array_contains(dm_all_markers('tracers'), player())) {
		dm_delete_marker('tracers', player());
	}
}

}

set_timeout(4000, @closure);

}
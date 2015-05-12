if(extension_exists('CHDynmap')) {

@closure = closure() {

if(!array_contains(dm_all_markersets(), 'tracers')) {
	dm_create_markerset('tracers', array('label': 'Tracers', 'persistent': false));
	dm_set_markerset_hide_by_default('tracers', false);
}

bind(player_move, null, array('threshold': 10), @event) {
	if(!ponline(@event['player']) || !has_permission('livemap.tracers') || pmode() == 'CREATIVE') {
		die();
	}
	@pdata = _pdata(@event['player']);
	if(!array_index_exists(@pdata, 'support') || @pdata['support'] < 15) {
		die();
	}
	try(
		@lines = dm_marker_corners('tracers', player());
		if(array_size(@lines) > 120) {
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
	if(!has_permission('livemap.tracers') || pmode() == 'CREATIVE') {
		die();
	}
	@pdata = _pdata(@event['player']);
	if(!array_index_exists(@pdata, 'support') || @pdata['support'] < 15) {
		die();
	}
	if(@event['from']['world'] != @event['to']['world']) {
		try(dm_delete_marker('tracers', player()));
	} else if(@event['type'] != 'ENDER_PEARL') {
		@dist = sqrt((@event['to']['x'] - @event['from']['x'])**2 
			+ (@event['to']['z'] - @event['from']['z'])**2);
		if(@dist > 64) {
			try(dm_set_marker_corners('tracers', player(), array(@event['to'])));
		}
	}
}

bind(player_death, null, null, @event) {
	if(!has_permission('livemap.deathmarkers')) {
		die();
	}
	@pdata = _pdata(@event['player']);
	try(dm_delete_marker('tracers', player()));
	try(dm_delete_marker('tracers', player().'lastdeath'));
	dm_create_marker('tracers', array(
		'world': pworld(),
		'label': @event['death_message'],
		'id': player().'lastdeath',
		'icon': 'skull',
		'location': ploc()
	));
}

bind(player_quit, null, null, @event) {
	if(!has_permission('livemap.tracers')) {
		die();
	}
	@pdata = _pdata(@event['player']);
	if(!array_index_exists(@pdata, 'support') || @pdata['support'] < 15) {
		die();
	}
	try(dm_delete_marker('tracers', player()));
}

}

set_timeout(4000, @closure);

}
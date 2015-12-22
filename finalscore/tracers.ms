if(extension_exists('CHDynmap')) {

if(!array_contains(dm_all_markersets(), 'tracers')) {
	dm_create_markerset('tracers', array('label': 'Tracers', 'persistent': false));
	dm_set_markerset_hide_by_default('tracers', false);
}

bind(player_move, null, array('threshold': 10), @event) {
	if(pmode() === 'CREATIVE') {
		die();
	}
	
	@pdata = _pdata(player());
	if(!array_index_exists(@pdata, 'support')) {
		die();
	}
	
	try(
		@lines = dm_marker_corners('tracers', player());
		if(array_size(@lines) > @pdata['support'] * 2) {
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
		dm_set_marker_line_style('tracers', player(), array(
			'color': array('r': 200, 'g': 0, 'b': 0), 
			'opacity': 0.5, 
			'weight': 2,
		));
	)
}

bind(player_teleport, null, null, @event) {
	if(!has_permission('group.donor')) {
		die();
	}
	set_timeout(50, closure(){
		if(@event['from']['world'] != @event['to']['world']) {
			if(array_contains(dm_all_markers('tracers'), player())) {
				dm_delete_marker('tracers', player());
			}
		} else if(@event['type'] !== 'ENDER_PEARL' && has_permission('livemap.tracers')) {
			@dist = sqrt((@event['to']['x'] - @event['from']['x'])**2 
				+ (@event['to']['z'] - @event['from']['z'])**2);
			if(@dist > 64) {
				try(dm_set_marker_corners('tracers', player(), array(@event['to'])));
			}
		}
	});
}

bind(player_death, null, null, @event) {
	if(!_is_survival_world(pworld()) || !has_permission('livemap.deathmarkers')) {
		die();
	}
	dm_create_marker('tracers', array(
		'world': pworld(),
		'label': @event['death_message'],
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
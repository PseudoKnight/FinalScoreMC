proc _place_ball(@mobtype, @loc, @ball) {
	@loc = @loc[];
	@loc['x'] += 0.5;
	@loc['y'] += 1;
	@loc['z'] += 0.5;
	
	@ball['id'] = spawn_mob(@mobtype.':1', 1, @loc)[0];
	@ball['velocity'] = array(x: 0, y: 0, z: 0);
		
	set_entity_velocity(@ball['id'], array(0, 0, 0));
	set_timeout(50, closure(){
		set_mob_effect(@ball['id'], 11, 4, 99999, true);
		set_mob_effect(@ball['id'], 2, 7, 99999, true);
	});
}

proc _ball_exists(@id) {
	return(@id && entity_exists(@id));
}

proc _remove_ball(@id) {
	try(
		entity_remove(@id);
	)
}
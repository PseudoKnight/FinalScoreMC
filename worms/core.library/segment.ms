proc _worms_create_segments(@loc, @num, @color, @game) {
	if(@color == -1) {
		@color = rand(16);
	}
	@segments = spawn_entity('ARMOR_STAND', @num, @loc);
	foreach(@segment in @segments) {
		set_entity_spec(@segment, array('visible': false, 'gravity': false));
		set_mob_equipment(@segment, array(
			'HELMET': array('name': 'CONCRETE', 'data': @color),
		));
	}
	return(@segments);
}

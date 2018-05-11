proc _worms_create_segments(@loc, @num, @color, @game) {
	if(@color == -1) {
		@color = rand(16);
	}
	@segments = spawn_entity('ARMOR_STAND', @num, @loc);
	foreach(@segment in @segments) {
		set_entity_spec(@segment, array('baseplate': false, 'gravity': false, 'arms': true, 'poses': array(
			'poseArmLeft': array(-0.2, 0, -0.9),
			'poseArmRight': array(-0.3, 0, 1.0),
			'poseLegLeft': array(-3.2, 0, 0),
			'poseLegRight': array(-3.2, 0, 0),
		)));
		set_mob_equipment(@segment, array(
			'HELMET': array('name': 'CONCRETE', 'data': @color),
		));
	}
	return(@segments);
}

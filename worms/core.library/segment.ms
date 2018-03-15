proc _worms_create_segments(@player, @num, @game, @color) {
	@segments = spawn_entity('ARMOR_STAND', @num, location_shift(ploc(@player), 'down', @game['height']));
	foreach(@segment in @segments) {
		set_entity_spec(@segment, array('visible': false, 'gravity': false));
		set_mob_equipment(@segment, array(
			'HELMET': array('name': 'CONCRETE', 'data': if(@color, @color, @game['players'][@player]['color'])),
		));
		@game['players'][@player]['segments'][] = @segment;
	}
	set_pscore('segments', @player, array_size(@game['players'][@player]['segments']), 'worms');
}

proc _worms_add_player(@player, @game) {
	set_peffect(@player, 'SPEED', 4, 9999, true, false);
	set_peffect(@player, 'INVISIBILITY', 0, 9999, true, false);
	set_pmode(@player, 'ADVENTURE');
	
	@game['players'][@player] = array(
		'segments': array(),
		'color': array_get_rand(reflect_pull('enum', 'DyeColor')),
	);
	
	@loc = array_get_rand(@game['spawns'][0]);
	@loc[5] = 90.0;
	set_ploc(@player, location_shift(@loc, 'up', 15));

	set_pscoreboard(@player, 'worms');
}

proc _worms_remove_player(@player, @game) {
	foreach(@segment in @game['players'][@player]['segments']) {
		try(entity_remove(@segment))
	}
	array_remove(@game['players'], @player);
	if(pworld(@player) == @game['world']) {
		set_peffect(@player, 'INVISIBILITY', 0, 0);
		set_peffect(@player, 'SPEED', 0, 0);
	}
}

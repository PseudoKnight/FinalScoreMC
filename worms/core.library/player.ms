proc _worms_add_player(@player, @game) {
	set_peffect(@player, 1, 4, 9999, true, false);
	set_peffect(@player, 14, 0, 9999, true, false);
	
	@game['players'][@player] = array(
		'segments': array(),
		'color': rand(16),
	);
	
	@loc = ploc(@player);
	@loc['pitch'] = 90.0;
	set_ploc(@player, @loc);

	set_pscoreboard(@player, 'worms');
}

proc _worms_remove_player(@player, @game) {
	foreach(@segment in @game['players'][@player]['segments']) {
		try(entity_remove(@segment));
	}
	array_remove(@game['players'], @player);
	if(pworld(@player) == @game['world']) {
		set_peffect(@player, 14, 0, 0);
		set_peffect(@player, 1, 0, 0);
	}
}

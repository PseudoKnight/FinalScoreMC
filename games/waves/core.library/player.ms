proc _waves_add_player(@player, @waves) {
	if(phealth(@player) == 0) {
		return(false);
	}
	if(!_set_pactivity(@player, _to_upper_camel_case(@waves['region']))) {
		return(false);
	}
	@c = @waves['config'];
	@waves['players'][] = @player;
	set_pscoreboard(@player, 'waves'.@waves['region']);
	bar_add_player('waves'.@waves['region'], @player);
	clear_peffects(@player);
	_clear_pinv(@player);
	if(array_index_exists(@c, 'gear')) {
		set_pinv(@player, @c['gear']);
	}
	if(array_index_exists(@c, 'shop')) {
		pgive_item(@player, array(name: 'EMERALD', meta: array(display: 'Open Shop', lore: array(@player.'\'s Shop Token'))));
	}
	set_pbed_location(@player, @waves['arena']['lobby']);
	set_entity_health(puuid(@player), 100);
	set_phunger(@player, 20);
	set_psaturation(@player, 5);
	@levels = 0;
	if(array_index_exists(@c, 'levels')) {
		@levels = @c['levels'];
	}
	set_plevel(@player, @levels);
	set_pexp(@player, 0);
	title(@player, @c['title'], if(array_index_exists(@c, 'subtitle'), '('.@c['subtitle'].')', ''), 20, 40, 20);
}

proc _waves_remove_player(@player, @waves) {
	try(bar_remove_player('waves'.@waves['region'], @player));
	array_remove_values(@waves['players'], @player);
	clear_peffects(@player);
	_equip_kit(@player);
	_set_pactivity(@player, null);
}

proc _waves_add_spectator(@player, @waves) {
	@waves['spectators'][] = @player;
	set_pmode(@player, 'SPECTATOR');
}

proc _waves_remove_spectator(@player, @waves) {
	array_remove_values(@waves['spectators'], @player);
	if(pmode(@player) != 'ADVENTURE' || get_block(location_shift(ploc(@player), 'up')) != 'AIR') {
		set_pmode(@player, 'ADVENTURE');
		set_ploc(@player, @waves['arena']['lobby']);
	}
	clear_peffects(@player);
	_equip_kit(@player);
}
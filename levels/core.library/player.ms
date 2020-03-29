proc _level_add_player(@player, @level) {
	if(phealth(@player) == 0) {
		return(false);
	}
	if(!_set_pactivity(@player, to_upper(@level['region']))) {
		return(false);
	}
	@c = @level['config'];
	@level['players'][] = @player;
	set_pscoreboard(@player, 'level'.@level['region']);
	bar_add_player('level'.@level['region'], @player);
	clear_peffects(@player);
	_clear_pinv(@player);
	if(array_index_exists(@c, 'gear')) {
		set_pinv(@player, @c['gear']);
	}
	if(array_index_exists(@c, 'shop')) {
		pgive_item(@player, array('name': 'EMERALD', 'meta': array('display': 'Open Shop', 'lore': array(@player.'\'s Shop Token'))));
	}
	set_pbed_location(@player, @level['arena']['lobby']);
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

proc _level_remove_player(@player, @level) {
	try(bar_remove_player('level'.@level['region'], @player));
	array_remove_values(@level['players'], @player);
	clear_peffects(@player);
	_equip_kit(@player);
	_set_pactivity(@player, null);
}

proc _level_add_spectator(@player, @level) {
	@level['spectators'][] = @player;
	set_pmode(@player, 'SPECTATOR');
}

proc _level_remove_spectator(@player, @level) {
	array_remove_values(@level['spectators'], @player);
	if(pmode(@player) != 'ADVENTURE' || get_block(location_shift(ploc(@player), 'up')) != 'AIR') {
		set_pmode(@player, 'ADVENTURE');
		set_ploc(@player, @level['arena']['lobby']);
	}
	clear_peffects(@player);
	_equip_kit(@player);
}

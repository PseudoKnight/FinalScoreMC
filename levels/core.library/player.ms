proc _level_add_player(@player, @level) {
	if(pinfo(@player, 5) == 0) {
		return(false);
	}
	if(!_set_pactivity(@player, to_upper(@level['region']))) {
		return(false);
	}
	@level['players'][] = @player;
	set_pscoreboard(@player, 'level'.@level['region']);
	_clear_peffects(@player);
	_clear_pinv(@player);
	set_pinv(@player, @level['config']['gear']);
	if(array_index_exists(@level['config'], 'shop')) {
		pgive_item(@player, 388, 1, array('display': 'Open Shop', 'lore': array(@player.'\'s Shop Token')));
	}
	set_pbed_location(@player, @level['arena']['lobby']);
	set_entity_health(puuid(@player), 100);
	set_phunger(@player, 20);
	set_psaturation(@player, 5);
	@levels = 0;
	if(array_index_exists(@level['config'], 'levels')) {
		@levels = @level['config']['levels'];
	}
	set_plevel(@player, @levels);
	set_pexp(@player, 0);
	title_msg(@player, @level['config']['title'], 'by '.@level['config']['author']
		.if(array_index_exists(@level['config'], 'subtitle'), '('.@level['config']['subtitle'].')', ''), 20, 40, 20);
}

proc _level_remove_player(@player, @level) {
	array_remove_values(@level['players'], @player);
	_clear_peffects(@player);
	_equip_kit(@player);
	_set_pactivity(@player, null);
}

proc _level_add_spectator(@player, @level) {
	@level['spectators'][] = @player;
	set_pmode(@player, 'SPECTATOR');
}

proc _level_remove_spectator(@player, @level) {
	array_remove_values(@level['spectators'], @player);
	set_pmode(@player, 'ADVENTURE');
	set_ploc(@player, @level['arena']['lobby']);
	_clear_peffects(@player);
	_equip_kit(@player);
}

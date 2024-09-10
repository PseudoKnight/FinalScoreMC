proc _waves_add_player(@player, @waves) {
	if(phealth(@player) == 0) {
		return(false);
	}
	if(!_set_pactivity(@player, _to_upper_camel_case(@waves['region']))) {
		return(false);
	}
	@c = @waves['config'];
	@waves['players'][] = @player;
	@waves['allplayers'][@player] = array(wave: @waves['wave']);
	set_pscoreboard(@player, 'waves'.@waves['region']);
	bar_add_player('waves'.@waves['region'], @player);
	create_bar('waves'.@waves['region'].@player, array(visible: false, color: 'YELLOW'));
	foreach(@p in @waves['players']) {
		bar_add_player('waves'.@waves['region'].@p, @player);
		bar_add_player('waves'.@waves['region'].@player, @p);
	}
	clear_peffects(@player);
	clear_pinv(@player);
	if(array_index_exists(@c, 'equipment')) {
		set_mob_equipment(puuid(@player), @c['equipment']);
	}
	if(array_index_exists(@c, 'inventory')) {
		foreach(@item in @c['inventory']) {
			pgive_item(@player, @item);
		}
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
	if(array_index_exists(@c, 'title')) {
		title(@player, @c['title'], if(array_index_exists(@c, 'subtitle'), '('.@c['subtitle'].')', ''), 20, 40, 20);
	}
	return(true);
}

proc _waves_remove_player(@player, @waves) {
	array_remove_values(@waves['players'], @player);
	clear_peffects(@player);
	_equip_kit(@player);
	_set_pactivity(@player, null);
	try(bar_remove_player('waves'.@waves['region'], @player))
	foreach(@p in @waves['players']) {
		try(bar_remove_player('waves'.@waves['region'].@p, @player))
	}
	try(remove_bar('waves'.@waves['region'].@player))
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

proc _hoops_player_add(@player) {
	@game = import('hoops');
	@game['players'][@player] = array(
		'score': 0,
		'team': '',
	);
	if(@game['state'] > 0) {
		_hoops_player_set_team(@player);
		_hoops_player_equip(@player);
	}
}

proc _hoops_player_set_team(@player) {
	@game = import('hoops');
	@team = 'red';
	if(array_size(@game['teams']['red']['players']) > array_size(@game['teams']['blue']['players'])) {
		@team = 'blue';
	}
	@game['teams'][@team]['players'][] = @player;
	@game['players'][@player]['team'] = @team;
}

proc _hoops_player_equip(@player) {
	@game = import('hoops');
	@team = @game['players'][@player]['team'];
	@data = if(@team == 'blue', 11, 14);
	@color = if(@team == 'blue', array(0, 0, 255), array(255, 0, 0));
	set_pmode(@player, 'SURVIVAL');
	set_peffect(@player, 8, 0, 90, true, false);
	@items = array(
		0: null,
		1: array('name': 'STAINED_GLASS_PANE', 'data': @data),
		2: array('name': 'STAINED_GLASS_PANE', 'data': @data),
		3: array('name': 'STAINED_GLASS_PANE', 'data': @data),
		4: array('name': 'STAINED_GLASS_PANE', 'data': @data),
		5: array('name': 'STAINED_GLASS_PANE', 'data': @data),
		6: array('name': 'STAINED_GLASS_PANE', 'data': @data),
		7: array('name': 'STAINED_GLASS_PANE', 'data': @data),
		8: array('name': 'STAINED_GLASS_PANE', 'data': @data),
		100: array('name': 'LEATHER_BOOTS', 'meta': array('color': @color)),
		101: array('name': 'LEATHER_LEGGINGS', 'meta': array('color': @color)),
		102: array('name': 'LEATHER_CHESTPLATE', 'meta': array('color': @color)),
	);
	set_pinv(@player, @items);
	set_phunger(@player, 20);
	bar_add_player('hoops', @player);
	set_pheld_slot(@player, 0);
	set_pflight(@player, true);
	set_pflying(@player, false);
	bind('player_toggle_flight', array('id': @player.'jump'), array('flying': true, 'player': @player), @event) {
		cancel();
		@block = get_block_at(location_shift(ploc(), 'down'));
		if(@block == '351:11' || @block == '351:14') {
			@vel = entity_velocity(puuid());
			set_pvelocity(@vel['x'] * 1.5, 0.6, @vel['z'] * 1.5);
			set_pflight(false);
			@world = pworld();
			set_timeout(2000, closure(){
				if(@world == pworld()) {
					set_pflight(true);
				}
			});
		}
	}
}

proc _hoops_player_remove(@player) {
	@game = import('hoops');
	array_remove(@game['players'], @player);
	foreach(@team in @game['teams']) {
		array_remove_values(@team['players'], @player);
	}
	if(ponline(@player)) {
		unbind(@player.'jump');
		set_pflight(@player, false);
		set_pmode(@player, 'ADVENTURE');
		set_peffect(@player, 8, 0, 0, true, false);
		bar_remove_player('hoops', @player);
		if(pworld(@player) == @game['world']) {
			_equip_kit(@player);
		}
	}
}

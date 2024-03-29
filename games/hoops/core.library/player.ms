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

proc _hoops_player_set_team(@player, @playersLeft = 0) {
	@game = import('hoops');
	@team = 'red';
	@redCount = array_size(@game['teams']['red']['players']);
	@blueCount = array_size(@game['teams']['blue']['players']);
	if(@redCount > @blueCount + @playersLeft) {
		@team = 'blue';
	} else if(@redCount + @playersLeft < @blueCount) {
		@team = 'red';
	} else {
		if(ploc(@player)['z'] > @game['center'][2]) {
			@team = 'red';
		} else {
			@team = 'blue';
		}
	}
	@game['teams'][@team]['players'][] = @player;
	@game['players'][@player]['team'] = @team;
}

proc _hoops_player_equip(@player) {
	@game = import('hoops');
	
	@team = @game['players'][@player]['team'];
	@type = if(@team == 'blue', 'BLUE_STAINED_GLASS_PANE', 'RED_STAINED_GLASS_PANE');
	@color = if(@team == 'blue', array(0, 0, 255), array(255, 0, 0));
	@items = array(
		0: null,
		1: array('name': @type),
		2: array('name': @type),
		3: array('name': @type),
		4: array('name': @type),
		5: array('name': @type),
		6: array('name': @type),
		7: array('name': @type),
		8: array('name': @type),
		100: array('name': 'LEATHER_BOOTS', 'meta': array('color': @color)),
		101: array('name': 'LEATHER_LEGGINGS', 'meta': array('color': @color)),
		102: array('name': 'LEATHER_CHESTPLATE', 'meta': array('color': @color)),
	);
	set_pinv(@player, @items);
	set_pheld_slot(@player, 0);
	
	set_pmode(@player, 'SURVIVAL');
	set_phunger(@player, 20);
	set_psaturation(@player, 20);
	
	bar_add_player('hoops', @player);
	
	bind('player_jump', array('id': @player.'jump'), array('player': @player), @event) {
		if(array_contains(sk_current_regions(), 'hoops')) {
			set_timeout(1,closure(){
				@vel = entity_velocity(puuid());
				set_pvelocity(@vel['x'] * 0.1, 0.85, @vel['z'] * 0.1);
			});
		}
	}
	
	bind('block_break', array('id': @player.'break'), array('player': @player), @event) {
		cancel();
	}
}

proc _hoops_player_remove(@player) {
	@game = import('hoops');
	array_remove(@game['players'], @player);
	foreach(@team in @game['teams']) {
		array_remove_values(@team['players'], @player);
	}
	unbind(@player.'jump');
	unbind(@player.'break');
	if(@game['lastholder'] == @player) {
		@game['lastholder'] = '';
	}
	if(ponline(@player)) {
		set_pmode(@player, 'ADVENTURE');
		bar_remove_player('hoops', @player);
		if(pworld(@player) == @game['world']) {
			_equip_kit(@player);
		}
	}
}

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
	@data = if(@team == 'blue', 11, 14);
	@color = if(@team == 'blue', array(0, 0, 255), array(255, 0, 0));
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
	set_pheld_slot(@player, 0);
	
	set_pmode(@player, 'SURVIVAL');
	set_phunger(@player, 20);
	set_psaturation(@player, 20);
	
	bar_add_player('hoops', @player);
	
	bind('player_jump', array('id': @player.'jump'), array('player': @player), @event) {
		if(psneaking()) {
			@block = get_block_at(ploc());
			if(@block == '251:11' || @block == '251:14') {
				set_timeout(50,closure(){
					@vel = entity_velocity(puuid());
					set_pvelocity(@vel['x'] * 1.4, 0.85, @vel['z'] * 1.4);
				});
			}
		} else {
			set_timeout(50,closure(){
				@vel = entity_velocity(puuid());
				set_pvelocity(0, 0.2, 0);
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
	if(ponline(@player)) {
		set_pmode(@player, 'ADVENTURE');
		bar_remove_player('hoops', @player);
		if(pworld(@player) == @game['world']) {
			_equip_kit(@player);
		}
	}
}

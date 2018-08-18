array_push(@pvp['binds'], @id.'spawner')
bind('player_interact', array('id': @id.'spawner', 'priority': 'HIGH'), array('button': 'right'), @e, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player())
	|| !@e['item']
	|| !string_ends_with(@e['item']['name'], '_SPAWN_EGG')
	|| pinfo(player(), 6) != @e['item']['name']) {
		die();
	}
	cancel();
	consume();
	if(@e['action'] === 'right_click_block') {
		@item = pinv(player(), null);
		if(is_null(@item['meta'])
		|| is_null(@item['meta']['display'])) {
			die();
		}
		
		@loc = @e['location'];
		if(get_block_info(@loc)['solid']) {
			@loc = location_shift(@loc, @e['facing']);
		}
		@loc['x'] += 0.5;
		@loc['z'] += 0.5;

		@mob = to_lower(@item['meta']['display']);
		
		if(!is_null(@item['meta']['lore'])
		&& @item['meta']['lore'][0] === 'Target Near') {
			foreach(@player in players_in_radius(@loc, 20)) {
				if(@player == player() || !array_index_exists(@pvp['players'], @player)
				|| array_index_exists(@pvp, 'team') && @pvp['players'][@player]['team'] == @pvp['players'][player()]['team']) {
					continue();
				}
				_spawn_mob(@mob, @loc, @player);
			}
		} else if(array_index_exists(@pvp, 'team')) {
			@team = @pvp['players'][player()]['team'];
			_spawn_mob(@mob, @loc, player(), @pvp['team'][@team]['players']);
		} else {
			_spawn_mob(@mob, @loc, player(), array(player()));
		}
		
		@effectLoc = location_shift(@loc, 'up');
		play_sound(@effectLoc, array('sound': 'ENTITY_ZOMBIE_INFECT', 'pitch': 1.5));
		play_effect(@effectLoc, 'cloud', array('speed': 0, 'particleCount': 10, 'offsetX': 0.4, 'offsetZ': 0.4, 'offsetY': 0.4));
		_weapon_cooldown(player(), 2000, 'PUMPKIN_SEEDS', false);
	}
}

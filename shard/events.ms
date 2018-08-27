bind('player_interact', null, array('itemname': 'DIAMOND', 'hand': 'main_hand', 'block': 0), @event) {
	include('core.library/util.ms');
	if(array_contains(get_worlds(), 'shard') && array_contains(get_scoreboards(), 'shard')) {
		if(pworld() == 'shard') {
			action_msg('You can\'t go deeper!');
		} else {
			// Late join
			@game = import('shard');
			play_sound(ploc(), array('sound': 'BLOCK_GLASS_BREAK', 'pitch': 0.5));
			@loc = get_spawn('shard');
			@loc['y'] -= 1;
			set_ploc(_get_spawn_location());
			if(!@game || !array_index_exists(@game['rules'], 'keep') || !@game['rules']['keep']) {
				_clear_pinv(player());
			}
			set_plevel(player(), 0);
			set_peffect(player(), 'RESISTANCE', 3, 30, true);
			set_pscoreboard(player(), 'shard');
			play_sound(@loc, array('sound': 'BLOCK_GLASS_BREAK', 'pitch': 0.5), player());
			@game = import('shard');
			if(@game && !@game['lateJoin']) {
				set_pmode(player(), 'SPECTATOR');
			}
		}
		die();
	}
	if(!_is_survival_world(pworld())) {
		action_msg('A shard can only be generated from a survival world.');
	} else if(array_contains(get_virtual_inventories(), 'shard')) {
		action_msg('Another player is generating a shard.');
	} else {
		include('core.library/menu.ms');
		_open_objective_menu();
	}
}

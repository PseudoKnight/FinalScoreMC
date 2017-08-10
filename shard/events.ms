bind(player_interact, null, array('item': 264, 'hand': 'main_hand', 'block': 0), @event) {
	include('core.library/util.ms');
	if(array_contains(get_worlds(), 'shard') && array_contains(get_scoreboards(), 'shard')) {
		if(pworld() == 'shard') {
			action_msg('You can\'t go deeper!');
		} else {
			// Late join
			play_sound(ploc(), array('sound': 'GLASS', 'pitch': 0.5));
			@loc = get_spawn('shard');
			@loc['y'] -= 1;
			set_ploc(_get_spawn_location());
			_clear_pinv(player());
			set_plevel(player(), 0);
			set_peffect(player(), 11, 3, 30, true);
			set_pscoreboard(player(), 'shard');
			play_sound(@loc, array('sound': 'GLASS', 'pitch': 0.5), player());
			if(get_world_border('shard')['width'] < 128) {
				set_pmode('SPECTATOR');
			}
		}
		die();
	}
	if(!_is_survival_world(pworld())) {
		action_msg('A shard can only be generated from a survival world.');
	} else if(array_contains(all_virtualchests(), 'shard')) {
		action_msg('Another player is generating a shard.');
	} else {
		include('core.library/menu.ms');
		_open_objective_menu();
	}
}

bind(player_interact, null, array('item': 264, 'hand': 'main_hand', 'block': 0), @event) {
	include('core.library/util.ms');
	if(array_contains(get_worlds(), 'shard')) {
		if(pworld() == 'shard') {
			action_msg('You can\'t go deeper!');
		} else {
			// Late join
			play_sound(ploc(), array('sound': 'GLASS', 'pitch': 0.5));
			@loc = get_spawn('shard');
			@loc['y'] -= 1;
			set_ploc(_get_spawn_location());
			_shard_equip(player());
			set_peffect(player(), 11, 3, 30, true);
			set_pscoreboard(player(), 'shard');
			play_sound(@loc, array('sound': 'GLASS', 'pitch': 0.5), player());
			if(get_world_border('shard')['width'] < 128) {
				set_pmode('SPECTATOR');
			}
		}
		die();
	}
	if(!has_permission('group.engineer')) {
		action_msg('Only engineers can generate shards for now!');
		die();
	}
	
	// Open menu
	include('core.library/menu.ms');
	_create_menu();
}

include('includes.library/procedures.ms');
@perms = yml_decode(read('config.yml'));
export('perms', @perms);
foreach(@player in all_players()) {
	_perm_player(@player, false);
}

bind('player_join', null, null, @event) {
	_perm_player(@event['player']);
}

bind('player_quit', array('priority': 'LOWEST'), null, @event) {
	unperm_player(@event['player']);
}

bind('world_changed', null, null, @event) {
	_perm_player(@event['player']);
}

bind('player_interact', null, null, @event) {
	if(!has_permission('permissions.build')
	&& (@event['action'] != 'right_click_air' || !material_info(@event['item']['name'], 'isEdible'))) {
		cancel();
	}
}

@perms = yml_decode(read('config.yml'));
export('perms', @perms);

bind(player_join, null, null, @event) {
	include('includes.library/procedures.ms');
	_perm_player(@event['player']);
}

bind(world_changed, null, null, @event) {
	include('includes.library/procedures.ms');
	_perm_player(@event['player']);
}

bind(player_interact, null, null, @event) {
	if(!has_permission('permissions.build')) {
		cancel();
	}
}

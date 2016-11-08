@perms = yml_decode(read('config.yml'));
export('perms', @perms);

bind(player_join, null, null, @event) {
	include('includes.library/procedures.ms');
	_perm_player(@event['player']);
}

bind(player_quit, array('priority': 'LOWEST'), null, @event) {
	unperm_player(@event['player']);
}

bind(world_changed, null, null, @event) {
	include('includes.library/procedures.ms');
	_perm_player(@event['player']);
}

bind(player_interact, null, null, @event) {
	if(!has_permission('permissions.build')
	&& (@event['action'] != 'right_click_air' || !material_info(split(':', @event['item'])[0])['isEdible'])) {
		cancel();
	}
}

// Add limited WorldEdit perms if player says he has WorldEdit CUI
bind(player_command, null, array('command': '/we cui'), @event) {
	if(has_permission('limitedworldedit') && !has_permission('worldedit.fast')) {
		@perms = import('perms');
		foreach(@perm: @value in @perms['limitedworldedit']['permissions']) {
			set_permission(@perm, @value);
		}
		action_msg('Enabled WorldEdit.');
	}
}

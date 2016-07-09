bind(world_changed, null, null, @event) {
	@to = @event['to'];
	@from = @event['from'];
	@worlds = _worlds_config();
	if(@worlds[@from]['mode'] != @worlds[@to]['mode']) {
		# let's swap inventory
		close_pinv();
		set_pmode(@worlds[@to]['mode']);
		include('util.library/storage.ms');
		if(@worlds[@from]['mode'] == 'survival') {
			_store_pstate(@event['player'], 'survival');
			_clear_pstate(@event['player']);
		} else if(@worlds[@to]['mode'] == 'survival') {
			console('Loading survival inventory for '.@event['player'].' coming from '.@from.'.', false);
			_get_pstate(@event['player'], 'survival');
		} else {
			_clear_pstate(@event['player']);
		}
		if(@worlds[@to]['mode'] == 'adventure') {
			_equip_park();
		}
	}
}

bind(player_spawn, array('priority': 'LOWEST'), null, @event) {
	if(@event['bed_spawn'] && _is_survival_world(@event['location']['world'])) {
		// workaround some issues with players spawning in the wrong world but at the right coords
		@pdata = _pdata(@event['player']);
		if(array_index_exists(@pdata, 'survival')
		&& array_index_exists(@pdata['survival'], 'bed')
		&& is_array(@pdata['survival']['bed'])
		&& @pdata['survival']['bed'][3] != @event['location']['world']) {
			console(@event['player'].' respawned at the wrong world. Fixing...', false);
			modify_event('location', get_spawn(@event['location']['world']));
		}
	} else if(@event['location']['world'] == 'custom') {
		set_timeout(50, closure(){
			_equip_park();
		});
	}
}

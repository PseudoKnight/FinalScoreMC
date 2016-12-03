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
			_clear_pstate(@event['player'], @worlds[@to]['mode']);
		} else if(@worlds[@to]['mode'] == 'survival') {
			console('Loading survival inventory for '.@event['player'].' coming from '.@from.'.', false);
			_get_pstate(@event['player'], 'survival');
		} else {
			_clear_pstate(@event['player'], @worlds[@to]['mode']);
		}
	}
}

bind(player_spawn, array('priority': 'LOWEST'), null, @event) {
	@world = @event['location']['world'];
	if(@event['bed_spawn'] && _is_survival_world(@world)) {
		// workaround some issues with players spawning in the wrong world but at the right coords
		@pdata = _pdata(@event['player']);
		if(array_index_exists(@pdata, 'survival')
		&& array_index_exists(@pdata['survival'], 'bed')
		&& is_array(@pdata['survival']['bed'])) {
			@bed = @pdata['survival']['bed'];
			@spawn = @event['location'];
			if(@bed[0] != integer(@spawn[0])
			|| @bed[1] != integer(@spawn[1])
			|| @bed[2] != integer(@spawn[2])
			|| @bed[3] != @world) {
				console(@event['player'].' respawned at '.@spawn.' but has bed set to '.@bed
						.'. Adjusting to current world\'s spawn...', false);
				modify_event('location', get_spawn(@world));
			}
		}
	} else if(@world == 'custom') {
		set_timeout(50, closure(){
			_equip_kit();
		});
	}
}

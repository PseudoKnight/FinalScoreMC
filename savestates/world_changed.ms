bind(world_changed, null, null, @event) {
	@to = @event['to'];
	@from = @event['from'];
	@worlds = _worlds_config();
	@fromMode = @worlds[@from]['mode'];
	@toMode = @worlds[@to]['mode'];
	if(@fromMode != @toMode) {
		# let's swap inventory
		close_pinv();
		if(@toMode == pmode()) {
			if(@toMode == 'survival' || @toMode == 'adventure') {
				set_pflight(false);
			}
		} else {
			set_pmode(@toMode);
		}
		include('util.library/storage.ms');
		if(@fromMode == 'survival') {
			_store_pstate(@event['player'], 'survival');
			_clear_pstate(@event['player'], @toMode);
		} else if(@toMode == 'survival') {
			console('Loading survival inventory for '.@event['player'].' coming from '.@from.'.', false);
			_get_pstate(@event['player'], 'survival');
		} else {
			_clear_pstate(@event['player'], @toMode);
		}
	}
}

bind(player_spawn, array('priority': 'LOWEST'), null, @event) {
	@world = @event['location']['world'];
	if(!@event['bed_spawn']) {
		@pdata = _pdata(player());
		if(array_index_exists(@pdata, 'homes') && array_index_exists(@pdata['homes'], @world)) {
			@home = @pdata['homes'][@world];
			@home[1] += 1;
			modify_event('location', @home);
		} else {
			@worlds = _worlds_config();
			if(array_index_exists(@worlds[@world], 'respawn')) {
				modify_event('location', get_spawn(@worlds[@world]['respawn']));
			} else {
				modify_event('location', get_spawn(@world));
			}
		}
	}
	if(!_is_survival_world(@world)) {
		set_timeout(50, closure(){
			_equip_kit(to_lower(pmode()));
		});
	}
}

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
	if(@event['bed_spawn'] && _is_survival_world(@world)) {
		// workaround some issues with players spawning in the wrong world but at the right coords
		@spawn = @event['location'];
		@pbed = pbed_location(@event['player']);
		if(@pbed[0] + 0.5 != @spawn[0]
		|| @pbed[1] != integer(@spawn[1])
		|| @pbed[2] + 0.5 != @spawn[2]
		|| @pbed[3] != @world) {
			@pdata = _pdata(@event['player']);
			@bed = null;
			if(array_index_exists(@pdata, 'survival')
			&& array_index_exists(@pdata['survival'], 'bed')) {
				@bed = @pdata['survival']['bed'];
			}
			console(@event['player'].' respawned at '.@spawn, false);
			console(@event['player'].' pdata bed set to '.@bed, false);
			console(@event['player'].' pbed set to '.@pbed, false);
			modify_event('location', get_spawn(@world));
		}
	} else if(@world == 'custom') {
		set_timeout(50, closure(){
			_equip_kit();
		});
	}
}

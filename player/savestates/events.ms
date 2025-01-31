bind('world_changed', null, null, @event) {
	@to = @event['to'];
	@from = @event['from'];
	@worlds = _worlds_config();
	@fromGroup = @worlds[@from]['group'];
	@toGroup = @worlds[@to]['group'];
	if(@fromGroup != @toGroup) {
		# swap inventory
		close_pinv();
		@toMode = @worlds[@to]['mode'];
		if(@toMode == pmode()) {
			if(@toMode == 'SURVIVAL' || @toMode == 'ADVENTURE') {
				set_pflight(false);
			}
		} else {
			set_pmode(@toMode);
			if(extension_exists('CHDynmap')) {
				dm_set_pvisible(true);
			}
		}
		if(@fromGroup == 'dev') {
			@session = _psession(player());
			@session['devInventory'] = pinv();
		}
		include('util.library/storage.ms');
		if(@fromGroup == 'survival') {
			_store_pstate(@event['player'], 'survival');
			_clear_pstate(@event['player'], @toGroup);
		} else if(@toGroup == 'survival') {
			_get_pstate(@event['player'], 'survival');
		} else {
			_clear_pstate(@event['player'], @toGroup);
		}
	}
}

bind('player_spawn', array('priority': 'LOW'), null, @event) {
	@world = pworld(); // This gets the world the player died in, which is not always the same as the respawn world.
	if(!@event['bed_spawn'] && _is_survival_world(@world)) {
		@worlds = _worlds_config();
		if(array_index_exists(@worlds[@world], 'respawn')) {
			@world = @worlds[@world]['respawn'];
		}
		@pdata = _pdata(player());
		if(array_index_exists(@pdata, 'homes') && array_index_exists(@pdata['homes'], @world)) {
			@home = @pdata['homes'][@world][];
			@home[1] += 1;
			modify_event('location', @home);
		} else {
			modify_event('location', get_spawn(@world));
		}
	}
	if(!_is_survival_world(@world)) {
		set_timeout(50, closure(){
			_equip_kit();
		});
	}
}

bind('player_teleport', array('priority': 'HIGH'), null, @event) {
	@fromWorld = @event['from']['world'];
	@toWorld = @event['to']['world'];
	
	if(@fromWorld != @toWorld) {
		@worlds = _worlds_config();
		@fromGroup = @worlds[@fromWorld]['group'];
		@toGroup = @worlds[@toWorld]['group'];
		if(@fromGroup != @toGroup) {
			if(@event['type'] == 'SPECTATE') {
				cancel();
				die(color('yellow').'You cannot spectate a player not in this dimension.');
			}
			
			@pdata = _pdata(player());
			if(array_index_exists(@pdata, @toGroup) && array_index_exists(@pdata[@toGroup], 'loc')) {
				@loc = @pdata[@toGroup]['loc'];
				if(!_world_allows_teleports(@loc[3])) {
					// Restoring their last location within that worldgroup since they were not allowed to teleport out
					// of it except to another worldgroup
					modify_event('to', @loc);
				}
			}
			
			if(@fromWorld != 'shard') { // temporary world, do not save location
				set_timeout(50, closure(){
					if(!array_index_exists(@pdata, @fromGroup)) {
						@pdata[@fromGroup] = associative_array();
					}
					@pdata[@fromGroup]['loc'] = array(
						round(@event['from']['x'], 3),
						round(@event['from']['y'], 3) - 1,
						round(@event['from']['z'], 3),
						@fromWorld,
						round(@event['from']['yaw'], 1),
						round(@event['from']['pitch'], 1),
					);
					_store_pdata(player(), @pdata);
				});
			}
		}
	}
}

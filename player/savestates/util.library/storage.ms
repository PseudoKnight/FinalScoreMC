proc _get_pstate(@player, @state) {
	@pdata = _pdata(@player);
	if(!array_index_exists(@pdata, @state)) {
		console('WARNING: No survival state for '.@player.'.', false);
		return();
	}
	@pstate = @pdata[@state];
	
	if(array_index_exists(@pstate, 'inv') && @pstate['inv']) {
		try {
			if(is_array(@pstate['inv'])) {
				_clear_pinv(@player);
				set_pinv(@player, @pstate['inv']);
			} else {
				deserialize_pinv(@player, @pstate['inv']);
			}
		} catch(Exception @ex) {
			console('WARNING: Failed to load survival inventory for '.@player.'.', false);
			console(@ex['message'], false);
			if(array_index_exists(@pdata, 'inv')) {
				console(@pstate['inv'], false);
			}
			_clear_pinv(@player);
		}
	} else {
		_clear_pinv(@player);
	}

	if(array_index_exists(@pstate, 'ender') && @pstate['ender']) {
		try {
			if(is_array(@pstate['ender'])) {
				set_penderchest(@player, array_merge(array_resize(array(), 27), @pstate['ender']));
			} else {
				deserialize_penderchest(@player, @pstate['ender']);
			}
		} catch(Exception @ex) {
			console('WARNING: Failed to load survival enderchest for '.@player.'.', false);
			console(@ex['message'], false);
			if(array_index_exists(@pdata, 'ender')) {
				console(@pstate['ender'], false);
			}
			set_penderchest(@player, array_resize(array(), 27));
		}
	} else {
		set_penderchest(@player, array_resize(array(), 27));
	}

	try {
		if(array_index_exists(@pstate, 'bed') && is_array(@pstate['bed'])) {
			set_pbed_location(@player, @pstate['bed'], false);
		} else if(is_array(pbed_location(@player))) {
			if(array_index_exists(@pdata, 'homes') && array_index_exists(@pdata['homes'], pworld(@player))) {
				set_pbed_location(@player, @pdata['homes'][pworld(@player)]);
			} else {
				@spawn = get_spawn(pworld(@player));
				@spawn[1] -= 1;
				set_pbed_location(@player, @spawn);
				console('set bed to spawn');
			}
		}
	} catch(Exception @ex) {
		console('WARNING: Failed to load bed location for '.@player.'.', false);
		console(@ex['message'], false);
	}

	try {
		clear_peffects(@player);
		foreach(@effect in array_get(@pstate, 'effects', array())) {
			set_peffect(@player, @effect['id'], @effect['strength'], @effect['seconds'], @effect['ambient']);
		}
	} catch(Exception @ex) {
		console('WARNING: Failed to load effects for '.@player.'.', false);
		console(@ex['message'], false);
	}

	try {
		set_phealth(@player, array_get(@pstate, 'hp', 20));
		set_phunger(@player, array_get(@pstate, 'hunger', 20));
		set_psaturation(@player, array_get(@pstate, 'sat', 5));
		set_ptexp(@player, array_get(@pstate, 'texp', 0));
		set_ponfire(@player, array_get(@pstate, 'fire', 0));
	} catch(Exception @ex) {
		console('WARNING: Failed to load player state for '.@player.'.', false);
		console(@ex['message'], false);
	}
}

proc _store_pstate(@player, @state) {
	@pdata = _pdata(@player);
	if(!array_index_exists(@pdata, @state)) {
		@pdata[@state] = associative_array();
	}
	@pstate = @pdata[@state];

	@pstate['inv'] = serialize_pinv(@player);
	@pstate['ender'] = serialize_penderchest(@player);

	@pstate['hp'] = phealth(@player);
	@pstate['hunger'] = phunger(@player);
	@pstate['sat'] = psaturation(@player);
	@pstate['texp'] = ptexp(@player);
	@pstate['fire'] = ponfire(@player);
	@pstate['effects'] = get_peffect(@player);

	@bed = pbed_location(@player);
	if(@bed) {
		@pstate['bed'] = array_normalize(pbed_location(@player))[0..3];
	} else {
		@pstate['bed'] = null;
	}

	_store_pdata(@player, @pdata);
}

proc _clear_pstate(@player, @state) {
	_equip_kit(@player);
	@inv = array();
	array_resize(@inv, 27);
	set_penderchest(@player, @inv);
	set_pbed_location(@player, get_spawn(pworld(@player)));
	set_phealth(@player, 20);
	set_phunger(@player, 20);
	set_psaturation(@player, 5);
	set_ptexp(@player, 0);
	set_ponfire(@player, 0);
	clear_peffects(@player);
}

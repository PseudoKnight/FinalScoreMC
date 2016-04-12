proc _get_pstate(@player, @state) {
	@pdata = _pdata(@player);
	if(!array_index_exists(@pdata, @state)) {
		console('WARNING: No survival state for '.@player.'.');
		return();
	}
	@pstate = @pdata[@state];

	try {
		deserialize_pinv(@player, array_get(@pstate, 'inv', ''));
	} catch(Exception @ex) {
		console('WARNING: Failed to load survival inventory for '.@player.'.');
		console(@ex['message']);
		if(array_index_exists(@pdata, 'inv')) {
			console(@pstate['inv']);
		}
		_clear_pinv(@player);
	}

	try {
		deserialize_penderchest(@player, array_get(@pstate, 'ender', ''));
	} catch(Exception @ex) {
		console('WARNING: Failed to load survival enderchest for '.@player.'.');
		console(@ex['message']);
		if(array_index_exists(@pdata, 'ender')) {
			console(@pstate['inv']);
		}
		@inv = array();
		array_resize(@inv, 27);
		set_penderchest(@player, @inv);
	}

	try {
		if(array_index_exists(@pstate, 'bed') && is_array(@pstate['bed'])) {
			set_pbed_location(@player, @pstate['bed']);
		} else if(is_array(pbed_location(@player))) {
			set_pbed_location(@player, get_spawn(pworld(@player)));
		}
	} catch(Exception @ex) {
		console('WARNING: Failed to load bed location for '.@player.'.');
		console(@ex['message']);
	}

	try {
		foreach(@effect in get_peffect(@player)) {
			set_peffect(@player, @effect['id'], 0, 0);
		}
		foreach(@effect in array_get(@pstate, 'effects', array())) {
			set_peffect(@player, @effect['id'], @effect['strength'], @effect['seconds']);
		}
	} catch(Exception @ex) {
		console('WARNING: Failed to load effects for '.@player'.');
		console(@ex['message']);
	}

	try {
		set_phealth(@player, array_get(@pstate, 'hp', 20));
		set_phunger(@player, array_get(@pstate, 'hunger', 20));
		set_psaturation(@player, array_get(@pstate, 'sat', 5));
		set_ptexp(@player, array_get(@pstate, 'texp', 0));
		set_ponfire(@player, array_get(@pstate, 'fire', 0));
	} catch(Exception @ex) {
		console('WARNING: Failed to load player state for '.@player.'.');
		console(@ex['message']);
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

	@pstate['hp'] = pinfo(@player, 5);
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

proc _clear_pstate(@player) {
	_clear_pinv(@player);
	@inv = array();
	array_resize(@inv, 27);
	set_penderchest(@player, @inv);
	set_pbed_location(@player, get_spawn(pworld(@player)));
	set_phealth(@player, 20);
	set_phunger(@player, 20);
	set_ptexp(@player, 0);
	set_ponfire(@player, 0);
	_clear_peffects(@player);
}

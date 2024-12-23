proc _get_pstate(@player, @state) {
	@pdata = _pdata(@player);
	if(!array_index_exists(@pdata, @state)) {
		console(color('yellow')."WARNING: No survival state for @player.", false);
		return();
	}
	@pstate = @pdata[@state];
	
	if(array_index_exists(@pstate, 'inv') && @pstate['inv']) {
		try {
			deserialize_pinv(@player, @pstate['inv']);
		} catch(Exception @ex) {
			console(color('red').'ERROR: '.@ex['message'].' in '.@pstate['inv'].' for '.@player, false);
			clear_pinv(@player);
		}
	} else {
		clear_pinv(@player);
	}

	if(array_index_exists(@pstate, 'ender')) {
		// Legacy ender chest support
		if(@pstate['ender']) {
			try {
				deserialize_penderchest(@player, @pstate['ender']);
			} catch(Exception @ex) {
				console(color('red').'ERROR: '.@ex['message'].' in '.@pstate['ender'].' for '.@player, false);
				set_penderchest(@player, array_resize(array(), 27));
			}
		} else {
			set_penderchest(@player, array_resize(array(), 27));
		}
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
		console(color('red')."ERROR: Failed to load bed location for @player.", false);
		console(@ex['message'], false);
	}

	try {
		clear_peffects(@player);
		foreach(@effect in array_get(@pstate, 'effects', array())) {
			set_peffect(@player, @effect['id'], @effect['strength'], @effect['seconds'], @effect['ambient']);
		}
	} catch(Exception @ex) {
		console(color('red')."ERROR: Failed to load effects for @player.", false);
		console(@ex['message'], false);
	}

	try {
		set_phealth(@player, array_get(@pstate, 'hp', 20));
		set_phunger(@player, array_get(@pstate, 'hunger', 20));
		set_psaturation(@player, array_get(@pstate, 'sat', 5));
		set_ptexp(@player, array_get(@pstate, 'texp', 0));
		set_ponfire(@player, array_get(@pstate, 'fire', 0));
	} catch(Exception @ex) {
		console(color('red')."ERROR: Failed to load player state for @player.", false);
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
	array_remove(@pstate, 'ender');

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
	set_pbed_location(@player, get_spawn(pworld(@player)));
	set_phealth(@player, 20);
	set_phunger(@player, 20);
	set_psaturation(@player, 5);
	set_ptexp(@player, 0);
	set_ponfire(@player, 0);
	clear_peffects(@player);
}

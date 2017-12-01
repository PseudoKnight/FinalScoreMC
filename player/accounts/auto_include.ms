/*
	Gets an offline player's UUID for db access
*/
proc _get_uuid(@player, @autocomplete = true, @dashless = true) {
	if(ponline(@player)) {
		return(puuid(@player, @dashless));
	} else {
		@uuidDashed = get_value('players', @player);
		if(is_null(@uuidDashed)) {
			if(@autocomplete) {
				@uuids = get_values('players.'.@player);
				if(array_size(@uuids) > 0) {
					@uuidDashed = array_normalize(@uuids)[0];
				} else {
					throw('NotFoundException', 'Could not find player in database matching: '.@player);
				}
			} else {
				throw('NotFoundException', 'Player name not stored in database: '.@player);
			}
		}
		return(if(@dashless, replace(@uuidDashed, '-', ''), @uuidDashed));
	}
}

/*
	Gets stored data for account under given player name.
	Will return cached data if available.
*/
proc _pdata(@player, @autocomplete = true) {
	@player = to_lower(@player);
	@pdata = import('pdata.'.@player);
	if(is_null(@pdata)) {
		@uuid = _get_uuid(@player, @autocomplete);
		@pdata = _pdata_by_uuid(@uuid);
		if(ponline(@player)) {
			export('pdata.'.@player, @pdata);
		}
	}
	return(@pdata);
}

/*
	Gets stored data for account under given dashless UUID.
	Always returns stored data, not cached.
*/
proc _pdata_by_uuid(@uuid) {
	@pdata = get_value('uuids', @uuid);
	if(is_null(@pdata)) {
		throw('NotFoundException', 'User data not stored in database: '.@uuid);
	}
	return(@pdata);
}

/*
	Sets player data
*/
proc _store_pdata(@player, @data) {
	if(!is_array(@data), return());
	@player = to_lower(@player);
	@uuid = _get_uuid(@player);
	x_new_thread('storePlayerData', closure(){
		store_value('uuids', @uuid, @data);
	});
}

/*
	Returns the amount of coins a player has
*/
proc _acc_balance(@player) {
	try {
		@pdata = _pdata(@player);
	} catch(NotFoundException @ex) {
		return(0);
	}
	if(!array_index_exists(@pdata, 'coins')) {
		return(100);
	} else {
		return(@pdata['coins']);
	}
}

/*
	Add an amount to a player's coin balance
*/
proc _acc_add(@player, @amount) {
	try {
		@pdata = _pdata(@player);
	} catch(NotFoundException @ex) {
		return(false);
	}
	if(!array_index_exists(@pdata, 'coins')) {
		@pdata['coins'] = 100; // default
	}
	@pdata['coins'] += @amount;
	_store_pdata(@player, @pdata);
	return(true);
}

/*
	Subtracts an amount from a player's coin balance
*/
proc _acc_subtract(@player, @amount) {
	try {
		@pdata = _pdata(@player);
	} catch(NotFoundException @ex) {
		return(false);
	}
	if(!array_index_exists(@pdata, 'coins')) {
		@pdata['coins'] = 100;
	}
	@pdata['coins'] -= @amount;
	_store_pdata(@player, @pdata);
	return(true);
}

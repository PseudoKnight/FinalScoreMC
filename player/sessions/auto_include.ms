/*
	Gets current session data for player
*/
proc _psession(@player) {
	if(!@player) {
		@player = player();
	}
	@session = import('session.'.@player);
	if(is_null(@session)) {
		@session = array('activity': null);
		export('session.'.@player, @session);
	}
	return(@session);
}

/*
	Sets the activity for the player
*/
proc _set_pactivity(@player, @activity, @overrideable = false) {
	@session = _psession(@player);
	if(@session['activity'] && @activity && !array_index_exists(@session, 'passive')) {
		return(false);
	}
	@session['activity'] = @activity;
	if(@overrideable) {
		@session['passive'] = true;
	} else {
		array_remove(@session, 'passive');
	}
	try {
		if(@activity) {
			set_list_name(@player, color('gray').@activity.' '.display_name(@player));
		} else {
			set_list_name(@player, display_name(@player));
		}
	} catch(PlayerOfflineException @ex) {
		// if in a player_quit event, setting list name will throw offline exception even though ponline() returns true
	}
	return(true);
}

proc _pbusy(@player) {
	if(!@player) {
		@player = player();
	}
	@session = _psession(@player);
	return(@session['activity'] && !array_index_exists(@session, 'passive'));
}

# DeadboltHelper
# Updates out-dated names on [private] signs

proc _get_deadbolt(@loc) {
	try {
		@signtext = get_sign_text(@loc);
	} catch(RangeException @ex) {
		return(null);
	}
	if(!reg_match('(?i)^(\\u00A7[0-9a-f])?\\[private\\]$', @signtext[0])) {
		return(null);
	}
	return(@signtext);
}

bind(player_interact, null, array('block': data_values('wallsign')), @e) {
	if(@db = _get_deadbolt(@e['location'])) {
		@changed = false;
		for(@i = 1, @i < 4, @i++) {
			if(@db[@i] === '' || @db[@i][0] === '[' || @db[@i] == player()) {
				continue();
			}
			try {
				@pdata = _pdata(@db[@i], (length(@db[@i]) == 15));
			} catch(NotFoundException @ex) {
				continue();
			}
			if(@pdata['name'] != @db[@i]) {
				@newplayer = @pdata['name'];
				@db[@i] = substr(@newplayer, 0, if(length(@newplayer) > 15, 15, length(@newplayer)));
				@changed = true;
			}
		}
		if(@changed) {
			set_sign_text(@e['location'], @db);
		}
	}
}

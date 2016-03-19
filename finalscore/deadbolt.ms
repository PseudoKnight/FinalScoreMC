# DeadboltHelper
# Automatically locks chests when right-clicking with sign.
# This feature already exists in Deadbolt, however,
# this allows me to customize which blocks I want to auto-protect with signs.
# DEPENDENCIES:
# _relative() procedure

proc _get_deadbolt(@loc) {
	try(
		@signtext = get_sign_text(@loc);
	,
		return(null);
	);
	if(!reg_match('(?i)^(\\u00A7[0-9a-f])?\\[private\\]$', @signtext[0])) {
		return(null);
	}
	return(@signtext);
}

bind(player_interact, null, array('button': 'right', 'item': 323), @e) {
	if(@e['action'] !== 'right_click_block' || pinfo(player(), 11) || !pinfo(player(), 6) != @e['item']) {
		die();
	}

	@blockid = split(':', @e['block'])[0]
	if((@blockid == 54 || @blockid == 146)
	&& sk_can_build(@e['location'])) {
		cancel();
		foreach(@dir in array('north', 'south', 'east', 'west')) {
			@checkblock = _relative(@e['location'], @dir)
			if(_get_deadbolt(@checkblock)) {
				die(color('red').'Chest already protected.');
			} else if(@blockid == split(':', get_block_at(@checkblock))[0]) {
				foreach(@recdir in array('north', 'south', 'east', 'west')) {
					if(_get_deadbolt(_relative(@checkblock, @recdir))) {
						die(color('red').'Chest already protected.');
					}
				}
			}
		}
		switch(@e['facing']) {
		case 'north':
			@data = 2
		case 'south':
			@data = 3
		case 'west':
			@data = 4
		case 'east':
			@data = 5
		default:
			die()
		}
		@location = _relative(@e['location'], @e['facing'])
		set_block_at(@location, '68:'.@data)
		set_sign_text(@location, array(
			color('dark_red').'[PRIVATE]',
			if(length(player()) > 15, substr(player(), 0, 15), player()),
			'',
			'',
		))
		@slot = pinv(player(), null)
		if(@slot['qty'] == 1) {
			set_pinv(array(null: null))
		} else {
			@slot['qty'] = @slot['qty'] - 1
			set_pinv(array(null: @slot))
		}
		cancel()
	}
}

bind(player_interact, null, array('block': data_values('wallsign')), @e) {
	if(@db = _get_deadbolt(@e['location'])) {
		@changed = false;
		for(@i = 1, @i < 4, @i++) {
			if(@db[@i] === '' || @db[@i][0] === '[' || @db[@i] == player()) {
				continue();
			}
			try(@pdata = _pdata(@db[@i], (length(@db[@i]) == 15)), continue());
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

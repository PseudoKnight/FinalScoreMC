# DeadboltHelper
# Updates out-dated names on [private] signs
bind('player_interact', null, null, @event) {
	if(!@event['block'] || !string_ends_with(@event['block'], 'WALL_SIGN')) {
		die();
	}
	@sign = null;
	@loc = @event['location'];
	try {
		@sign = get_sign_text(@loc);
	} catch(RangeException @ex) {
		die(); // wallsign isn't a sign
	}
	if(reg_match('(?i)^(\\u00A7[0-9a-f])?\\[private\\]$', @sign[0])) {
		for(@i = 1, @i < 4, @i++) {
			if(@sign[@i] === '' || @sign[@i][0] === '[' || @sign[@i] == player()) {
				continue();
			}
			@pdata = null;
			try {
				@pdata = _pdata(@sign[@i], (length(@sign[@i]) == 15));
			} catch(NotFoundException @ex) {
				continue();
			}
			if(@pdata['name'] != @sign[@i]) {
				@newplayer = @pdata['name'];
				@sign[@i] = substr(@newplayer, 0, if(length(@newplayer) > 15, 15, length(@newplayer)));
				set_sign_text(@loc, @sign);
				play_sound(@loc, array('sound': 'BLOCK_WOOD_PLACE'));
				play_sound(@loc, array('sound': 'BLOCK_FIRE_EXTINGUISH', 'pitch': 2));
				@facing = get_blockdata(@loc)['facing'];
				spawn_particle(location_shift(location_shift(@loc, @facing, -1), 'up', 0.5), 'LAVA');
			}
		}
	}
}

# colorize signs
bind('sign_changed', null, null, @event) {
	if(pmode() === 'CREATIVE')  {
		modify_event('text', array(
			0: colorize(@event['text'][0]),
			1: colorize(@event['text'][1]),
			2: colorize(@event['text'][2]),
			3: colorize(@event['text'][3]),
		));
	}
}

/*
	Updates out-dated names on [private] protection signs
	and open existing signs.
 */
bind('player_interact', null, array(hand: 'MAIN_HAND', button: 'right'), @event) {
	if(@event['block'] && string_ends_with(@event['block'], 'SIGN') && !psneaking()) {
		@sign = null;
		@loc = @event['location'];
		try {
			@sign = get_sign_text(@loc);
		} catch(RangeException @ex) {
			die(); // sign is not a sign
		}
		if(string_ends_with(@event['block'], 'WALL_SIGN') && reg_match('(?i)^(\\u00A7[0-9a-f])?\\[private\\]$', @sign[0])) {
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
					play_sound(@loc, array(sound: 'BLOCK_WOOD_PLACE'));
					play_sound(@loc, array(sound: 'BLOCK_FIRE_EXTINGUISH', pitch: 2));
					@facing = get_blockdata(@loc)['facing'];
					spawn_particle(location_shift(location_shift(@loc, @facing, -1), 'up', 0.5), 'LAVA');
				}
			}
		}

		if(sk_can_build(@loc) && pmode() == 'CREATIVE' && !is_sign_waxed(@loc)
		&& (!@event['item'] || (!string_ends_with(@event['item']['name'], 'DYE') && @event['item']['name'] != 'GLOW_INK_SAC'))) {
			@colorCodes = false;
			foreach(@i: @line in @sign) {
				if(string_position(@line, '\u00A7') != -1) {
					@sign[@i] = replace(@line, '\u00A7', '&');
					@colorCodes = true;
				}
			}
			if(@colorCodes) {
				cancel();
				set_sign_text(@loc, @sign);
				set_timeout(50, closure(){
					open_sign(@loc);
				});
			}
		}
	}
}
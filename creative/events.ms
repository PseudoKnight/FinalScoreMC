# colorize signs
bind(sign_changed, null, null, @event) {
	if(pmode() === 'CREATIVE')  {
		modify_event('text', array(
			0: colorize(@event['text'][0]),
			1: colorize(@event['text'][1]),
			2: colorize(@event['text'][2]),
			3: colorize(@event['text'][3]),
		));
	}
}

# Allow command block placement for builders
proc _place_command_block(@loc, @face, @block) {
	if(has_permission('group.builder')
	&& !_is_survival_world(@loc['world'])) {
		@clicked = split(':', get_block_at(@loc))[0];
		if(pinfo(player(), 11) || (@clicked != '137' && @clicked != '210' && @clicked != '211')) {
			@loc = _relative(@loc, @face);
			if(sk_can_build(@loc)) {
				@data = 0;
				switch(@face) {
					case 'up':
						@data = 1;
					case 'north':
						@data = 2;
					case 'south':
						@data = 3;
					case 'west':
						@data = 4;
					case 'east':
						@data = 5;
				}
				set_block_at(@loc, split(':', @block)[0].':'.@data);
			}
		}
	}
}

bind(player_interact, null, associative_array('button': 'right', 'item': 137), @event) {
	if(@event['action'] === 'right_click_block') {
		_place_command_block(@event['location'], @event['facing'], @event['item']);
	}
}

bind(player_interact, null, associative_array('button': 'right', 'item': 211), @event) {
	if(@event['action'] === 'right_click_block') {
		_place_command_block(@event['location'], @event['facing'], @event['item']);
	}
}

# Allow breaking command blocks for builders
bind(block_break, null, associative_array('type': 137), @event) {
	if(!pisop() && sk_can_build(@event['location'])) {
		set_block_at(@event['location'], 0);
		make_effect(@event['location'], 'STEP_SOUND:'.@event['block']['type']);
	}
}

bind(block_break, null, associative_array('type': 211), @event) {
	if(!pisop() && sk_can_build(@event['location'])) {
		set_block_at(@event['location'], 0);
		make_effect(@event['location'], 'STEP_SOUND:'.@event['block']['type']);
	}
}

# Display command to builders
proc _msg_block_command(@loc) {
	@cmd = get_block_command(@loc);
	@args = parse_args(@cmd);
	if(array_size(@args) > 1 && (@args[0] == '/runalias' || @args[0] == 'runalias')) {
		@cmd = array_implode(@args[cslice(1, array_size(@args) - 1)], ' ');
	}
	@cmd = replace(@cmd, '\\', '\\\\');
	@cmd = replace(@cmd, '"', '\\u0022');
	runas('~console', '/tellraw '.player().' ["",{"text":"[COPY]","clickEvent":{"action":"suggest_command","value":"/scb '.@cmd.'"}},{"text":" '.@cmd.'"}]');
}

bind(player_interact, null, associative_array('button': 'right', 'block': 137), @event) {
	if(!pisop() && !pinfo(player(), 11) && @event['hand'] == 'main_hand' && has_permission('group.builder')){
		_msg_block_command(@event['location']);
	}
}

bind(player_interact, null, associative_array('button': 'right', 'block': 211), @event) {
	if(!pisop() && !pinfo(player(), 11) && @event['hand'] == 'main_hand' && has_permission('group.builder')){
		_msg_block_command(@event['location']);
	}
}

# Don't instant-break noteblocks in creative mode if not sneaking
bind(player_interact, null, array('block': 25, 'button': 'left'), @event) {
	if(pmode() === 'CREATIVE' && !pinfo(player(), 11)) {
		// It won't break if in survival, and it'll play the note if we don't cancel
		@flying = pinfo(player(), 18);
		set_pmode('SURVIVAL');
		set_timeout(50, closure(){
			// return the player to creative
			set_pmode('CREATIVE');
			set_pflying(@flying);
			// The block will appear as air due to the client-side block-break,
			// so resend the noteblock
			psend_block_change(@event['location'], 25);
		});
	}
}

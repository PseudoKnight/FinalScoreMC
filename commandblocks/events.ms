# Allow command block placement for builders
proc _place_command_block(@loc, @face, @block) {
	if(!pisop() && has_permission('group.builder')
	&& !_is_survival_world(@loc['world'])) {
		@clicked = split(':', get_block_at(@loc))[0];
		if(psneaking() || (@clicked != '137' && @clicked != '210' && @clicked != '211')) {
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
	runas('~console', '/tellraw '.player().' ["",'
			.'{"text":"[REDSTONE |","clickEvent":{"action":"run_command","value":"/scbauto false"}},'
			.'{"text":" ALWAYS]","clickEvent":{"action":"run_command","value":"/scbauto true"}},'
			'{"text":" [CONDITIONAL]","clickEvent":{"action":"run_command","value":"/scbconditional"}},'
			.'{"text":" [TYPE]","clickEvent":{"action":"run_command","value":"/scbtype"}},'
			.'{"text":" [COPY]","clickEvent":{"action":"suggest_command","value":"/scb '.@cmd.'"}},'
			.'{"text":"\n'.@cmd.'"}]');
}

bind(player_interact, null, associative_array('button': 'right', 'block': 137), @event) {
	if(!pisop() && !psneaking() && @event['hand'] == 'main_hand' && has_permission('group.builder')){
		_msg_block_command(@event['location']);
	}
}

bind(player_interact, null, associative_array('button': 'right', 'block': 211), @event) {
	if(!pisop() && !psneaking() && @event['hand'] == 'main_hand' && has_permission('group.builder')){
		_msg_block_command(@event['location']);
	}
}

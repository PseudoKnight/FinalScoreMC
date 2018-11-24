# Allow command block placement for builders
proc _place_command_block(@loc, @face, @block) {
	if(!pisop() && has_permission('command.cb')
	&& !_is_survival_world(@loc['world'])) {
		@clicked = get_block(@loc);
		if(psneaking() || (@clicked != 'COMMAND_BLOCK' && @clicked != 'CHAIN_COMMAND_BLOCK' && @clicked != 'REPEATING_COMMAND_BLOCK')) {
			@loc = location_shift(@loc, @face);
			if(sk_can_build(@loc)) {
				play_sound(@loc, array('sound': 'BLOCK_STONE_PLACE'));
				set_blockdata_string(@loc, to_lower(@block).'[facing='.to_lower(@face).',conditional=false]');
			}
		}
	}
}

bind('player_interact', null, associative_array('button': 'right', 'itemname': 'COMMAND_BLOCK'), @event) {
	if(@event['action'] === 'right_click_block') {
		_place_command_block(@event['location'], @event['facing'], @event['item']['name']);
	}
}

bind('player_interact', null, associative_array('button': 'right', 'itemname': 'CHAIN_COMMAND_BLOCK'), @event) {
	if(@event['action'] === 'right_click_block') {
		_place_command_block(@event['location'], @event['facing'], @event['item']['name']);
	}
}

# Allow breaking command blocks for builders
bind('block_break', null, array('block': 'COMMAND_BLOCK'), @event) {
	console('CommandBlock @ '.array_implode(array_normalize(@event['location'])[0..3]).' : '.get_block_command(@event['location']));
	if(!pisop() && sk_can_build(@event['location'])) {
		set_block(@event['location'], 'AIR');
		play_sound(@event['location'], array('sound': 'BLOCK_STONE_BREAK'));
		spawn_particle(@event['location'], array('particle': 'BLOCK_CRACK', 'block': @event['block']));
	}
}

bind('block_break', null, array('block': 'CHAIN_COMMAND_BLOCK'), @event) {
	console('CommandBlock @ '.array_implode(array_normalize(@event['location'])[0..3]).' : '.get_block_command(@event['location']));
	if(!pisop() && sk_can_build(@event['location'])) {
		set_block(@event['location'], 'AIR');
		play_sound(@event['location'], array('sound': 'BLOCK_STONE_BREAK'));
		spawn_particle(@event['location'], array('particle': 'BLOCK_CRACK', 'block': @event['block']));
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
			.'{"text":"\\n'.@cmd.'"}]');
}

bind('player_interact', null, associative_array('button': 'right', 'block': 'COMMAND_BLOCK'), @event) {
	if(!pisop() && !psneaking() && @event['hand'] == 'main_hand' && has_permission('command.cb')){
		_msg_block_command(@event['location']);
	}
}

bind('player_interact', null, associative_array('button': 'right', 'block': 'CHAIN_COMMAND_BLOCK'), @event) {
	if(!pisop() && !psneaking() && @event['hand'] == 'main_hand' && has_permission('command.cb')){
		_msg_block_command(@event['location']);
	}
}

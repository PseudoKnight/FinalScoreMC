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
bind(player_interact, null, array('button': 'right', 'item': 137), @event) {
	if(has_permission('group.builder')
	&& @event['action'] === 'right_click_block'
	&& pinfo(player(), 11)
	&& !_is_survival_world(@event['location']['world'])) {
		@loc = _relative(@event['location'], @event['facing']);
		if(sk_can_build(@loc)) {
			set_block_at(@loc, 137);
		}
	}
}

# Don't instant-break noteblocks in creative mode if not sneaking
bind(player_interact, null, array('block': 25, 'button': 'left'), @event) {
	if(pmode() === 'CREATIVE' && !pinfo(player(), 11)) {
		// It won't break if in survival, and it'll play the note if we don't cancel
		set_pmode('SURVIVAL');
		set_timeout(50, closure(){
			// return the player to creative
			set_pmode('CREATIVE');
			// The block will appear as air due to the client-side block-break,
			// so resend the noteblock
			psend_block_change(@event['location'], 25);
		});
	}
}

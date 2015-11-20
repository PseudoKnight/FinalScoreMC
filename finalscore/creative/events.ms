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
	&& @event['block'] !== '137'
	&& !_is_survival_world(@event['location']['world'])) {
		@loc = _relative(@event['location'], @event['facing']);
		if(sk_can_build(@loc)) {
			set_block_at(@loc, 137);
		}
	}
}
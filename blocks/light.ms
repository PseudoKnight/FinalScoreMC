// Right-click to adjust light block light level
bind('player_interact', null, array(block: 'LIGHT', button: 'right'), @event) {
	if(!pisop()) {
		cancel();
		@light = get_blockdata(@event['location']);
		@light['level'] = (@light['level'] + 1) % 16;
		set_blockdata(@event['location'], @light);
	}
}
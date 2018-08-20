bind('entity_death', null, null, @event) {
	if(string_starts_with(@event['location']['world'], 'outworld')) {
		@cause = @event['cause'];
		@player = null;
		if(@cause['cause'] == 'ENTITY_ATTACK') {
			if(ponline(@cause['damager'])) {
				@player = @cause['damager'];
			}
		} else if(array_index_exists(@cause, 'shooter') && ponline(@cause['shooter'])) {
			@player = @cause['shooter'];
		}
		if(@player) {
			@width = get_world_border('outworld')['width'];
			if(@width < 8192) {
				@width = ceil(@width + 2);
				set_world_border('outworld', array('width': @width, 'seconds': 1));
				set_world_border('outworld_nether', array('width': @width / 8, 'seconds': 1));
				action_msg(@player, color('green').'WorldBorder++ ('.@width.')');
				play_sound(ploc(@player), array('sound': 'BLOCK_ENCHANTMENT_TABLE_USE', 'pitch': 0.5))
			}
		}
	}
}

bind('entity_death', null, null, @event, @border = _get_worldborder('outworld')) {
	if(@border && string_starts_with(@event['location']['world'], 'outworld')) {
		@width = get_world_border('outworld')['width'];
		if(@width >= @border['radiusX'] * 2) {
			die();
		}

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
			@exp = @event['xp'];
			if(@event['type'] == 'WITHER') {
				@exp = 500;
			} else if(@event['type'] == 'ENDER_DRAGON') {
				@exp = 1000;
			}
			@cost = @width / 1000;
			@amount = @exp - @cost;
			if(@amount > 0) {
				@width += @amount;
				set_world_border('outworld', array('width': @width, 'seconds': 1));
				set_world_border('outworld_nether', array('width': @width / 8, 'seconds': 1));
				action_msg(@player, color('green').'WorldBorder ++ '.round(@amount, 1).' (width: '.integer(@width).')');
				play_sound(ploc(@player), array('sound': 'BLOCK_ENCHANTMENT_TABLE_USE', 'pitch': 0.5))
			}
		}
	}
}

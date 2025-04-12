/*
	Expands the worldborder for the Outworld when exp is dropped from kills/blocks.
	Distance expanded is determined by the amount of exp dropped, minus world-width divided by 1000.
 */
bind('entity_death', null, null, @event, @border = _get_worldborder('outworld')) {
	if(@border && string_starts_with(@event['location']['world'], 'outworld')) {
		@width = get_world_border('outworld')['width'];
		if(@width >= @border['radiusX'] * 2) {
			die();
		}

		@cause = @event['cause'];
		@player = null;
		if(@cause['cause'] === 'ENTITY_ATTACK') {
			if(@cause['damagertype'] === 'PLAYER') {
				@player = @cause['damager'];
			}
		} else if(array_index_exists(@cause, 'shooter') && ponline(@cause['shooter'])) {
			@player = @cause['shooter'];
		}
		if(@player) {
			@amount = min(1000, @event['xp'] - @width / 1000);
			if(@amount >= 1) {
				@width = min(@width + @amount, @border['radiusX'] * 2);
				set_world_border('outworld', array(width: @width, seconds: 2));
				set_world_border('outworld_nether', array(width: @width / 4, seconds: 2));
				set_world_border('outworld_the_end', array(width: @width, seconds: 2));
				action_msg(@player, 'WorldBorder: '.integer(@width / 2).color('green').' +'.integer(@amount));
				play_sound(ploc(@player), array(sound: 'BLOCK_ENCHANTMENT_TABLE_USE', pitch: 0.5));
			}
		}
	}
}

bind('block_break', null, null, @event, @border = _get_worldborder('outworld')) {
	if(@border && string_starts_with(@event['location']['world'], 'outworld')) {
		@width = get_world_border('outworld')['width'];
		if(@width >= @border['radiusX'] * 2) {
			die();
		}
		@player = @event['player'];
		@amount = @event['xp'] - @width / 1000;
		if(@amount >= 1) {
			@width = min(@width + @amount, @border['radiusX'] * 2);
			set_world_border('outworld', array(width: @width, seconds: 2));
			set_world_border('outworld_nether', array(width: @width / 4, seconds: 2));
			set_world_border('outworld_the_end', array(width: @width, seconds: 2));
			action_msg(@player, 'WorldBorder: '.integer(@width / 2).color('green').' +'.integer(@amount));
			play_sound(ploc(@player), array(sound: 'BLOCK_ENCHANTMENT_TABLE_USE', pitch: 0.5));
		}
	}
}

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

# Don't instant-break noteblocks in creative mode if not sneaking
bind(player_interact, null, array('block': 25, 'button': 'left'), @event) {
	if(pmode() === 'CREATIVE' && !psneaking()) {
		// It won't break if in survival, and it'll play the note if we don't cancel
		set_pmode('SURVIVAL');
		set_pflight(true);
		set_pflying(true);
		set_timeout(50, closure(){
			// return the player to creative
			set_pmode('CREATIVE');
			// The block will appear as air due to the client-side block-break,
			// so resend the noteblock
			psend_block_change(@event['location'], 25);
		});
	}
}

# Dispenser handling
# Infinite dispensers on creative/game worlds
# Special behavior for other items (eg. place armor stands)
bind(block_dispense, null, array('type': 'DISPENSER'), @event, @ignored = array('BUCKET', 'WATER_BUCKET', 'LAVA_BUCKET')) {
	if(@event['item'] && array_contains(@ignored, @event['item']['name'])) {
		// Always ignore buckets
	} else if(!_is_survival_world(@event['location']['world'])) {
		if(!array_contains(sk_region_check_flag(@event['location'], 'blocked-cmds'), '/finitedispensers')) {
			try {
				@inv = get_inventory(@event['location']);
			} catch(CastException @ex) {
				die();
			}
			foreach(@i: @item in @inv) {
				if(@item && @item['qty'] < 64) {
					@item['qty'] = 64;
					queue_push(closure(){
						try {
							set_inventory_item(@event['location'], @i, @item);
						} catch(CastException @ex) {
							console('Could not refill dispenser at '. @event['location'], false);
						}
					});
					break();
				}
			}
		}
	}
	if(@event['item'] && @event['item']['name'] == 'ARMOR_STAND') {
		try {
			@inv = get_inventory(@event['location']);
		} catch(CastException @ex) {
			die();
		}
		cancel();
		@loc = @event['location'][];
		switch(split(':', get_block_at(@loc))[1]) {
			case '8':
				@loc['y'] -= 1;
			case '9':
				@loc['y'] += 1;
			case '10':
				@loc['z'] -= 1;
				@loc['yaw'] = 180;
			case '11':
				@loc['z'] += 1;
			case '12':
				@loc['x'] -= 1;
				@loc['yaw'] = 90;
			case '13':
				@loc['x'] += 1;
				@loc['yaw'] = 270;
		}
		@loc['x'] += 0.5;
		@loc['z'] += 0.5;
		spawn_entity('ARMOR_STAND', 1, @loc);
		set_timeout(50, closure(){
			set_inventory(@event['location'], @inv);
		});
	}
}

// Custom noteblock sounds
bind(note_play, null, null, @event) {
	cancel();
	@sound = 'NOTE_'.@event['instrument'];
	switch(split(':', get_block_at(_relative(@event['location'], 'down')))[0]) {
		case '79':
		case '174':
			@sound = 'ORB_PICKUP';
		case '145':
			@sound = 'ANVIL_LAND';
		case '159':
		case '172':
			@sound = 'NOTE_PLING';
		case '165':
			@sound = 'CHICKEN_EGG_POP';
		case '173':
			@sound = 'FIREWORK_BLAST';
		case '169':
			@sound = 'BLOCK_NOTE_CHIME';
		case '35':
			@sound = 'BLOCK_NOTE_GUITAR';
		case '82':
			@sound = 'BLOCK_NOTE_FLUTE';
		case '41':
			@sound = 'BLOCK_NOTE_BELL';
		case '216':
			@sound = 'BLOCK_NOTE_XYLOPHONE';
	}
	play_sound(@event['location'], array(
		'sound': @sound,
		'category': 'RECORDS',
		'pitch': _get_pitch(@event['tone'], @event['octave']),
		'volume': if(is_block_powered(@event['location']), 8, 1)
	));
	@event['location']['x'] += 0.5;
	@event['location']['z'] += 0.5;
	play_effect(_relative(@event['location'], 'up'), 'note');
}

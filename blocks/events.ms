# colorize signs
bind('sign_changed', null, null, @event) {
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
bind('player_interact', null, array('block': 'NOTE_BLOCK', 'button': 'left'), @event) {
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
			psend_block_change(@event['location'], 'NOTE_BLOCK');
		});
	}
}

# Dispenser handling
# Infinite dispensers on creative/game worlds
# Special behavior for other items (eg. place armor stands)
bind('block_dispense', null, array('type': 'DISPENSER'), @event, @ignored = array('BUCKET', 'WATER_BUCKET', 'LAVA_BUCKET')) {
	if(!@event['item'] || array_contains(@ignored, @event['item']['name'])) {
		die();
	}
	if(!_is_survival_world(@event['location']['world'])) {
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
						} catch(IllegalArgumentException @ex) {
							console('Could not refill dispenser at '. @event['location'], false);
						}
					});
					break();
				}
			}
		}
	}
	@type = @event['item']['name']
	if(@type == 'ARMOR_STAND') {
		try {
			@inv = get_inventory(@event['location']);
		} catch(CastException @ex) {
			die();
		}
		cancel();
		@loc = @event['location'][];
		@facing = reg_match('facing\\=([a-z]+)', get_blockdata_string(@loc))[1];
		switch(@facing) {
			case 'down':
				@loc['y'] -= 1;
			case 'up':
				@loc['y'] += 1;
			case 'north':
				@loc['z'] -= 1;
				@loc['yaw'] = 180;
			case 'south':
				@loc['z'] += 1;
			case 'west':
				@loc['x'] -= 1;
				@loc['yaw'] = 90;
			case 'east':
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
bind('note_play', null, null, @event) {
	cancel();
	@sound = '';
	switch(get_block(location_shift(@event['location'], 'down'))) {
		case 'ICE':
		case 'PACKED_ICE':
			@sound = 'ENTITY_EXPERIENCE_ORB_PICKUP';
		case 'ANVIL':
			@sound = 'BLOCK_ANVIL_LAND';
		case 'TERRACOTTA':
		case 'WHITE_TERRACOTTA':
		case 'ORANGE_TERRACOTTA':
		case 'YELLOW_TERRACOTTA':
		case 'RED_TERRACOTTA':
		case 'PURPLE_TERRACOTTA':
		case 'PINK_TERRACOTTA':
		case 'MAGENTA_TERRACOTTA':
		case 'LIME_TERRACOTTA':
		case 'GREEN_TERRACOTTA':
		case 'GRAY_TERRACOTTA':
		case 'CYAN_TERRACOTTA':
		case 'BROWN_TERRACOTTA':
		case 'BLUE_TERRACOTTA':
		case 'BLACK_TERRACOTTA':
		case 'LIGHT_GRAY_TERRACOTTA':
		case 'LIGHT_BLUE_TERRACOTTA':
			@sound = 'BLOCK_NOTE_BLOCK_PLING';
		case 'SLIME_BLOCK':
			@sound = 'ENTITY_CHICKEN_EGG';
		case 'COAL_BLOCK':
			@sound = 'ENTITY_FIREWORK_ROCKET_BLAST';
		case 'SEA_LANTERN':
			@sound = 'BLOCK_NOTE_BLOCK_CHIME';
		case 'SOUL_SAND':
			@sound = 'BLOCK_NOTE_BLOCK_COW_BELL';
		case 'IRON_BLOCK':
			@sound = 'BLOCK_NOTE_BLOCK_IRON_XYLOPHONE';
		default:
			@data = reg_match('instrument\\=([a-z]+)', get_blockdata_string(@event['location']));
			@sound = 'BLOCK_NOTE_BLOCK_'.@data[1];
	}
	play_sound(@event['location'], array(
		'sound': @sound,
		'category': 'RECORDS',
		'pitch': _get_pitch(@event['tone'], @event['octave']),
		'volume': if(is_block_powered(@event['location']), 8, 1)
	));
	@event['location']['x'] += 0.5;
	@event['location']['z'] += 0.5;
	spawn_particle(location_shift(@event['location'], 'up'), 'NOTE');
}

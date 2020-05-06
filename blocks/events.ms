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

# Player head effects
bind('player_interact', null, array('block': 'PLAYER_HEAD', 'button': 'right'), @event) {
	@loc = @event['location'];
	@owner = get_skull_owner(@loc);
	if(!@owner) {
		die();
	}
	@uuid = @owner['uuid'];

	// BURGER (Burger_guy)
	if(@uuid == '8e3d7b63-2a47-4c09-86c4-780e672b7af5') {
		@loc['x'] += 0.5;
		@loc['y'] += 0.2;
		@loc['z'] += 0.5;
		spawn_particle(@loc, array(
			'particle': 'ITEM_CRACK',
			'item': 'ROSE_BUSH',
			'count': 3,
			'xoffset': 0.75,
			'zoffset': 0.75,
		));
		play_sound(@loc, array('sound': 'ENTITY_GENERIC_EAT'));
	}

	// BEER (Thanauser)
	if(@uuid == '69bcc186-fe80-4635-a085-9cec311d8d9f') {
		@loc['x'] += 0.5;
		@loc['y'] += 0.6;
		@loc['z'] += 0.5;
		spawn_particle(@loc, array(
			'particle': 'BUBBLE_POP',
			'count': 2,
			'xoffset': 0.5,
			'zoffset': 0.5,
		));
		play_sound(@loc, array('sound': 'ENTITY_GENERIC_DRINK'));
		set_peffect(player(), 'nausea', 0, 4);
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

// Sets ender crystal beams to target nearby newly placed dragon eggs
bind('block_place', array('priority': 'LOW'), array('block': 'DRAGON_EGG'), @event) {
	@loc = @event['location'];
	@loc['x'] += 0.5;
	@loc['y'] -= 1.5;
	@loc['z'] += 0.5;
	foreach(@e in entities_in_radius(@event['location'], 32, 'ENDER_CRYSTAL')) {
		@target = entity_spec(@e)['beamtarget'];
		if(!@target || get_block(location_shift(@target, 'up', 2)) != 'DRAGON_EGG') {
			set_entity_spec(@e, array('beamtarget': @loc));
		}
	}
}

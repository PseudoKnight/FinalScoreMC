# Do not instant-break noteblocks in creative mode if not sneaking
bind('player_interact', null, array('block': 'NOTE_BLOCK', 'button': 'left'), @event) {
	if(pmode() === 'CREATIVE' && !psneaking()) {
		// It will not break if in survival, and it will play the note if we do not cancel
		set_pmode('SURVIVAL');
		set_pflight(true);
		set_pflying(true);
		set_timeout(1, closure(){
			// return the player to creative
			set_pmode('CREATIVE');
			// The block will appear as air due to the client-side block-break,
			// so resend the noteblock
			psend_block_change(@event['location'], get_blockdata_string(@event['location']));
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
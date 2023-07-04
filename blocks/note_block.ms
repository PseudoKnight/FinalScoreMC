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
bind('note_play', null, null, @event, @instruments = array(
	ICE: 'ENTITY_EXPERIENCE_ORB_PICKUP',
	PACKED_ICE: 'ENTITY_EXPERIENCE_ORB_PICKUP',
	ANVIL: 'BLOCK_ANVIL_LAND',
	TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	WHITE_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	ORANGE_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	YELLOW_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	RED_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	PURPLE_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	PINK_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	MAGENTA_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	LIME_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	GREEN_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	GRAY_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	CYAN_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	BROWN_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	BLUE_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	BLACK_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	LIGHT_GRAY_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	LIGHT_BLUE_TERRACOTTA: 'BLOCK_NOTE_BLOCK_PLING',
	SLIME_BLOCK: 'ENTITY_CHICKEN_EGG',
	COAL_BLOCK: 'ENTITY_FIREWORK_ROCKET_BLAST',
	SEA_LANTERN: 'BLOCK_NOTE_BLOCK_CHIME',
	SOUL_SAND: 'BLOCK_NOTE_BLOCK_COW_BELL',
	IRON_BLOCK: 'BLOCK_NOTE_BLOCK_IRON_XYLOPHONE',
)) {
	cancel();
	@sound = '';
	@block = get_block(location_shift(@event['location'], 'down'));
	if(array_index_exists(@instruments, @block)) {
		@sound = @instruments[@block];
	} else {
		@sound = 'BLOCK_NOTE_BLOCK_'.reg_match('instrument\\=([a-z]+)', get_blockdata_string(@event['location']))[1];
	}
	@pitch = _get_pitch(@event['tone'], @event['octave']);
	play_sound(@event['location'], array(
		sound: @sound,
		category: 'RECORDS',
		pitch: @pitch,
		volume: if(is_block_powered(@event['location']), 8, 1)
	));
	@event['location']['x'] += 0.5;
	@event['location']['y'] += 1.3;
	@event['location']['z'] += 0.5;
	spawn_particle(@event['location'], array(particle: 'NOTE', speed: 2.4, xoffset: @pitch - 0.5));
}
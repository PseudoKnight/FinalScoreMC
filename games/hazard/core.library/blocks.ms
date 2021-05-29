proc _hazard_add_block(@game, @location, @type) {
	if(!@type) {
		@location['type'] = get_blockdata_string(@location);
	} else {
		@location['type'] = @type;
	}
	@game['blocks'][] = @location;
}

proc _hazard_respawn_blocks(@game) {
	foreach(@block in @game['blocks']) {
		set_blockdata_string(@block, @block['type']);
	}
	@game['blocks'] = array();
}
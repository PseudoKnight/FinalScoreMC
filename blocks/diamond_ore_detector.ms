// Anti-xray helper for moderators
bind('block_break', null, array(block: 'DIAMOND_ORE'), @event) {
	if(!has_metadata(pworld(), 'survival')) {
		die();
	}
	@loc = @event['location'];
	set_timeout(1, closure(){ // right after event finished, so current block is gone
		@report = true;
		for(@x = @loc['x'] - 1, @x <= @loc['x'] + 1, @x++) {
			for(@y = @loc['y'] - 1, @y <= @loc['y'] + 1, @y++) {
				for(@z = @loc['z'] - 1, @z <= @loc['z'] + 1, @z++) {
					if(get_block(array(@x, @y, @z, pworld())) === 'DIAMOND_ORE') {
						@report = false;
					}
				}
			}
		}

		if(@report) {
			@msg = colorize('&c[!] '.display_name().'&r found diamonds');
			broadcast(@msg, 'group.moderator');
		}
	});
}
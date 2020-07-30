/*
	Block respawn anchor explosions in regions
 */
bind('player_interact', null, array('block': 'RESPAWN_ANCHOR', 'button': 'right'), @event) {
	if(world_info(pworld())['environment'] != 'NETHER' && sk_regions_at(@event['location'])) {
		if(!@event['item']) {
			cancel();
		} else {
			@charges = get_blockdata(@event['location'])['charges'];
			if(@charges > 0) {
				if(@charges == 4 || @event['item']['name'] != 'GLOWSTONE') {
					cancel();
				}
			}
		}
	}
}
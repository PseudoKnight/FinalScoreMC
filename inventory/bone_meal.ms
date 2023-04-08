// Bone meal regular vines
bind('player_interact', null, array(itemname: 'BONE_MEAL', button: 'right', hand: 'main_hand', block: 'VINE'), @event) {
	@mode = pmode();
	if(@mode == 'ADVENTURE' || @mode == 'SPECTATOR') {
		die();
	}
	@loc = @event['location'];
	@previousVine = get_blockdata(@loc);
	if(@previousVine['up'] && !(@previousVine['east'] || @previousVine['west'] || @previousVine['north'] || @previousVine['south'])) {
		die();
	}
	while(@loc['y'] > 0) {
		@loc = location_shift(@loc, 'down');
		@blockData = get_blockdata(@loc);
		if(@blockData['block'] == 'air') {
			spawn_particle(_center(@event['location']), array(particle: 'VILLAGER_HAPPY', count: 10, xoffset: 1, yoffset: 1, zoffset: 1));
			@previousVine['up'] = false;
			set_blockdata(@loc, @previousVine);
			if(pmode() == 'SURVIVAL') {
				@event['item']['qty']--;
				set_pinv(player(), null, @event['item']);
			}
			break();
		} else if(@blockData['block'] == 'vine') {
			@previousVine = @blockData;
		} else {
			break();
		}
	}
}
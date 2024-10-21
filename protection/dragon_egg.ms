// Prevent enderdragon egg teleportation in non-survival worlds
bind('player_interact', null, array(block: 'DRAGON_EGG'), @event) {
	if(!has_metadata(@event['location']['world'], 'survival')
	&& (@event['button'] === 'right' || pmode() !== 'CREATIVE')) {
		cancel();
	}
}
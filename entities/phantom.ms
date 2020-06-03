bind('creature_spawn', null, array('type': 'PHANTOM'), @event) {
	if(@event['location']['world'] != 'outworld' && @event['location']['world'] != 'custom') {
		cancel();
	}
}
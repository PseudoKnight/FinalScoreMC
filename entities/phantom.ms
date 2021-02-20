bind('creature_spawn', null, array(type: 'PHANTOM', reason: 'NATURAL'), @event) {
	if(@event['location']['world'] != 'outworld') {
		cancel();
	}
}
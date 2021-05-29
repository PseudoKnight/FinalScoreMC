# block skeleton trap horses in regions
bind('creature_spawn', null, array('reason': 'LIGHTNING', 'type': 'SKELETON_HORSE'), @event) {
	if(@event['location']['world'] != 'outworld' && sk_regions_at(@event['location'])) {
		cancel();
	}
}
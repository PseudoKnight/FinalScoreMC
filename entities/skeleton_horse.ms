# block skeleton trap horses in regions
bind('creature_spawn', null, array(reason: 'LIGHTNING', type: 'SKELETON_HORSE'), @event) {
	if(array_contains(sk_region_check_flag(@event['location'], 'deny-spawn'), 'minecraft:skeleton')) {
		cancel();
	}
}
# prevent enderpearls from damaging item frames and paintings
/*
	Protect item frames from ender pearl damage.
 */
bind('entity_damage', null, array(type: 'ITEM_FRAME', cause: 'PROJECTILE'), @event) {
	if(entity_type(@event['damager']) === 'ENDER_PEARL') {
		cancel();
	}
}

bind('entity_damage', null, array(type: 'GLOW_ITEM_FRAME', cause: 'PROJECTILE'), @event) {
	if(entity_type(@event['damager']) === 'ENDER_PEARL') {
		cancel();
	}
}

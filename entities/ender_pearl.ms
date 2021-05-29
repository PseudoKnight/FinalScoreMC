# prevent enderpearls from damaging item frames and paintings
bind('entity_damage', null, array('type': 'ITEM_FRAME', 'cause': 'PROJECTILE'), @event) {
	if(entity_type(@event['damager']) === 'ENDER_PEARL') {
		cancel();
	}
}

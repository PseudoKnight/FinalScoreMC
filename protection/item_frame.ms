bind('entity_damage', null, array(type: 'ITEM_FRAME', cause: 'PROJECTILE'), @event) {
	if(@event['damagertype'] === 'ENDER_PEARL' || !_is_survival_world(@event['world'])) {
		cancel();
	}
}

bind('entity_damage', null, array(type: 'GLOW_ITEM_FRAME', cause: 'PROJECTILE'), @event) {
	if(@event['damagertype'] === 'ENDER_PEARL' || !_is_survival_world(@event['world'])) {
		cancel();
	}
}

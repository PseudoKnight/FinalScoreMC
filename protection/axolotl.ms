/*
	Don't let axolotls to attack named tropical fish.
 */
bind('entity_damage', null, array(type: 'TROPICAL_FISH', cause: 'ENTITY_ATTACK'), @event) {
	if(get_mob_name(@event['id']) && entity_type(@event['damager']) == 'AXOLOTL') {
		cancel();
	}
}

/*
	Prevent dehydration damage to named axolotls
 */
bind('entity_damage', null, array(type: 'AXOLOTL', cause: 'DRYOUT'), @event) {
	if(get_mob_name(@event['id'])) {
		cancel();
	}
}
/*
	Don't let axolotls to attack named tropical fish.
 */
bind('entity_damage', null, array(type: 'TROPICAL_FISH', cause: 'ENTITY_ATTACK'), @event) {
	if(get_mob_name(@event['id']) && entity_type(@event['damager']) == 'AXOLOTL') {
		cancel();
	}
}
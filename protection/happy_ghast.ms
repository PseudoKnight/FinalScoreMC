/*
	Named happy ghast suffocation protection.
 */
bind('entity_damage', null, array(type: 'HAPPY_GHAST', cause: 'SUFFOCATION'), @event) {
	if(get_mob_name(@event['id'])) {
		modify_event('amount', 0);
	}
}
/*
	Happy ghast suffocation protection.
 */
bind('entity_damage', null, array(type: 'HAPPY_GHAST', cause: 'SUFFOCATION'), @event) {
	modify_event('amount', 0);
}
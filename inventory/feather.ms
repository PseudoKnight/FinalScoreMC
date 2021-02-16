/*
	Pushes entities without damaging them.
 */
bind('entity_damage', null, array(cause: 'ENTITY_ATTACK'), @event) {
	if(ponline(@event['damager'])
	&& _is_survival_world(@event['location']['world'])
	&& sk_can_build(@event['damager'], entity_loc(@event['id']))) {
		@item = pinv(@event['damager'], null);
		if(!@item || @item['name'] == 'FEATHER') {
			cancel();
			@vector = get_vector(ploc(@event['damager']), if(!@item, 0.5, 1.0));
			set_entity_velocity(@event['id'], @vector);
		}
	}
}
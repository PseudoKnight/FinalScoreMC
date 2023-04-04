// Block firework damage
bind('entity_damage', null, array(cause: 'ENTITY_EXPLOSION'), @event) {
	if(entity_type(@event['damager']) == 'FIREWORK') {
		if(!array_index_exists(@event, 'shooter')) { // from launch_firework()
			cancel();
		} else if(is_tameable(@event['id']) && get_mob_owner(@event['id']) != null) {
			cancel();
		} else if(entity_type(@event['id']) == 'ARMOR_STAND') {
			cancel();
		}
	}
}

// Block firework damage
bind('entity_damage', null, array('cause': 'ENTITY_EXPLOSION'), @event) {
	if(entity_type(@event['damager']) == 'FIREWORK') {
		// Crossbows currently do not set the firework's shooter.
		// This is an imperfect solution but captures more cases where we want to cancel damage.
		if(!is_null(get_firework_shooter(@event['damager']))) {
			cancel();
		} else if(!entity_exists(@event['id'])) {
			// what the hell is going on?
			if(array_index_exists(@event, 'player')) {
				if(_is_survival_world(@event['world'])) {
					// ensure we disabled pvp in survival
					cancel();
				}
			} else {
				console('Entity doesn\'t exist in entity_damage event: '.@event['type']);
			}
		} else if(is_tameable(@event['id']) && get_mob_owner(@event['id']) != null) {
			cancel();
		} else {
			@type = entity_type(@event['id']);
			if(@type == 'ITEM_FRAME' || @type == 'GLOW_ITEM_FRAME' || @type == 'ARMOR_STAND'
			|| @type == 'PAINTING' || @type == 'PLAYER' && _is_survival_world(@event['location']['world'])) {
				cancel();
			}
		}
	}
}

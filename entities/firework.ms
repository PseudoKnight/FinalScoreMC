// Block firework damage
bind('entity_damage', null, array('cause': 'ENTITY_EXPLOSION'), @event) {
	if(entity_type(@event['damager']) == 'FIREWORK') {
		if(is_tameable(@event['id']) && get_mob_owner(@event['id']) != null) {
			cancel();
		} else {
			@type = entity_type(@event['id']);
			if(@type == 'ITEM_FRAME' || @type == 'GLOW_ITEM_FRAME' || @type == 'ARMOR_STAND'
			|| @type == 'PAINTING' || @type == 'PLAYER' && _is_survival_world(@event['location']['world'])
			|| array_contains(get_scoreboard_tags(@event['damager']), 'nodamage')) {
				cancel();
			}
		}
	}
}

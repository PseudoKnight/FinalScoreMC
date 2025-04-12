// Block firework damage for all tamed mobs as well as entity decorations
bind('entity_damage', null, array(cause: 'ENTITY_EXPLOSION'), @event) {
	if(@event['damagertype'] === 'FIREWORK') {
		if(!array_index_exists(@event, 'shooter')) { // function fired
			cancel();
		} else if(is_tameable(@event['id'])) {
			if(get_mob_owner(@event['id'])) {
				cancel();
			}
		} else {
			@type = @event['type'];
			if(@type === 'ARMOR_STAND' || @type === 'ITEM_FRAME' || @type === 'GLOW_ITEM_FRAME') {
				cancel();
			}
		}
	}
}
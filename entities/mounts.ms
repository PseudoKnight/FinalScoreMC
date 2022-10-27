/*
	Sitting on some (mostly) non-hostile animals.
 */
bind('player_interact_entity', null, array(hand: 'main_hand', clicked: '/(COW|MUSHROOM_COW|PANDA|POLAR_BEAR|SHEEP)/'), @event) {
	if(!pblocking() && !pinv(player(), null)) {
		set_entity_rider(@event['id'], puuid());
	}
}
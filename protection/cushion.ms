/**
	Bypass entity interaction protection in WorldGuard for cushions
 */
bind('player_interact_entity', null, array(clicked: 'CUSHION'), @event) {
	cancel();
	set_entity_rider(@event['id'], puuid());
	play_sound(@event['id'], array(sound: 'ENTITY_CUSHION_SIT'));
}
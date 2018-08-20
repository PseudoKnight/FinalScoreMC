bind('player_move', null, array('threshold': 2), @event) {
	spawn_particle(@event['from'], 'HEART');
}

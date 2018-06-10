bind('player_move', null, array('threshold': 2), @event) {
	play_effect(@event['from'], 'HEART');
}

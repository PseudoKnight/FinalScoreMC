if(extension_exists('CHDynmap')) {
	bind('dm_player_web_chat', null, null, @event) {
		cancel();
		include('includes.library/chat.ms');
		_chat(@event['name'], @event['message'], all_players());
	}
}

if(!import('ignorelist')) {
	@ignorelist = get_value('session.ignorelist')
	if(!@ignorelist) {
		@ignorelist = associative_array();
	} else {
		clear_value('session.ignorelist');
	}
	export('ignorelist', @ignorelist);
}

if(!import('conv')) {
	@conv = get_value('session.conv')
	if(!@conv) {
		@conv = associative_array();
	} else {
		clear_value('session.conv');
	}
	export('conv', @conv);
}

bind('player_chat', null, null, @event) {
	cancel();
	include('includes.library/chat.ms');
	_chat(@event['player'], @event['message'], @event['recipients']);
}

if(extension_exists('CHDynmap')) {
	bind('dm_player_web_chat', null, null, @event) {
		cancel();
		include('includes.library/chat.ms');
		_chat(@event['name'], @event['message'], all_players());
	}
}

if(extension_exists('CHDiscord')) {
	// connect to finalscoremc server
	discord_connect(trim(read('discord-token.txt')), '104504215983890432');
	// listen for messages in chat channel
	bind('discord_message_received', null, null, @event) {
		if(@event['channel'] == 'chat') {
			include('includes.library/chat.ms');
			_chat(@event['username'], @event['message'], all_players(), @event['channel']);
		}
	}
}

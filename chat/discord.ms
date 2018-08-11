if(extension_exists('CHDiscord')) {
	// connect to finalscoremc server
	if(function_exists('discord_connect')) {
		discord_connect(trim(read('discord-token.txt')), '104504215983890432');
	}
	// listen for messages in chat channel
	bind('discord_message_received', null, null, @event) {
		if(@event['channel'] == 'chat') {
			include('includes.library/chat.ms');
			_chat(@event['username'], @event['message'], all_players(), @event['channel']);
		}
	}
}

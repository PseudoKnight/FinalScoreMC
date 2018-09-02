if(extension_exists('CHDiscord')) {
	// listen for messages in chat channel
	bind('discord_message_received', null, null, @event) {
		if(@event['channel'] == 'chat') {
			include('includes.library/chat.ms');
			_chat(@event['username'], @event['message'], all_players(), @event['channel']);
		}
	}
	
	bind('discord_voice_joined', null, null, @event) {
		broadcast(@event['nickname'].' joined the "'.@event['channel'].'" Discord voice channel.');
	}
}

if(extension_exists('CHDiscord')) {
	// listen for messages in chat channel
	bind('discord_message_received', null, null, @event) {
		if(@event['channel'] == 'chat') {
			include('../includes.library/chat.ms');
			_chat(@event['nickname'], @event['message'], all_players(), @event['channel']);
		}
	}
	
	bind('discord_voice_joined', null, null, @event) {
		@player = if(ponline(@event['nickname']), display_name(@event['nickname']), @event['nickname']);
		broadcast(color('yellow').@player.color('yellow').' joined the "'.@event['channel'].'" Discord voice channel.');
	}
}

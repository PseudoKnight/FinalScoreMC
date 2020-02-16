if(extension_exists('CHDiscord')) {
	// listen for messages in chat channel
	bind('discord_message_received', null, null, @event) {
		if(@event['channel'] == 'minecraft_chat') {
			@name = @event['nickname'];
			@pdata = null;
			if(ponline(@name)) {
				@pdata = _pdata(@name);
			} else {
				@uuid = get_value('discord', @event['userid']);
				if(@uuid) {
					@pdata = _pdata_by_uuid(@uuid);
				}
			}
			if(@pdata) {
				if(array_index_exists(@pdata, 'discord') && @pdata['discord'] != @event['userid']) {
					console('Discord message ignored from '.@name.': '.@event['message']);
					die();
				}
				@name = @pdata['name'];
			}
			include('../includes.library/chat.ms');
			_chat(@name, @event['message'], all_players(), 'discord', @event['channel']);
		}
	}

	bind('discord_voice_joined', null, null, @event) {
		@player = if(ponline(@event['nickname']), display_name(@event['nickname']), @event['nickname']);
		broadcast(color('yellow').@player.color('yellow').' joined the Discord voice chat.');
	}
}

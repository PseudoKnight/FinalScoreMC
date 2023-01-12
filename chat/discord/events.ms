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
			} else {
				// remove 
				@name = trim(reg_replace('[^a-zA-Z0-9_-]', '', @name));
				if(!@name) {
					@name = color('magic').'[unknown]';
				}
			}
			include('../includes.library/chat.ms');
			foreach(@line in split('\n', @event['message'])) {
				_chat(@name, @line, all_players(), 'discord', @event['channel']);
			}
			foreach(@attachment in @event['attachments']) {
				_tellraw(all_players(), array(array('open_url', @attachment['filename'], @attachment['url'], @attachment['description'])));
			}
		} else if(@event['channel'] == 'general') {
			if(reg_match('(?i).*\bserver\b.*\bdown\b.*', @event['message'])) {
				discord_broadcast(@event['channel'], 'Beep boop. I am still alive!'
						.'If you are having trouble connecting to `finalscoremc.com`, you can also use `'
						.get_server_info(12).':'.get_server_info(11).'`.');
			}
		}
	}

	bind('discord_voice_joined', null, null, @event) {
		@player = if(ponline(@event['nickname']), display_name(@event['nickname']), @event['nickname']);
		broadcast(color('yellow').@player.color('yellow').' joined the Discord voice chat.');
	}
}

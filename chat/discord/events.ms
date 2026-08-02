if(extension_exists('CHDiscord')) {
	// listen for messages in chat channel
	bind('discord_message_received', null, null, @event) {
		// Spam protection
		if(!@event['bot'] && !@event['webhook']) {
			try {
				if(discord_member_info(@event['userid'])['joined_at'] + 1000 * 60 * 60 * 24 * 3 > time()) {
					// Joined less than 3 days ago
					if(@event['attachments']) {
						// AND sent attachments
						discord_delete_message(@event['serverid'], @event['channelid'], @event['id']);
						discord_broadcast(@event['serverid'], 'mods', 'Deleted message in '.@event['channel']
								.' by new user ('.@event['username'].') containing '.array_size(@event['attachments'])
								.' attachment(s): '.@event['attachments'][0]['filename']
								.if(@event['message'], ' "'.@event['message'].'"'));
						if(!@event['message'] && @event['attachments'][0]['filename'] === 'image.jpg') {
							// Also a generic filename without a message, so kick user
							discord_request('DELETE', 'guilds/'.@event['serverid'].'/members/'.@event['userid'], null, closure(@success) {
								discord_broadcast(@event['serverid'], 'mods', 'Kicked '.@event['username']);
							}, closure(@failure) {
								console('Failed to kick '.@event['username']);
							});
						}
						die();
					} else if(string_position(@event['message'], 'http') > -1
					|| string_position(@event['message'], 'discord.gg/') > -1) {
						// Sent a link or invite embed
						discord_delete_message(@event['serverid'], @event['channelid'], @event['id']);
						discord_broadcast(@event['serverid'], 'mods', 'Deleted message in '.@event['channel']
								.' by new user ('.@event['username'].') containing URL: "'.@event['message'].'"');
						die();
					}
				}
			} catch(NotFoundException @ex) {}
		}

		// Regular chat
		if(@event['channel'] === 'chat') {
			@name = @event['nickname'];
			@msg = reg_replace('[\uFE00-\uFE0F]', '', @event['message']); // ignore unsupported unicode
			@pdata = null;
			if(ponline(@name)) {
				@pdata = _pdata(@name);
			} else {
				// Not online, so only use account data if linked.
				@uuid = get_value('discord', @event['userid']);
				if(@uuid) {
					@pdata = _pdata_by_uuid(@uuid);
				}
			}
			if(@pdata) {
				if(array_index_exists(@pdata, 'discord')) {
					// Check if linked account matches Discord userid.
					if(@pdata['discord'] != @event['userid']) {
						console("Discord message ignored from @name: @msg");
						die();
					}
				} else if(ponline(@name)) { // online but missing linked Discord
					console("@name account is not linked with Discord");
				}
				@name = @pdata['name'];
			} else {
				// Cannot find player data, so use Discord nickname.
				// However, remove special characters.
				@name = trim(reg_replace('[^a-zA-Z0-9_-]', '', @name));
				if(!@name) {
					@name = color('magic').'[unknown]';
				}
			}
			include('../includes.library/chat.ms');
			foreach(@line in split('\n', @msg)) {
				_chat(@name, @line, all_players(), 'discord', @event['channel']);
			}
			foreach(@attachment in @event['attachments']) {
				_tellraw(all_players(), array(array('open_url', @attachment['filename'], @attachment['url'],
						@attachment['description'])));
			}
		
		// Discord keywords or commands
		} else if(@event['channel'] === 'general') {
			if(reg_match('(?i).*\\bserver\\b\\W\\w*\\W?\\b(down|alive)\\b.*', @event['message'])) {
				discord_broadcast(@event['serverid'], 'general', 'Beep boop. I am still alive!');
			}
		}
	}

	bind('discord_voice_joined', null, null, @event) {
		@player = if(ponline(@event['nickname']), display_name(@event['nickname']), @event['nickname']);
		broadcast(color('yellow').@player.color('yellow').' joined Discord voice chat');
	}

	bind('discord_voice_left', null, null, @event) {
		@player = if(ponline(@event['nickname']), display_name(@event['nickname']), @event['nickname']);
		broadcast(color('yellow').@player.color('yellow').' left Discord voice chat');
	}
}

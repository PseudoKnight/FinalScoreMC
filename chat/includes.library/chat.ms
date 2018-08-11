proc _chat(@player, @message, @recipients, @discordChannel = '') {
	if(length(@message) == 0) {
		die();
	}
	# PRIVATE MESSAGING
	if(@message[0] === '@') {
		@parts = parse_args(@message);
		@p = substr(@parts[0], 1);
		if(length(@p) != 0 && array_size(@parts) > 1) {
			@message = substr(@message, length(@p) + 2);
			_pmsg(@player, @p, @message);
			console(@player.' @ '.@p.': '.@message, false);
			die();
		}
	}

	# Remove players that are ignoring this player, or everyone if muted.
	@recipients = _remove_ignored(@player, @recipients);
	if(array_size(@recipients) == 1 && array_size(all_players()) > 1) {
		die('No players can receive your chat.');
	}

	# Basic hostile word filters
	@filteredMessage = reg_replace(comp_read('filter.txt'), '\u2639', @message);

	# Chat escaping
	@escapedMessage = replace(@filteredMessage, '\\', '\\\\');
	@escapedMessage = replace(@escapedMessage, '"', '\\u0022');

	# Construct chat components
	@components = array();
	@components[] = array('colorize', '&8'.simple_date('h:mm').' ');

	try {
		@pdata = _pdata(@player, false);
		if(array_index_exists(@pdata, 'support')) {
			@components[] = array('hover', '&a\u2666', 'Server Supporter');
		}
	} catch(NotFoundException @ex) {
		@pdata = associative_array();
	}

	@nameColor = '';
	if(ponline(@player)) {
		@session = _psession(@player);
		if(array_index_exists(@session, 'trophies')) {
			@components[] = array('hover', '&6\u2660', '&6&lTrophies\\n'.array_implode(@session['trophies'], '\\n'));
		}
	} else {
		if(array_index_exists(@pdata, 'ban')) {
			die(@player.' tried to speak in web chat');
		}
		if(@discordChannel) {
			@components[] = array('hover', '&9\u2689'.if(@discordChannel != 'chat', '#'.@discordChannel), 'Discord');
		} else {
			@components[] = array('hover', '&2\u29E0', 'Live Map on Web');
		}
		if(@pdata) {
			@nameColor = _colorname(@player);
		}
	}

	if(array_index_exists(@pdata, 'icon')) {
		@components[] = array('plain', @pdata['icon']);
	}

	if(ponline(@player)) {
		@components[] = array('hover', ' '.display_name(@player),
			if(has_permission(@player, 'group.moderator'), '&bSTAFF\\n')
			.if(array_index_exists(@pdata, 'names'), '&7'.array_implode(@pdata['names']).'\\n')
			.if(array_index_exists(@session, 'lastplayed'), '&8[last played] &r'.@session['lastplayed'].'\\n')
			.'&8[world] &r'._worldname(pworld(@player)));
	} else {
		@components[] = array('hover', ' '.@nameColor.@player,
			.if(array_index_exists(@pdata, 'names'), '&7'.array_implode(@pdata['names']).'\\n')
			.'&8[world] &rReal World');
	}
	@components[] = '&8: ';

	@components[] = '&r'.@escapedMessage;

	# Send chat message
	_tellraw(@recipients, @components);
	console(if(!@recipients, '[MUTED] ').@player.': '.@message, false);
	if(@recipients) {
		if(function_exists('dm_broadcast_to_web')) {
			dm_broadcast_to_web(@filteredMessage, @player);
		}
		if(!@discordChannel) {
			if(function_exists('discord_broadcast')) {
				try(discord_broadcast('chat', '**'.@player.'** '.@filteredMessage));
			}
		}
	}
}

proc _pmsg(@from, @player, @message) {
	try{
		if(@player !== '~console') {
			@player = player(@player);
		}
		if(@recipients = _remove_ignored(@from, array(@player))) {
			@player = @recipients[0];
			@message = colorize(@message);
			tmsg(@player, color(7).'(From '.@from.if(!ponline(@from), ' on web').'): '.color('r').@message);
			if(@player !== '~console') {
				play_sound(ploc(@player), array('sound': 'ENTITY_CHICKEN_EGG', 'pitch': 2, 'category': 'VOICE'), @player);
			}
			msg(color(7).'(To '.@player.'): '.color('r').@message);
			@conv = import('conv');
			@conv[@player] = @from;
			@conv[@from] = @player;
			export('conv', @conv);
		} else {
			msg('You cannot message that player.');
		}
	} catch(PlayerOfflineException @ex) {
		if(length(@player) < 4) {
			die(color('gold').'You must provide at least the first 4 characters of a player\'s name for offline messages.');
		}
		try {
			@pdata = _pdata(@player);
		} catch(NotFoundException @ex) {
			die(color('red').'Unknown player. If you wish to send an offline message, use their full name.');
		}
		if(!array_index_exists(@pdata, 'mail')) {
			@pdata['mail'] = array();
		}
		array_push(@pdata['mail'], array(
			simple_date('MMM d h:mm a', time(), 'CST'),
			@from.if(!ponline(@from), ' on web'),
			@message
		));
		_store_pdata(@player, @pdata);
		msg(color(7).'(To '.@player.'): '.color('r').@message);
		msg(color('yellow').'Type /unsend if you wish to remove this offline message.');
		export(@from.'_mail', @pdata['name']);
	}
}

proc _remove_ignored(@sender, @recipients) {
	@ignorelist = import('ignorelist');
	foreach(@index: @player in @recipients) {
		if(array_index_exists(@ignorelist, @sender)) {
			if(array_contains(@ignorelist[@sender], @player)) {
				array_remove(@recipients, @index);
			} else if(array_contains(@ignorelist[@sender], 'all')) {
				return(array());
			}
		}
		if(array_index_exists(@ignorelist, 'all')) {
			if(array_contains(@ignorelist['all'], @player)) {
				array_remove(@recipients, @index);
			}
		}
	}
	return(@recipients);
}

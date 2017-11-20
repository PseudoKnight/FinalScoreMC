proc _chat(@player, @message, @recipients) {
	# PRIVATE MESSAGING
	if(@message[0] === '@') {
		@p = substr(parse_args(@message)[0], 1)
		if((length(@p) + 2) >= length(@message)) {
			die();
		}
		@message = substr(@message, length(@p) + 2);
		_pmsg(@player, @p, @message);
		console(@player.' @ '.@p.': '.@message, false);
		die();
	}

	# Remove players that are ignoring this player, or everyone if muted.
	@recipients = _remove_ignored(@player, @recipients);
	if(array_size(@recipients) == 1 && array_size(all_players()) > 1) {
		die('No players can receive your chat.');
	}

	# Basic hostile word filters
	@filteredMessage = reg_replace('(?i)(fuck|shit|damn|nigg|cunt|fag)', '\u2639', @message);

	# Chat escaping
	@escapedMessage = replace(@filteredMessage, '\\', '\\\\');
	@escapedMessage = replace(@escapedMessage, '"', '\\u0022');

	# Construct chat components
	@components = array();
	@components[] = array('colorize', '&8'.simple_date('h:mm').' ');

	@pdata = _pdata(@player);
	if(array_index_exists(@pdata, 'support')) {
		@components[] = array('hover', '&a\u2666', 'Server Supporter');
	}

	if(ponline(@player)) {
		@session = _psession(@player);
		if(array_index_exists(@session, 'trophies')) {
			@components[] = array('hover', '&6\u2660', '&6&lTrophies\n'.array_implode(@session['trophies'], '\n'));
		}
	} else {
		if(array_index_exists(@pdata, 'ban')) {
			die(@player.' tried to speak in web chat');
		}
		@components[] = array('hover', '&2\u29E0', 'Chat from Web');
	}

	if(array_index_exists(@pdata, 'icon')) {
		@components[] = array('plain', @pdata['icon']);
	}

	if(ponline(@player)) {
		@components[] = array('hover', ' '.display_name(@player),
			if(has_permission(@player, 'group.moderator'), '&bSTAFF\n')
			.if(array_index_exists(@pdata, 'names'), '&7'.array_implode(@pdata['names']).'\n')
			.if(array_index_exists(@session, 'lastplayed'), '&8[last played] &r'.@session['lastplayed'].'\n')
			.'&8[world] &r'._worldname(pworld(@player)));
	} else {
		@components[] = array('hover', ' '._colorname(@player).@player,
			.if(array_index_exists(@pdata, 'names'), '&7'.array_implode(@pdata['names']).'\n')
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
	}
	runas('~console', '/discord broadcast **'.@player.'**: '.@filteredMessage);
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
				play_sound(ploc(@player), array('sound': 'CHICKEN_EGG_POP', 'pitch': 2, 'category': 'VOICE'), @player);
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

/*
	Constructs and sends a tellraw command with a hover event
*/
proc _tellraw(@recipients, @components) {
	proc _colorize(@text) {
		@colors = array(
			'&0': '"color":"black",',
			'&1': '"color":"dark_blue",',
			'&2': '"color":"dark_green",',
			'&3': '"color":"dark_aqua",',
			'&4': '"color":"dark_red",',
			'&5': '"color":"dark_purple",',
			'&6': '"color":"gold",',
			'&7': '"color":"gray",',
			'&8': '"color":"dark_gray",',
			'&9': '"color":"blue",',
			'&a': '"color":"green",',
			'&b': '"color":"aqua",',
			'&c': '"color":"red",',
			'&d': '"color":"light_purple",',
			'&e': '"color":"yellow",',
			'&f': '"color":"white",',
			'&k': '"obfuscated":true,',
			'&l': '"bold":true,',
			'&m': '"strikethrough":true,',
			'&n': '"underlined":true,',
			'&o': '"italic":true,',
			'&r': '"color":"reset",',
			'': '',
		);
		@matches = reg_match_all('(&[0-9a-fk-or])?(&[k-o])?(&[k-o])?(&[k-o])?((?:&[^0-9a-fk-or]|[^&])*)', @text);
		@raw = '';
		foreach(@m in @matches) {
			if(@m[0]) {
				@raw .= ',{'.@colors[@m[1]].@colors[@m[2]].@colors[@m[3]].@colors[@m[4]].'"text":"'.@m[5].'"}';
			}
		}
		return(@raw);
	}
	
	@raw = ' [""';
	foreach(@c in @components) {
		if(!is_array(@c)) {
			@parts = reg_match('(.*?)(?:https?://|www\\.)([\\da-z.-]+\\.[a-z.]{2,6})([/\\w\\#\\+~:.?=&-]*)(.*)', @c);
			if(@parts) {
				@raw .= _colorize(@parts[1])
						.',{"color":"aqua","text":"\u29C9'.@parts[2].'","clickEvent":{"action":"open_url","value":"http://'
						.@parts[2].@parts[3].'"},"hoverEvent":{"action":"show_text","value":"http://'.@parts[2].@parts[3].'"}}'
						._colorize(@parts[4]);
			} else {
				@raw .= _colorize(@c);
			}
		} else {
			switch(@c[0]) {
				case 'hover':
					@raw .= ',{"text":"'.colorize(@c[1]).'","hoverEvent":{"action":"show_text","value":"'.colorize(@c[2]).'"}}';
				case 'colorize':
					@raw .= ',"'.colorize(@c[1]).'"';
				case 'plain':
					@raw .= ',"'.@c[1].'"';
			}
		}
	}
	@raw .= ']';
	foreach(@player in @recipients) {
		runas('~console', '/tellraw '.@player.@raw);
	}
}

proc _pmsg(@player, @message) {
	try{
		if(@player !== '~console') {
			@player = player(@player);
		}
		if(@recipients = _remove_ignored(player(), array(@player))) {
			@player = @recipients[0]
			@message = colorize(@message)
			tmsg(@player, color(7).'(From '.player().'): '.color('r').@message)
			if(@player !== '~console', play_sound(ploc(@player), array('sound': 'CHICKEN_EGG_POP', 'pitch': 2), @player))
			msg(color(7).'(To '.@player.'): '.color('r').@message)
			@conv = import('conv')
			@conv[@player] = player()
			@conv[player()] = @player
			export('conv', @conv)
		} else {
			msg('You cannot message that player.')
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
		if(!array_index_exists(@pdata, 'mail'), @pdata['mail'] = array())
		array_push(@pdata['mail'], array(
			simple_date('MMM d h:mm a', time(), 'CST'),
			player(),
			@message
		))
		_store_pdata(@player, @pdata)
		msg(color(7).'(To '.@player.'): '.color('r').@message)
		msg(color('yellow').'Type /unsend if you wish to remove this offline message.');
		export(player().'_mail', @pdata['name']);
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
proc _hover_tell(@recipients, @components) {
	@message = '';
	foreach(@c in @components) {
		if(!is_array(@c)) {
			@message .= @c;
		} else {
			@message .= '"},{"text":"'.colorize(@c[0]).'","hoverEvent":{"action":"show_text","value":"'.colorize(@c[1]).'"}},{"text":"';
		}
	}
	@raw = ' [{"text":"';
	@matches = reg_match_all('(&[0-9a-fr])(&[k-o])*([^&]+)', @message);
	foreach(@m in @matches) {
		@raw .= '"},{'._color(@m[1])._style(@m[2]).'"text":"'.@m[3];
	}
	@raw .= '"}]';
	foreach(@player in @recipients) {
		runas('~console', '/tellraw '.@player.@raw);
	}
}

proc _color(@char, @colors = associative_array(
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
	'&r': '"color":"reset",')) {
	return(array_get(@colors, @char, 'reset'));
}

proc _style(@char, @styles = associative_array(
		'&k': '"obfuscated":true,',
		'&l': '"bold":true,',
		'&m': '"strikethrough":true,',
		'&n': '"underline":true,',
		'&o': '"italic":true,'
	)) {
	return(array_get(@styles, @char, ''));
}

/*
	Create clickable links for a JSON message
*/
proc _clickable_links(@string) {
	return(reg_replace('(?:https?://|www\\.)([\\da-z.-]+\\.[a-z.]{2,6})([/\\w\\#~:.?=&-]*)',
		'&b\u29C9$1&r","clickEvent":{"action":"open_url","value":"http://$1$2"},"hoverEvent":{"action":"show_text","value":"http://$1$2"}},{"text":"&r',
		@string
	));
}

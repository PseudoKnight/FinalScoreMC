proc _pmsg(@player, @message) {
	try(if(@player != '~console', @player = player(@player))
		if(@recipients = _remove_ignored(player(), array(@player))) {
			@player = @recipients[0]
			@message = colorize(@message)
			tmsg(@player, color(7).'(From '.player().'): '.color('r').@message)
			if(@player != '~console', play_sound(ploc(@player), array('sound': 'CHICKEN_EGG_POP', 'pitch': 2), @player))
			msg(color(7).'(To '.@player.'): '.color('r').@message)
			@conv = import('conv')
			@conv[@player] = player()
			@conv[player()] = @player
			export('conv', @conv)
		} else {
			msg('You cannot message that player.')
		}
	, # else
		if(length(@player) < 4) {
			die(color('gold').'You must provide at least the first 4 characters of a player\'s name for offline messages.');
		}
		try(
			@pdata = _pdata(@player)
		, #catch
			die(color('red').'Unknown player. If you wish to send an offline message, use their full name.')
		)
		if(!array_index_exists(@pdata, 'mail'), @pdata['mail'] = array())
		array_push(@pdata['mail'], array(
			simple_date('MMM d h:mm a', time(), 'CST'),
			player(),
			@message
		))
		_store_pdata(@player, @pdata)
		msg(color(7).'(To '.@player.'): '.color('r').@message)
		msg(color('yellow').'Type /unsend immediately if you wish to remove this offline message.');
		export(player().'_mail', @pdata['name']);
	)
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
	Adds a timestamp with a player's timezone
*/
proc _time_stamp(@player) {
	@pdata = _pdata(@player);
	return(simple_date('h:mm', time(), array_get(@pdata, 'tz', 'Etc/GMT-6')));
}


/*
	Constructs and sends a tellraw command with a hover event
*/
proc _hover_tell(@recipients, @components) {
	@message = ' [""';
	foreach(@c in @components) {
		@message .= ',{text:"';
		if(!is_array(@c)) {
			@message .= colorize(@c).'"}';
		} else {
			@message .= colorize(@c[0]).'",hoverEvent:{action:"show_text",value:"'.colorize(@c[1]).'"}}';
		}
	}
	@message .= ']';
	foreach(@player in @recipients) {
		runas('~console', '/tellraw '.@player.@message);
	}
}

/*
	Create clickable links for a JSON message
*/
proc _clickable_links(@string) {
	return(reg_replace('(?:https?://|www\\.)([\\da-z.-]+\\.[a-z.]{2,6}[/\\w:.?=&-]*)', 
		'&b[$1]",clickEvent:{action:"open_url",value:"http://$1"}},{text:"&r',
		@string
	));
}